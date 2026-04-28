"""add_line_item_resolution_columns

Revision ID: 23456789abcd
Revises: 1234567890ab
Create Date: 2026-03-22 12:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "23456789abcd"
down_revision: Union[str, None] = "1234567890ab"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "receipt_line_items",
        sa.Column(
            "status", sa.String(length=50), server_default="ACTIVE", nullable=False
        ),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("replacement_for_id", sa.String(length=36), nullable=True),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("replaced_by_id", sa.String(length=36), nullable=True),
    )

    op.create_foreign_key(
        "fk_receipt_line_items_replacement_for_id",
        "receipt_line_items",
        "receipt_line_items",
        ["replacement_for_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        "ix_receipt_line_items_status",
        "receipt_line_items",
        ["status"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_receipt_line_items_status", table_name="receipt_line_items")
    op.drop_constraint(
        "fk_receipt_line_items_replacement_for_id",
        "receipt_line_items",
        type_="foreignkey",
    )
    op.drop_column("receipt_line_items", "replaced_by_id")
    op.drop_column("receipt_line_items", "replacement_for_id")
    op.drop_column("receipt_line_items", "status")
