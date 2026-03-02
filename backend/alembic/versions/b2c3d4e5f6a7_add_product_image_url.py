"""add_product_image_url

Adds product_image_url column to receipts table.
Stores the external image URL returned by Brave Search API.

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-03-02 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'b2c3d4e5f6a7'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'receipts',
        sa.Column('product_image_url', sa.String(2048), nullable=True),
    )


def downgrade() -> None:
    op.drop_column('receipts', 'product_image_url')
