"""Add claim_defect_images table

Revision ID: 78901234defg
Revises: 67890123cdef
Create Date: 2026-03-29 04:08:00.000000

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "78901234defg"
down_revision = "67890123cdef"
branch_labels = None
depends_on = None


def upgrade():
    """Add claim_defect_images table to store defect image references.

    This table enables storing multiple defect/issue images per claim that users
    upload to provide visual evidence of product defects when creating warranty
    or return claims.
    """

    # Create claim_defect_images table
    op.create_table(
        "claim_defect_images",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("claim_id", sa.String(length=36), nullable=False),
        sa.Column("s3_object_key", sa.String(length=512), nullable=False),
        sa.Column("display_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(
            ["claim_id"], ["claim_documents.id"], ondelete="CASCADE"
        ),
    )

    # Create indexes for efficient querying
    op.create_index(
        "ix_claim_defect_images_claim_id", "claim_defect_images", ["claim_id"]
    )
    op.create_index(
        "ix_claim_defect_images_display_order", "claim_defect_images", ["display_order"]
    )
    op.create_index("ix_claim_defect_images_id", "claim_defect_images", ["id"])


def downgrade():
    """Remove claim_defect_images table (for rollback only)."""

    # Drop indexes first
    op.drop_index("ix_claim_defect_images_id", table_name="claim_defect_images")
    op.drop_index(
        "ix_claim_defect_images_display_order", table_name="claim_defect_images"
    )
    op.drop_index("ix_claim_defect_images_claim_id", table_name="claim_defect_images")

    # Drop table
    op.drop_table("claim_defect_images")
