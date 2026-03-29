"""Add receipt_images table for front/back images

Revision ID: 89012345efgh
Revises: 78901234defg
Create Date: 2026-03-29 12:01:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision = '89012345efgh'
down_revision = '78901234defg'
branch_labels = None
depends_on = None


def upgrade():
    """Add receipt_images table to support front/back receipt images.
    
    This table enables storing multiple images per receipt (front and back sides)
    to handle double-sided receipts or receipts that require multiple photos.
    """
    
    # Create receipt_images table
    op.create_table(
        'receipt_images',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('receipt_id', sa.String(length=36), nullable=False),
        sa.Column('s3_object_key', sa.String(length=512), nullable=False),
        sa.Column('image_type', sa.String(length=10), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['receipt_id'], ['receipts.id'], ondelete='CASCADE'),
    )
    
    # Create indexes for efficient querying
    op.create_index('ix_receipt_images_id', 'receipt_images', ['id'])
    op.create_index('ix_receipt_images_receipt_id', 'receipt_images', ['receipt_id'])
    op.create_index('ix_receipt_images_image_type', 'receipt_images', ['image_type'])


def downgrade():
    """Remove receipt_images table (for rollback only)."""
    
    # Drop indexes first
    op.drop_index('ix_receipt_images_image_type', table_name='receipt_images')
    op.drop_index('ix_receipt_images_receipt_id', table_name='receipt_images')
    op.drop_index('ix_receipt_images_id', table_name='receipt_images')
    
    # Drop table
    op.drop_table('receipt_images')
