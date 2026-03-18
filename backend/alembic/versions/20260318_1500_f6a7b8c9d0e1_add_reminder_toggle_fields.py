"""add_reminder_toggle_fields

Add per-product notification toggle fields to receipt_line_items.
Allows users to enable/disable notifications for specific products separately from lead time customization.

Columns added:
  - warranty_reminder_enabled (Boolean, default=True) — whether to send warranty notifications for this product
  - return_reminder_enabled (Boolean, default=True) — whether to send return notifications for this product

When False, notifications will not be sent for that product even if lead times exist.
Default to True to maintain backward compatibility with existing products.

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-03-18 15:00:00.000000
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'f6a7b8c9d0e1'
down_revision = 'e5f6a7b8c9d0'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Add warranty_reminder_enabled to receipt_line_items ──────────────────
    op.add_column(
        'receipt_line_items',
        sa.Column(
            'warranty_reminder_enabled',
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
    )

    # ── Add return_reminder_enabled to receipt_line_items ────────────────────
    op.add_column(
        'receipt_line_items',
        sa.Column(
            'return_reminder_enabled',
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
    )


def downgrade() -> None:
    # ── Remove return_reminder_enabled from receipt_line_items ───────────────
    op.drop_column('receipt_line_items', 'return_reminder_enabled')

    # ── Remove warranty_reminder_enabled from receipt_line_items ─────────────
    op.drop_column('receipt_line_items', 'warranty_reminder_enabled')
