"""db_fixes

Structural fixes addressing multiple issues:
  - Issue 2:  Float → Numeric(12,2) for all monetary columns
  - Issue 5:  Add composite index (user_id, created_at) on receipts
  - Issue 6:  Add updated_at + deleted_at to receipt_line_items
  - Issue 10: Add fcm_token to users
  - Issue 11: Create user_notification_preferences table

Revision ID: a1b2c3d4e5f6
Revises: 6faa1167a629
Create Date: 2026-03-01 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a1b2c3d4e5f6"
down_revision = "6faa1167a629"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Issue 2: Float → Numeric(12,2) for money columns ─────────────────────
    # receipts.total_amount
    op.alter_column(
        "receipts",
        "total_amount",
        type_=sa.Numeric(precision=12, scale=2),
        existing_type=sa.Float(),
        existing_nullable=True,
        postgresql_using="total_amount::numeric(12,2)",
    )
    # receipt_line_items.unit_price
    op.alter_column(
        "receipt_line_items",
        "unit_price",
        type_=sa.Numeric(precision=12, scale=2),
        existing_type=sa.Float(),
        existing_nullable=True,
        postgresql_using="unit_price::numeric(12,2)",
    )
    # receipt_line_items.amount
    op.alter_column(
        "receipt_line_items",
        "amount",
        type_=sa.Numeric(precision=12, scale=2),
        existing_type=sa.Float(),
        existing_nullable=True,
        postgresql_using="amount::numeric(12,2)",
    )

    # ── Issue 5: Composite index (user_id, created_at) on receipts ───────────
    op.create_index(
        "ix_receipts_user_id_created_at",
        "receipts",
        ["user_id", "created_at"],
        unique=False,
    )

    # ── Issue 6: Add updated_at and deleted_at to receipt_line_items ─────────
    op.add_column(
        "receipt_line_items",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )

    # ── Issue 10: Add fcm_token to users ──────────────────────────────────────
    op.add_column(
        "users",
        sa.Column("fcm_token", sa.String(512), nullable=True),
    )

    # ── Issue 11: Create user_notification_preferences table ─────────────────
    op.create_table(
        "user_notification_preferences",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column(
            "warranty_reminders_enabled",
            sa.Boolean(),
            nullable=False,
            server_default="true",
        ),
        sa.Column(
            "return_reminders_enabled",
            sa.Boolean(),
            nullable=False,
            server_default="true",
        ),
        sa.Column(
            "ocr_notifications_enabled",
            sa.Boolean(),
            nullable=False,
            server_default="true",
        ),
        sa.Column("quiet_hours_start", sa.Integer(), nullable=True),  # hour 0-23
        sa.Column("quiet_hours_end", sa.Integer(), nullable=True),  # hour 0-23
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
    )
    op.create_index(
        "ix_user_notification_preferences_id",
        "user_notification_preferences",
        ["id"],
        unique=False,
    )
    op.create_index(
        "ix_user_notification_preferences_user_id",
        "user_notification_preferences",
        ["user_id"],
        unique=True,
    )


def downgrade() -> None:
    # ── Issue 11 ──────────────────────────────────────────────────────────────
    op.drop_index(
        "ix_user_notification_preferences_user_id",
        table_name="user_notification_preferences",
    )
    op.drop_index(
        "ix_user_notification_preferences_id",
        table_name="user_notification_preferences",
    )
    op.drop_table("user_notification_preferences")

    # ── Issue 10 ──────────────────────────────────────────────────────────────
    op.drop_column("users", "fcm_token")

    # ── Issue 6 ───────────────────────────────────────────────────────────────
    op.drop_column("receipt_line_items", "deleted_at")
    op.drop_column("receipt_line_items", "updated_at")

    # ── Issue 5 ───────────────────────────────────────────────────────────────
    op.drop_index("ix_receipts_user_id_created_at", table_name="receipts")

    # ── Issue 2 ───────────────────────────────────────────────────────────────
    op.alter_column(
        "receipt_line_items",
        "amount",
        type_=sa.Float(),
        existing_type=sa.Numeric(precision=12, scale=2),
        existing_nullable=True,
    )
    op.alter_column(
        "receipt_line_items",
        "unit_price",
        type_=sa.Float(),
        existing_type=sa.Numeric(precision=12, scale=2),
        existing_nullable=True,
    )
    op.alter_column(
        "receipts",
        "total_amount",
        type_=sa.Float(),
        existing_type=sa.Numeric(precision=12, scale=2),
        existing_nullable=True,
    )
