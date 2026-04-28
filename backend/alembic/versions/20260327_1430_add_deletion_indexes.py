"""Add indexes for deletion queries

Revision ID: 56789012bcde
Revises: 45678901defa
Create Date: 2026-03-27 14:30:00.000000

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "56789012bcde"
down_revision = "45678901defa"
branch_labels = None
depends_on = None


def upgrade():
    """Add indexes on deleted_at and created_at for efficient hard delete queries."""

    # Add indexes on deleted_at for all tables with soft delete
    op.create_index("idx_users_deleted_at", "users", ["deleted_at"], unique=False)

    op.create_index("idx_receipts_deleted_at", "receipts", ["deleted_at"], unique=False)

    op.create_index(
        "idx_receipt_line_items_deleted_at",
        "receipt_line_items",
        ["deleted_at"],
        unique=False,
    )

    op.create_index(
        "idx_claim_documents_deleted_at",
        "claim_documents",
        ["deleted_at"],
        unique=False,
    )

    # Add indexes on created_at for date range queries
    op.create_index("idx_receipts_created_at", "receipts", ["created_at"], unique=False)

    op.create_index(
        "idx_claim_documents_created_at",
        "claim_documents",
        ["created_at"],
        unique=False,
    )


def downgrade():
    """Remove deletion indexes."""

    # Drop deleted_at indexes
    op.drop_index("idx_claim_documents_deleted_at", table_name="claim_documents")
    op.drop_index("idx_receipt_line_items_deleted_at", table_name="receipt_line_items")
    op.drop_index("idx_receipts_deleted_at", table_name="receipts")
    op.drop_index("idx_users_deleted_at", table_name="users")

    # Drop created_at indexes
    op.drop_index("idx_claim_documents_created_at", table_name="claim_documents")
    op.drop_index("idx_receipts_created_at", table_name="receipts")
