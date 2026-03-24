"""
PDF Generation Service - Generates warranty claim PDFs using reportlab.
Creates professional PDFs with receipt details, warranty information, and user data.
"""

import logging
from io import BytesIO
from datetime import datetime, timezone
from typing import Optional, Tuple, TYPE_CHECKING

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak,
    Image as RLImage
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from PIL import Image as PILImage

from sqlalchemy.orm import Session

from app.models import Receipt, User
from app.models.receipt_line_item import ReceiptLineItem

if TYPE_CHECKING:
    from app.services.s3_service import MockS3Service, RealS3Service

logger = logging.getLogger(__name__)

# Color palette matching app branding
PRIMARY_COLOR = colors.HexColor("#12E28C")
ACCENT_DARK = colors.HexColor("#1F2937")
TEXT_PRIMARY = colors.HexColor("#111827")
TEXT_SECONDARY = colors.HexColor("#6B7280")
BORDER_COLOR = colors.HexColor("#E5E7EB")
WARNING_COLOR = colors.HexColor("#F59E0B")
ERROR_COLOR = colors.HexColor("#EF4444")


class PdfGenerationService:
    """Service for generating PDF documents (warranty claims, receipt exports)."""

    def __init__(self):
        """Initialize PDF service."""
        self.page_size = letter
        self.left_margin = 0.5 * inch
        self.right_margin = 0.5 * inch
        self.top_margin = 0.75 * inch
        self.bottom_margin = 0.75 * inch

    def _get_scaled_image(
        self,
        image_bytes: bytes,
        max_width: float = 5.5 * inch,
        max_height: float = 3.5 * inch
    ) -> Optional[RLImage]:
        """
        Process image bytes and return a ReportLab Image with scaling.

        Args:
            image_bytes: Image content as bytes
            max_width: Maximum width for the image
            max_height: Maximum height for the image

        Returns:
            ReportLab Image object or None if processing fails
        """
        try:
            # Open image with PIL
            pil_image = PILImage.open(BytesIO(image_bytes))

            # Convert to RGB if necessary (remove alpha channel)
            if pil_image.mode in ('RGBA', 'LA', 'P'):
                background = PILImage.new('RGB', pil_image.size, (255, 255, 255))
                background.paste(pil_image, mask=pil_image.split()[-1] if pil_image.mode == 'RGBA' else None)
                pil_image = background

            # Calculate scaling to fit within max dimensions while maintaining aspect ratio
            img_width, img_height = pil_image.size
            width_ratio = max_width / img_width
            height_ratio = max_height / img_height
            scale_ratio = min(width_ratio, height_ratio, 1.0)  # Don't upscale

            new_width = img_width * scale_ratio
            new_height = img_height * scale_ratio

            # Save processed image to bytes
            img_buffer = BytesIO()
            pil_image.save(img_buffer, format='JPEG', quality=85)
            img_buffer.seek(0)

            # Create ReportLab Image
            rl_image = RLImage(img_buffer, width=new_width, height=new_height)
            return rl_image

        except Exception as e:
            logger.warning(f"Failed to process receipt image: {e}")
            return None

    def generate_claim_pdf(
        self,
        receipt: Receipt,
        user: User,
        issue_description: str,
        claim_type: str,
        created_at: Optional[datetime] = None,
        s3_service: Optional[object] = None
    ) -> bytes:
        """
        Generate a warranty claim PDF document.

        Args:
            receipt: Receipt object with all details
            user: User object (for contact info)
            issue_description: Description of the claim issue
            claim_type: Type of claim (warranty, return)
            created_at: Original claim creation timestamp (for regenerated PDFs)
            s3_service: S3 service for retrieving receipt image

        Returns:
            PDF document as bytes
        """
        logger.info(
            f"Generating claim PDF for receipt {receipt.id}, "
            f"claim_type={claim_type}"
        )

        # Create PDF in memory
        pdf_buffer = BytesIO()
        doc = SimpleDocTemplate(
            pdf_buffer,
            pagesize=self.page_size,
            leftMargin=self.left_margin,
            rightMargin=self.right_margin,
            topMargin=self.top_margin,
            bottomMargin=self.bottom_margin,
            title="Warranty Claim Document"
        )

        # Build PDF elements
        story = []
        styles = getSampleStyleSheet()

        # Custom styles
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            textColor=ACCENT_DARK,
            spaceAfter=6,
            alignment=TA_CENTER,
            fontName='Helvetica-Bold'
        )

        heading_style = ParagraphStyle(
            'SectionHeading',
            parent=styles['Heading2'],
            fontSize=12,
            textColor=PRIMARY_COLOR,
            spaceAfter=8,
            spaceBefore=12,
            fontName='Helvetica-Bold'
        )

        normal_style = ParagraphStyle(
            'CustomNormal',
            parent=styles['Normal'],
            fontSize=10,
            textColor=TEXT_PRIMARY,
            leading=14
        )

        label_style = ParagraphStyle(
            'Label',
            parent=styles['Normal'],
            fontSize=9,
            textColor=TEXT_SECONDARY,
            fontName='Helvetica-Bold'
        )

        # ── Header Section ──────────────────────────────────────────────
        story.append(Paragraph("WARRANTY CLAIM DOCUMENT", title_style))
        story.append(Spacer(1, 0.1 * inch))

        # Document ID and date
        generation_date = created_at or datetime.now(timezone.utc)
        doc_info = f"Claim ID: {receipt.id[:8]}... | Generated: {generation_date.strftime('%B %d, %Y at %I:%M %p')}"
        story.append(Paragraph(doc_info, label_style))
        story.append(Spacer(1, 0.2 * inch))

        # ── Receipt Image ───────────────────────────────────────────────
        if receipt.s3_object_key and s3_service:
            try:
                image_bytes = s3_service.get_file(receipt.s3_object_key)
                if image_bytes:
                    receipt_image = self._get_scaled_image(image_bytes)
                    if receipt_image:
                        story.append(Paragraph("RECEIPT IMAGE", heading_style))
                        # Center the image by wrapping in a table
                        image_table = Table(
                            [[receipt_image]],
                            colWidths=[6 * inch]
                        )
                        image_table.setStyle(TableStyle([
                            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                        ]))
                        story.append(image_table)
                        story.append(Spacer(1, 0.15 * inch))
            except Exception as e:
                logger.warning(f"Failed to include receipt image in PDF: {e}")

        # ── Customer Information ────────────────────────────────────────
        story.append(Paragraph("CUSTOMER INFORMATION", heading_style))
        customer_data = [
            ["Name:", user.display_name or "Not Provided"],
            ["Contact:", user.contact_number or "Not Provided"],
            ["Email:", user.email],
        ]
        customer_table = Table(customer_data, colWidths=[1.5 * inch, 4 * inch])
        customer_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('FONT', (0, 0), (0, -1), 'Helvetica-Bold', 9),
            ('FONT', (1, 0), (1, -1), 'Helvetica', 9),
            ('TEXTCOLOR', (0, 0), (0, -1), TEXT_SECONDARY),
            ('TEXTCOLOR', (1, 0), (1, -1), TEXT_PRIMARY),
            ('LINEBELOW', (0, -1), (-1, -1), 1, BORDER_COLOR),
        ]))
        story.append(customer_table)
        story.append(Spacer(1, 0.15 * inch))

        # ── Receipt Information ─────────────────────────────────────────
        story.append(Paragraph("RECEIPT INFORMATION", heading_style))
        receipt_data = [
            ["Store Name:", receipt.store_name or "Unknown"],
            ["Purchase Date:", receipt.purchase_date.strftime('%B %d, %Y') if receipt.purchase_date else "Not Available"],
            ["Invoice Number:", receipt.invoice_number or "N/A"],
            ["Total Amount:", f"{receipt.currency} {receipt.total_amount:.2f}" if receipt.total_amount else "Not Available"],
        ]
        receipt_table = Table(receipt_data, colWidths=[1.5 * inch, 4 * inch])
        receipt_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('FONT', (0, 0), (0, -1), 'Helvetica-Bold', 9),
            ('FONT', (1, 0), (1, -1), 'Helvetica', 9),
            ('TEXTCOLOR', (0, 0), (0, -1), TEXT_SECONDARY),
            ('TEXTCOLOR', (1, 0), (1, -1), TEXT_PRIMARY),
            ('LINEBELOW', (0, -1), (-1, -1), 1, BORDER_COLOR),
        ]))
        story.append(receipt_table)
        story.append(Spacer(1, 0.15 * inch))

        # ── Vendor Contact Information ──────────────────────────────────
        story.append(Paragraph("VENDOR CONTACT INFORMATION", heading_style))
        vendor_data = [
            ["Address:", receipt.vendor_address or "Not Available"],
            ["Phone:", receipt.vendor_phone or "Not Available"],
            ["Email:", receipt.vendor_email or "Not Available"],
            ["Website:", receipt.vendor_url or "Not Available"],
        ]
        vendor_table = Table(vendor_data, colWidths=[1.5 * inch, 4 * inch])
        vendor_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (0, -1), 'LEFT'),
            ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('FONT', (0, 0), (0, -1), 'Helvetica-Bold', 9),
            ('FONT', (1, 0), (1, -1), 'Helvetica', 8),
            ('TEXTCOLOR', (0, 0), (0, -1), TEXT_SECONDARY),
            ('TEXTCOLOR', (1, 0), (1, -1), TEXT_PRIMARY),
            ('LINEBELOW', (0, -1), (-1, -1), 1, BORDER_COLOR),
        ]))
        story.append(vendor_table)
        story.append(Spacer(1, 0.15 * inch))

        # ── Products / Line Items ───────────────────────────────────────
        story.append(Paragraph("PURCHASED ITEMS", heading_style))

        if receipt.line_items:
            line_items_data = [
                ["Product", "Category", "Quantity", "Unit Price", "Amount"]
            ]

            for item in receipt.line_items:
                line_items_data.append([
                    item.product_name or item.item_description or "N/A",
                    item.product_category or "N/A",
                    item.quantity or "N/A",
                    f"{receipt.currency} {float(item.unit_price or 0):.2f}" if item.unit_price else "N/A",
                    f"{receipt.currency} {float(item.amount or 0):.2f}" if item.amount else "N/A",
                ])

            items_table = Table(
                line_items_data,
                colWidths=[2 * inch, 1.2 * inch, 0.8 * inch, 1 * inch, 1 * inch]
            )
            items_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONT', (0, 0), (-1, 0), 'Helvetica-Bold', 9),
                ('FONT', (0, 1), (-1, -1), 'Helvetica', 8),
                ('GRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9FAFB")]),
            ]))
            story.append(items_table)
        else:
            story.append(Paragraph("No line items found.", normal_style))

        story.append(Spacer(1, 0.15 * inch))

        # ── Warranty & Return Terms ─────────────────────────────────────
        story.append(Paragraph("WARRANTY & RETURN TERMS", heading_style))

        warranty_data = []
        for item in receipt.line_items:
            warranty_str = f"{item.warranty_period_months} months" if item.warranty_period_months else "Not specified"
            warranty_expiry = item.warranty_expiry_date.strftime('%B %d, %Y') if item.warranty_expiry_date else "N/A"

            return_str = f"{item.return_period_days} days" if item.return_period_days else "Not specified"
            return_expiry = item.return_expiry_date.strftime('%B %d, %Y') if item.return_expiry_date else "N/A"

            warranty_data.append([
                item.product_name or item.item_description or "Item",
                warranty_str,
                warranty_expiry,
                return_str,
                return_expiry,
            ])

        if warranty_data:
            warranty_table_data = [
                ["Product", "Warranty", "Expiry Date", "Return Period", "Return Expiry"]
            ] + warranty_data

            warranty_table = Table(
                warranty_table_data,
                colWidths=[1.5 * inch, 1 * inch, 1.2 * inch, 1 * inch, 1.2 * inch]
            )
            warranty_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONT', (0, 0), (-1, 0), 'Helvetica-Bold', 8),
                ('FONT', (0, 1), (-1, -1), 'Helvetica', 7),
                ('GRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9FAFB")]),
            ]))
            story.append(warranty_table)
        else:
            story.append(Paragraph("No warranty information available.", normal_style))

        story.append(Spacer(1, 0.15 * inch))

        # ── Notification Status ─────────────────────────────────────────
        story.append(Paragraph("NOTIFICATION STATUS", heading_style))

        notification_data = [
            ["Product", "Warranty Reminders", "Return Reminders"]
        ]

        for item in receipt.line_items:
            warranty_status = "Enabled" if (item.warranty_reminder_enabled if item.warranty_reminder_enabled is not None else True) else "Disabled"
            return_status = "Enabled" if (item.return_reminder_enabled if item.return_reminder_enabled is not None else True) else "Disabled"

            notification_data.append([
                item.product_name or item.item_description or "Item",
                warranty_status,
                return_status,
            ])

        if len(notification_data) > 1:
            notif_table = Table(notification_data, colWidths=[2 * inch, 1.5 * inch, 1.5 * inch])
            notif_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), PRIMARY_COLOR),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONT', (0, 0), (-1, 0), 'Helvetica-Bold', 9),
                ('FONT', (0, 1), (-1, -1), 'Helvetica', 8),
                ('GRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#F9FAFB")]),
            ]))
            story.append(notif_table)

        story.append(Spacer(1, 0.15 * inch))

        # ── Claim Details ───────────────────────────────────────────────
        story.append(Paragraph("CLAIM DETAILS", heading_style))

        claim_data = [
            ["Claim Type:", claim_type.capitalize()],
            ["Issue Description:", issue_description],
        ]

        claim_table = Table(claim_data, colWidths=[1.5 * inch, 4 * inch])
        claim_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (0, -1), 'LEFT'),
            ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('FONT', (0, 0), (0, -1), 'Helvetica-Bold', 9),
            ('FONT', (1, 0), (1, -1), 'Helvetica', 9),
            ('TEXTCOLOR', (0, 0), (0, -1), TEXT_SECONDARY),
            ('TEXTCOLOR', (1, 0), (1, -1), TEXT_PRIMARY),
            ('LINEBELOW', (0, -1), (-1, -1), 1, BORDER_COLOR),
        ]))
        story.append(claim_table)
        story.append(Spacer(1, 0.2 * inch))

        # ── Footer ──────────────────────────────────────────────────────
        footer_text = (
            "This is an official warranty claim document generated by Smart Receipt & Warranty Manager. "
            "Please retain a copy for your records. Submit this document along with the original receipt "
            "and any supporting documentation when filing your warranty claim."
        )
        story.append(Paragraph(footer_text, ParagraphStyle(
            'Footer',
            parent=styles['Normal'],
            fontSize=8,
            textColor=TEXT_SECONDARY,
            alignment=TA_CENTER,
            leading=10
        )))

        # Build PDF
        doc.build(story)

        # Get PDF bytes
        pdf_bytes = pdf_buffer.getvalue()
        logger.info(f"Generated claim PDF: {len(pdf_bytes)} bytes")

        return pdf_bytes

    def generate_receipt_export_pdf(
        self,
        receipt: Receipt,
        user: User
    ) -> bytes:
        """
        Generate a receipt export PDF (for backup/archiving).

        Args:
            receipt: Receipt object
            user: User object

        Returns:
            PDF document as bytes
        """
        logger.info(f"Generating receipt export PDF for receipt {receipt.id}")

        # For now, reuse claim PDF generation but with different styling
        # In future, this could have different layout/content
        return self.generate_claim_pdf(
            receipt=receipt,
            user=user,
            issue_description="Receipt Export / Backup",
            claim_type="export"
        )


def get_pdf_service() -> PdfGenerationService:
    """Factory function to get PDF service."""
    return PdfGenerationService()
