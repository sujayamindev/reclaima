"""add_extended_ocr_fields_and_line_items

Adds 7 new OCR-extracted columns to the receipts table and creates the
receipt_line_items table for multi-item receipt/invoice support.

Revision ID: 6faa1167a629
Revises:
Create Date: 2026-02-23 13:22:36.312953
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '6faa1167a629'
down_revision = '95ff49aa0955'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── New columns on receipts ──────────────────────────────────────────────
    op.add_column('receipts', sa.Column('invoice_number', sa.String(100),  nullable=True))
    op.add_column('receipts', sa.Column('vendor_address', sa.Text(),        nullable=True))
    op.add_column('receipts', sa.Column('vendor_phone',   sa.String(100),   nullable=True))
    op.add_column('receipts', sa.Column('vendor_email',   sa.String(255),   nullable=True))
    op.add_column('receipts', sa.Column('vendor_url',     sa.String(255),   nullable=True))
    op.add_column('receipts', sa.Column('remarks',        sa.Text(),        nullable=True))
    op.add_column('receipts', sa.Column('warranty_notes', sa.Text(),        nullable=True))

    # ── New receipt_line_items table ─────────────────────────────────────────
    op.create_table(
        'receipt_line_items',
        sa.Column('id',               sa.String(36),  primary_key=True),
        sa.Column('receipt_id',       sa.String(36),
                  sa.ForeignKey('receipts.id', ondelete='CASCADE'), nullable=False),
        sa.Column('row_index',        sa.Integer(),   nullable=False, server_default='0'),
        sa.Column('product_code',     sa.String(100), nullable=True),
        sa.Column('item_description', sa.String(512), nullable=True),
        sa.Column('quantity',         sa.String(50),  nullable=True),
        sa.Column('unit_price',       sa.Float(),     nullable=True),
        sa.Column('amount',           sa.Float(),     nullable=True),
        sa.Column('created_at',       sa.DateTime(timezone=True),
                  server_default=sa.text('now()'), nullable=False),
    )
    op.create_index(
        'ix_receipt_line_items_id', 'receipt_line_items', ['id'], unique=False
    )
    op.create_index(
        'ix_receipt_line_items_receipt_id', 'receipt_line_items', ['receipt_id'], unique=False
    )


def downgrade() -> None:
    op.drop_index('ix_receipt_line_items_receipt_id', table_name='receipt_line_items')
    op.drop_index('ix_receipt_line_items_id',         table_name='receipt_line_items')
    op.drop_table('receipt_line_items')

    op.drop_column('receipts', 'warranty_notes')
    op.drop_column('receipts', 'remarks')
    op.drop_column('receipts', 'vendor_url')
    op.drop_column('receipts', 'vendor_email')
    op.drop_column('receipts', 'vendor_phone')
    op.drop_column('receipts', 'vendor_address')
    op.drop_column('receipts', 'invoice_number')
