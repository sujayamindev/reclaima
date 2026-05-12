"""Sync index names and drop duplicate unique constraint

Revision ID: 90123456fghi
Revises: 89012345efgh
Create Date: 2026-05-13 00:00:00.000000

"""

from alembic import op

# revision identifiers, used by Alembic.
revision = "90123456fghi"
down_revision = "89012345efgh"
branch_labels = None
depends_on = None


def upgrade():
    # Drop manually-named idx_* indexes that duplicate the ix_* indexes
    # already tracked by SQLAlchemy via index=True on the respective columns.
    op.drop_index("idx_users_deleted_at", table_name="users")
    op.drop_index("idx_receipts_deleted_at", table_name="receipts")
    op.drop_index("idx_receipts_created_at", table_name="receipts")
    op.drop_index("idx_receipt_line_items_deleted_at", table_name="receipt_line_items")
    op.drop_index("idx_claim_documents_deleted_at", table_name="claim_documents")
    op.drop_index("idx_claim_documents_created_at", table_name="claim_documents")

    # Drop the PostgreSQL auto-named unique constraint on
    # user_notification_preferences.user_id.  Uniqueness is already enforced
    # by the ix_user_notification_preferences_user_id unique index created in
    # migration a1b2c3d4e5f6, so this constraint is redundant.
    op.drop_constraint(
        "user_notification_preferences_user_id_key",
        "user_notification_preferences",
        type_="unique",
    )


def downgrade():
    op.create_unique_constraint(
        "user_notification_preferences_user_id_key",
        "user_notification_preferences",
        ["user_id"],
    )

    op.create_index("idx_claim_documents_created_at", "claim_documents", ["created_at"])
    op.create_index("idx_claim_documents_deleted_at", "claim_documents", ["deleted_at"])
    op.create_index(
        "idx_receipt_line_items_deleted_at", "receipt_line_items", ["deleted_at"]
    )
    op.create_index("idx_receipts_created_at", "receipts", ["created_at"])
    op.create_index("idx_receipts_deleted_at", "receipts", ["deleted_at"])
    op.create_index("idx_users_deleted_at", "users", ["deleted_at"])
