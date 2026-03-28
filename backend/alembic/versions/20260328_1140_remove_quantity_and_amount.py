"""Remove quantity and amount from line items

Revision ID: 67890123cdef
Revises: 56789012bcde
Create Date: 2026-03-28 11:40:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision = '67890123cdef'
down_revision = '56789012bcde'
branch_labels = None
depends_on = None


def upgrade():
    """Remove quantity and amount columns from receipt_line_items.
    
    Each line item now represents exactly 1 physical unit (implicit quantity=1).
    Total amount is stored at receipt level. Only unit_price is kept per item.
    """
    
    # Remove quantity column (was String(50), nullable)
    op.drop_column('receipt_line_items', 'quantity')
    
    # Remove amount column (was Numeric(12,2), nullable)
    op.drop_column('receipt_line_items', 'amount')


def downgrade():
    """Re-add quantity and amount columns (for rollback only)."""
    
    # Re-add quantity column
    op.add_column(
        'receipt_line_items',
        sa.Column('quantity', sa.String(length=50), nullable=True)
    )
    
    # Re-add amount column
    op.add_column(
        'receipt_line_items',
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=True)
    )
