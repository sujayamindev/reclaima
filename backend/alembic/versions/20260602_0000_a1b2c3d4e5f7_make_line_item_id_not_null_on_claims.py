"""make_line_item_id_not_null_on_claims

Revision ID: a1b2c3d4e5f7
Revises: 90123456fghi
Create Date: 2026-06-02 00:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "a1b2c3d4e5f7"
down_revision: Union[str, None] = "90123456fghi"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "claim_documents",
        "line_item_id",
        existing_type=sa.String(length=36),
        nullable=False,
    )


def downgrade() -> None:
    op.alter_column(
        "claim_documents",
        "line_item_id",
        existing_type=sa.String(length=36),
        nullable=True,
    )
