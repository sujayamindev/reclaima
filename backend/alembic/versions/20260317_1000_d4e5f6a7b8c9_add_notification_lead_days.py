"""add_notification_lead_days

Adds warranty_lead_days and return_lead_days columns to
user_notification_preferences so each user can configure how many
days before expiry they want to receive push notifications.

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-03-17 10:00:00.000000
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "d4e5f6a7b8c9"
down_revision = "c3d4e5f6a7b8"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "user_notification_preferences",
        sa.Column(
            "warranty_lead_days", sa.Integer(), nullable=False, server_default="30"
        ),
    )
    op.add_column(
        "user_notification_preferences",
        sa.Column("return_lead_days", sa.Integer(), nullable=False, server_default="3"),
    )


def downgrade() -> None:
    op.drop_column("user_notification_preferences", "return_lead_days")
    op.drop_column("user_notification_preferences", "warranty_lead_days")
