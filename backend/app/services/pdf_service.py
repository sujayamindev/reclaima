"""
PDF Generation Service - Generates warranty claim PDFs using reportlab.
Creates professional PDFs with receipt details, warranty information, and user data.
"""

import logging
from io import BytesIO
from datetime import datetime, timezone
from typing import Optional, List, TYPE_CHECKING

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate,
    Table,
    TableStyle,
    Paragraph,
    Spacer,
    PageBreak,
    Image as RLImage,
    KeepTogether,
)
from reportlab.lib.enums import TA_CENTER
from PIL import Image as PILImage


from app.models import Receipt, User

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)

# Color palette matching app branding
PRIMARY_COLOR = colors.HexColor("#12E28C")
ACCENT_DARK = colors.HexColor("#000000")
TEXT_PRIMARY = colors.HexColor("#111827")
TEXT_SECONDARY = colors.HexColor("#6B7280")
BORDER_COLOR = colors.HexColor("#E5E7EB")
WARNING_COLOR = colors.HexColor("#F59E0B")
ERROR_COLOR = colors.HexColor("#EF4444")


class PdfGenerationService:
    """Service for generating PDF documents (warranty claims, receipt exports)."""

    def __init__(self):
        """Initialize PDF service."""
        self.page_size = A4  # Changed to A4 for international standard
        self.left_margin = 0.75 * inch
        self.right_margin = 0.75 * inch
        self.top_margin = 0.5 * inch  # Reduced from 0.75
        self.bottom_margin = 0.5 * inch  # Reduced from 0.75

    def _get_scaled_image(
        self,
        image_bytes: bytes,
        max_width: float = 5.5 * inch,
        max_height: float = 3.5 * inch,
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
            if pil_image.mode in ("RGBA", "LA", "P"):
                background = PILImage.new("RGB", pil_image.size, (255, 255, 255))
                background.paste(
                    pil_image,
                    mask=pil_image.split()[-1] if pil_image.mode == "RGBA" else None,
                )
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
            pil_image.save(img_buffer, format="JPEG", quality=85)
            img_buffer.seek(0)

            # Create ReportLab Image
            rl_image = RLImage(img_buffer, width=new_width, height=new_height)
            return rl_image

        except Exception as e:
            logger.warning(f"Failed to process receipt image: {e}")
            return None

    def _get_logo_image(self, max_width: float = 2 * inch) -> Optional[RLImage]:
        """
        Load logo image with maintained aspect ratio.

        Args:
            max_width: Maximum width for the logo

        Returns:
            ReportLab Image object or None if logo not found
        """
        import os

        logo_path = os.path.join(
            os.path.dirname(__file__), "..", "..", "assets", "receipta_logo.png"
        )

        if os.path.exists(logo_path):
            try:
                # Open image to get dimensions
                pil_image = PILImage.open(logo_path)
                img_width, img_height = pil_image.size

                # Calculate height maintaining aspect ratio
                aspect_ratio = img_height / img_width
                new_width = max_width
                new_height = max_width * aspect_ratio

                return RLImage(logo_path, width=new_width, height=new_height)
            except Exception as e:
                logger.warning(f"Failed to load logo: {e}")
                return None
        return None

    def _add_page_footer(self, canvas_obj, doc, footer_text: str):
        """
        Add footer to every page.

        Args:
            canvas_obj: ReportLab canvas object
            doc: Document template
            footer_text: Footer text to display
        """
        canvas_obj.saveState()
        canvas_obj.setFont("Helvetica", 8)
        canvas_obj.setFillColor(colors.HexColor("#6B7280"))

        # Calculate center position
        page_width = doc.pagesize[0]

        # Draw footer text centered at bottom
        footer_y = 0.3 * inch
        canvas_obj.drawCentredString(page_width / 2, footer_y, footer_text)

        canvas_obj.restoreState()

    def generate_claim_pdf(
        self,
        receipt: Receipt,
        user: User,
        issue_description: str,
        claim_type: str,
        created_at: Optional[datetime] = None,
        s3_service: Optional[object] = None,
        claim_id: Optional[str] = None,
        line_item_id: Optional[str] = None,
        defect_image_s3_keys: Optional[List[str]] = None,
    ) -> bytes:
        """
        Generate a warranty claim PDF document with optional defect images.

        Args:
            receipt: Receipt object with all details
            user: User object (for contact info)
            issue_description: Description of the claim issue
            claim_type: Type of claim (warranty, return)
            created_at: Original claim creation timestamp (for regenerated PDFs)
            s3_service: S3 service for retrieving receipt image
            claim_id: Full claim ID to display in PDF header
            line_item_id: Specific line item ID if claim is for single product
            defect_image_s3_keys: List of S3 keys for defect images to append

        Returns:
            PDF document as bytes
        """
        logger.info(
            f"Generating claim PDF for receipt {receipt.id}, "
            f"claim_type={claim_type}, defect_images={len(defect_image_s3_keys or [])}"
        )

        # Dynamic PDF metadata title based on claim type
        pdf_title = (
            "Return Request Document"
            if claim_type and claim_type.lower() == "return"
            else "Warranty Claim Document"
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
            title=pdf_title,
        )

        # Build PDF elements
        story = []
        styles = getSampleStyleSheet()

        # Custom styles
        title_style = ParagraphStyle(
            "CustomTitle",
            parent=styles["Heading1"],
            fontSize=26,
            textColor=ACCENT_DARK,
            spaceAfter=8,
            alignment=TA_CENTER,
            fontName="Helvetica-Bold",
        )

        heading_style = ParagraphStyle(
            "SectionHeading",
            parent=styles["Heading2"],
            fontSize=11,
            textColor=PRIMARY_COLOR,
            spaceAfter=8,
            spaceBefore=14,
            fontName="Helvetica-Bold",
            borderWidth=0,
            borderColor=PRIMARY_COLOR,
            borderPadding=4,
        )

        # Dynamic title based on claim type
        if claim_type and claim_type.lower() == "return":
            doc_title = "RETURN REQUEST DOCUMENT"
            footer_claim_type = "return request"
        else:
            doc_title = "WARRANTY CLAIM DOCUMENT"
            footer_claim_type = "warranty claim"

        # Prepare footer text for all pages
        footer_text = (
            f"This is an official {footer_claim_type} document generated by Receipta. "
            "Please retain this document for your records."
        )

        # Get product name for claim details
        product_name = "N/A"
        if line_item_id and receipt.line_items:
            claimed_items = [
                item for item in receipt.line_items if item.id == line_item_id
            ]
            if claimed_items:
                product_name = (
                    claimed_items[0].product_name
                    or claimed_items[0].item_description
                    or "N/A"
                )
        elif receipt.line_items and len(receipt.line_items) > 0:
            product_name = (
                receipt.line_items[0].product_name
                or receipt.line_items[0].item_description
                or "N/A"
            )

        # ── Header Section ──────────────────────────────────────────────
        # Add logo with maintained aspect ratio
        logo = self._get_logo_image(max_width=2 * inch)
        if logo:
            # Center the logo
            logo_table = Table([[logo]], colWidths=[6 * inch])
            logo_table.setStyle(
                TableStyle(
                    [
                        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                    ]
                )
            )
            story.append(logo_table)
            story.append(Spacer(1, 0.15 * inch))

        story.append(Paragraph(doc_title, title_style))
        story.append(Spacer(1, 0.15 * inch))

        # Document ID and date (centered)
        generation_date = created_at or datetime.now(timezone.utc)
        display_claim_id = claim_id if claim_id else receipt.id

        timestamp_style = ParagraphStyle(
            "Timestamp",
            parent=styles["Normal"],
            fontSize=8,
            textColor=TEXT_SECONDARY,
            alignment=TA_CENTER,
            fontName="Helvetica",
        )

        story.append(
            Paragraph(
                f"Generated: {generation_date.strftime('%B %d, %Y at %I:%M %p UTC')}",
                timestamp_style,
            )
        )
        story.append(Spacer(1, 0.25 * inch))

        # ── Claim Details (Priority - Top Section) ─────────────────────
        story.append(Paragraph("CLAIM DETAILS", heading_style))

        claim_data = [
            ["Claim ID:", display_claim_id],
            ["Product:", product_name],
            ["Claim Type:", claim_type.upper() if claim_type else "WARRANTY"],
            ["Issue Description:", issue_description],
        ]

        claim_table = Table(claim_data, colWidths=[1.8 * inch, 4.2 * inch])
        claim_table.setStyle(
            TableStyle(
                [
                    ("ALIGN", (0, 0), (0, -1), "LEFT"),
                    ("ALIGN", (1, 0), (1, -1), "LEFT"),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 10),
                    ("FONT", (1, 0), (1, -1), "Helvetica", 9),
                    ("TEXTCOLOR", (0, 0), (0, -1), TEXT_SECONDARY),
                    ("TEXTCOLOR", (1, 0), (1, -1), TEXT_PRIMARY),
                    ("TOPPADDING", (0, 0), (-1, -1), 8),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ]
            )
        )
        story.append(claim_table)
        story.append(Spacer(1, 0.2 * inch))

        # ── Customer Information ────────────────────────────────────────
        story.append(Paragraph("CUSTOMER INFORMATION", heading_style))
        customer_data = [
            ["Name:", user.display_name or "Not Provided"],
            ["Contact:", user.contact_number or "Not Provided"],
            ["Email:", user.email],
        ]
        customer_table = Table(customer_data, colWidths=[1.8 * inch, 4.2 * inch])
        customer_table.setStyle(
            TableStyle(
                [
                    ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 9),
                    ("FONT", (1, 0), (1, -1), "Helvetica", 9),
                    ("TEXTCOLOR", (0, 0), (0, -1), TEXT_SECONDARY),
                    ("TEXTCOLOR", (1, 0), (1, -1), TEXT_PRIMARY),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )
        story.append(customer_table)
        story.append(Spacer(1, 0.2 * inch))

        # ── Receipt Information ─────────────────────────────────────────
        story.append(Paragraph("RECEIPT INFORMATION", heading_style))
        receipt_data = [
            ["Store Name:", receipt.store_name or "Unknown"],
            [
                "Purchase Date:",
                (
                    receipt.purchase_date.strftime("%B %d, %Y")
                    if receipt.purchase_date
                    else "Not Available"
                ),
            ],
            ["Invoice Number:", receipt.invoice_number or "N/A"],
            [
                "Total Amount:",
                (
                    f"{receipt.currency} {receipt.total_amount:.2f}"
                    if receipt.total_amount
                    else "Not Available"
                ),
            ],
        ]
        receipt_table = Table(receipt_data, colWidths=[1.8 * inch, 4.2 * inch])
        receipt_table.setStyle(
            TableStyle(
                [
                    ("ALIGN", (0, 0), (-1, -1), "LEFT"),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 9),
                    ("FONT", (1, 0), (1, -1), "Helvetica", 9),
                    ("TEXTCOLOR", (0, 0), (0, -1), TEXT_SECONDARY),
                    ("TEXTCOLOR", (1, 0), (1, -1), TEXT_PRIMARY),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )
        story.append(receipt_table)
        story.append(Spacer(1, 0.2 * inch))

        # ── Vendor Contact Information ──────────────────────────────────
        story.append(Paragraph("VENDOR CONTACT INFORMATION", heading_style))
        vendor_data = [
            ["Address:", receipt.vendor_address or "Not Available"],
            ["Phone:", receipt.vendor_phone or "Not Available"],
            ["Email:", receipt.vendor_email or "Not Available"],
            ["Website:", receipt.vendor_url or "Not Available"],
        ]
        vendor_table = Table(vendor_data, colWidths=[1.8 * inch, 4.2 * inch])
        vendor_table.setStyle(
            TableStyle(
                [
                    ("ALIGN", (0, 0), (0, -1), "LEFT"),
                    ("ALIGN", (1, 0), (1, -1), "LEFT"),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("FONT", (0, 0), (0, -1), "Helvetica-Bold", 9),
                    ("FONT", (1, 0), (1, -1), "Helvetica", 9),
                    ("TEXTCOLOR", (0, 0), (0, -1), TEXT_SECONDARY),
                    ("TEXTCOLOR", (1, 0), (1, -1), TEXT_PRIMARY),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )
        story.append(vendor_table)
        story.append(Spacer(1, 0.3 * inch))

        # ── Receipt Images (Separate Full Pages) ─────────────────────────
        # Include both front (s3_object_key) and back images from receipt_images
        receipt_images_added = False

        # Front image (from receipt.s3_object_key)
        if receipt.s3_object_key and s3_service:
            try:
                image_bytes = s3_service.get_file(receipt.s3_object_key)
                if image_bytes:
                    # Add page break before receipt image
                    story.append(PageBreak())

                    story.append(Paragraph("ORIGINAL RECEIPT - FRONT", heading_style))
                    story.append(Spacer(1, 0.2 * inch))

                    # Full page image - use larger dimensions for better visibility
                    receipt_image = self._get_scaled_image(
                        image_bytes, max_width=6.5 * inch, max_height=9 * inch
                    )
                    if receipt_image:
                        # Center the image
                        image_table = Table([[receipt_image]], colWidths=[6.5 * inch])
                        image_table.setStyle(
                            TableStyle(
                                [
                                    ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                                ]
                            )
                        )
                        story.append(image_table)
                        receipt_images_added = True
            except Exception as e:
                logger.warning(f"Failed to include front receipt image in PDF: {e}")

        # Back image (from receipt.images relationship)
        if hasattr(receipt, "images") and receipt.images and s3_service:
            for img in receipt.images:
                if img.image_type == "BACK" and img.s3_object_key:
                    try:
                        back_image_bytes = s3_service.get_file(img.s3_object_key)
                        if back_image_bytes:
                            story.append(PageBreak())

                            story.append(
                                Paragraph("ORIGINAL RECEIPT - BACK", heading_style)
                            )
                            story.append(Spacer(1, 0.2 * inch))

                            back_receipt_image = self._get_scaled_image(
                                back_image_bytes,
                                max_width=6.5 * inch,
                                max_height=9 * inch,
                            )
                            if back_receipt_image:
                                image_table = Table(
                                    [[back_receipt_image]], colWidths=[6.5 * inch]
                                )
                                image_table.setStyle(
                                    TableStyle(
                                        [
                                            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                                            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                                        ]
                                    )
                                )
                                story.append(image_table)
                                receipt_images_added = True
                    except Exception as e:
                        logger.warning(
                            f"Failed to include back receipt image in PDF: {e}"
                        )

        # ── Defect Images (Full Page Each with Auto-Rotation) ──────────
        if defect_image_s3_keys and s3_service:
            total_defect_images = len(defect_image_s3_keys)
            for idx, defect_s3_key in enumerate(defect_image_s3_keys, start=1):
                try:
                    defect_image_bytes = s3_service.get_file(defect_s3_key)
                    if defect_image_bytes:
                        # Add page break before each defect image
                        story.append(PageBreak())

                        # Process image: check orientation and rotate if landscape
                        try:
                            pil_image = PILImage.open(BytesIO(defect_image_bytes))
                            width, height = pil_image.size

                            # If landscape, rotate 90 degrees clockwise to portrait
                            if width > height:
                                logger.info(
                                    f"Defect image {idx} is landscape ({width}x{height}), rotating 90° for full-page display"
                                )
                                pil_image = pil_image.rotate(-90, expand=True)

                                # Convert back to bytes
                                rotated_buffer = BytesIO()
                                pil_image.save(
                                    rotated_buffer, format="JPEG", quality=95
                                )
                                defect_image_bytes = rotated_buffer.getvalue()
                        except Exception as rot_err:
                            logger.warning(
                                f"Could not rotate defect image {idx}: {rot_err}"
                            )

                        # Full page image for defect - maximize size
                        defect_image = self._get_scaled_image(
                            defect_image_bytes,
                            max_width=7.0 * inch,
                            max_height=10.0 * inch,
                        )
                        if defect_image:
                            # Create elements to keep together (caption + image)
                            caption_text = f"DEFECT EVIDENCE - IMAGE {idx} OF {total_defect_images}"
                            defect_elements = [
                                Paragraph(caption_text, heading_style),
                                Spacer(1, 0.2 * inch),
                                Table([[defect_image]], colWidths=[7.0 * inch]),
                            ]

                            # Use KeepTogether to prevent page break between caption and image
                            story.append(KeepTogether(defect_elements))
                except Exception as e:
                    logger.warning(f"Failed to include defect image {idx} in PDF: {e}")

        # Add page break after images if they exist
        if receipt_images_added or (defect_image_s3_keys and s3_service):
            story.append(PageBreak())

        # Build PDF with footer on every page
        def add_footer(canvas_obj, doc_obj):
            """Add footer to each page."""
            self._add_page_footer(canvas_obj, doc_obj, footer_text)

        doc.build(story, onFirstPage=add_footer, onLaterPages=add_footer)

        # Get PDF bytes
        pdf_bytes = pdf_buffer.getvalue()
        logger.info(f"Generated claim PDF: {len(pdf_bytes)} bytes")

        return pdf_bytes

    def generate_receipt_export_pdf(self, receipt: Receipt, user: User) -> bytes:
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
            claim_type="export",
        )


def get_pdf_service() -> PdfGenerationService:
    """Factory function to get PDF service."""
    return PdfGenerationService()
