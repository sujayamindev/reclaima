"""add_line_item_id_to_claims

Revision ID: 34567890cdef
Revises: 23456789abcd
Create Date: 2026-03-24 01:30:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "34567890cdef"
down_revision: Union[str, None] = "23456789abcd"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "claim_documents",
        sa.Column("line_item_id", sa.String(length=36), nullable=True),
    )
    op.create_foreign_key(
        "fk_claim_documents_line_item_id",
        "claim_documents",
        "receipt_line_items",
        ["line_item_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index(
        "ix_claim_documents_line_item_id",
        "claim_documents",
        ["line_item_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_claim_documents_line_item_id", table_name="claim_documents")
    op.drop_constraint(
        "fk_claim_documents_line_item_id", "claim_documents", type_="foreignkey"
    )
    op.drop_column("claim_documents", "line_item_id")
