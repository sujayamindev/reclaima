"""initial_schema

Creates the initial database tables: users, receipts, and claim_documents.
This is the baseline migration that all subsequent migrations build upon.

Revision ID: 95ff49aa0955
Revises:
Create Date: 2026-01-01 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "95ff49aa0955"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── users ─────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("firebase_uid", sa.String(128), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("display_name", sa.String(255), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_users_id", "users", ["id"], unique=False)
    op.create_index("ix_users_firebase_uid", "users", ["firebase_uid"], unique=True)
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    # ── receipts ──────────────────────────────────────────────────────────────
    op.create_table(
        "receipts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("s3_object_key", sa.String(512), nullable=True),
        sa.Column("store_name", sa.String(255), nullable=True),
        sa.Column("purchase_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("total_amount", sa.Float(), nullable=True),
        sa.Column("currency", sa.String(3), nullable=True, server_default="USD"),
        sa.Column("product_name", sa.String(512), nullable=True),
        sa.Column("product_category", sa.String(128), nullable=True),
        sa.Column("warranty_period_months", sa.Integer(), nullable=True),
        sa.Column("warranty_expiry_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "return_period_days", sa.Integer(), nullable=True, server_default="30"
        ),
        sa.Column("return_expiry_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "status",
            sa.Enum(
                "LOCAL_ONLY",
                "UPLOADED",
                "PROCESSING",
                "COMPLETED",
                "OCR_FAILED",
                "MANUAL_ENTRY",
                name="receiptstatus",
            ),
            nullable=False,
            server_default="UPLOADED",
        ),
        sa.Column("ocr_retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_ocr_attempt_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ocr_raw_response", sa.Text(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_receipts_id", "receipts", ["id"], unique=False)
    op.create_index("ix_receipts_user_id", "receipts", ["user_id"], unique=False)
    op.create_index(
        "ix_receipts_purchase_date", "receipts", ["purchase_date"], unique=False
    )
    op.create_index(
        "ix_receipts_warranty_expiry_date",
        "receipts",
        ["warranty_expiry_date"],
        unique=False,
    )
    op.create_index(
        "ix_receipts_return_expiry_date",
        "receipts",
        ["return_expiry_date"],
        unique=False,
    )
    op.create_index("ix_receipts_status", "receipts", ["status"], unique=False)
    op.create_index("ix_receipts_created_at", "receipts", ["created_at"], unique=False)
    op.create_index("ix_receipts_deleted_at", "receipts", ["deleted_at"], unique=False)

    # ── claim_documents ───────────────────────────────────────────────────────
    op.create_table(
        "claim_documents",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "receipt_id",
            sa.String(36),
            sa.ForeignKey("receipts.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("issue_description", sa.Text(), nullable=False),
        sa.Column("claim_type", sa.String(64), nullable=True),
        sa.Column("generated_pdf_s3_key", sa.String(512), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_claim_documents_id", "claim_documents", ["id"], unique=False)
    op.create_index(
        "ix_claim_documents_receipt_id", "claim_documents", ["receipt_id"], unique=False
    )
    op.create_index(
        "ix_claim_documents_created_at", "claim_documents", ["created_at"], unique=False
    )


def downgrade() -> None:
    op.drop_index("ix_claim_documents_created_at", table_name="claim_documents")
    op.drop_index("ix_claim_documents_receipt_id", table_name="claim_documents")
    op.drop_index("ix_claim_documents_id", table_name="claim_documents")
    op.drop_table("claim_documents")

    op.drop_index("ix_receipts_deleted_at", table_name="receipts")
    op.drop_index("ix_receipts_created_at", table_name="receipts")
    op.drop_index("ix_receipts_status", table_name="receipts")
    op.drop_index("ix_receipts_return_expiry_date", table_name="receipts")
    op.drop_index("ix_receipts_warranty_expiry_date", table_name="receipts")
    op.drop_index("ix_receipts_purchase_date", table_name="receipts")
    op.drop_index("ix_receipts_user_id", table_name="receipts")
    op.drop_index("ix_receipts_id", table_name="receipts")
    op.drop_table("receipts")
    op.execute("DROP TYPE IF EXISTS receiptstatus")

    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_firebase_uid", table_name="users")
    op.drop_index("ix_users_id", table_name="users")
    op.drop_table("users")
