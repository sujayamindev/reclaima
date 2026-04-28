"""add_notification_overrides

Add per-product notification lead time overrides to receipt_line_items.
Allows users to override global warranty/return lead times on a per-item basis.

Columns added:
  - warranty_lead_days_override (Integer, nullable) — override for warranty lead time
  - return_lead_days_override (Integer, nullable) — override for return lead time

When set, these override the user's global notification preferences for that specific product.
NULL values mean "use the user's global preference".

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-03-18 14:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "e5f6a7b8c9d0"
down_revision = "d4e5f6a7b8c9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Add warranty_lead_days_override to receipt_line_items ──────────────────
    op.add_column(
        "receipt_line_items",
        sa.Column("warranty_lead_days_override", sa.Integer(), nullable=True),
    )

    # ── Add return_lead_days_override to receipt_line_items ────────────────────
    op.add_column(
        "receipt_line_items",
        sa.Column("return_lead_days_override", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    # ── Remove return_lead_days_override from receipt_line_items ───────────────
    op.drop_column("receipt_line_items", "return_lead_days_override")

    # ── Remove warranty_lead_days_override from receipt_line_items ─────────────
    op.drop_column("receipt_line_items", "warranty_lead_days_override")
