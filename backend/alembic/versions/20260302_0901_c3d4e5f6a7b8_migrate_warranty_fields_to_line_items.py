"""migrate_warranty_fields_to_line_items

Moves product/warranty/return fields from the receipts table to
receipt_line_items so each purchased item tracks its own warranty.

Data migration:
  - For existing receipts that have warranty/product data:
    * If no line items exist: insert a synthetic "Primary Item" row
    * If line items exist: copy receipt-level data onto the first line item
  - Removes the 7 migrated columns from receipts
  - Adds new indexes on line_items for the scheduler

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-03-02 09:01:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import uuid

# revision identifiers, used by Alembic.
revision = "c3d4e5f6a7b8"
down_revision = "b2c3d4e5f6a7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── 1. Add warranty/product columns to receipt_line_items ─────────────
    op.add_column(
        "receipt_line_items", sa.Column("product_name", sa.String(512), nullable=True)
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("product_category", sa.String(128), nullable=True),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("product_image_url", sa.String(2048), nullable=True),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("warranty_period_months", sa.Integer(), nullable=True),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("warranty_expiry_date", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("return_period_days", sa.Integer(), nullable=True),
    )
    op.add_column(
        "receipt_line_items",
        sa.Column("return_expiry_date", sa.DateTime(timezone=True), nullable=True),
    )

    # ── 2. Add indexes for scheduler queries ──────────────────────────────
    op.create_index(
        "ix_line_items_warranty_expiry_date",
        "receipt_line_items",
        ["warranty_expiry_date"],
        unique=False,
    )
    op.create_index(
        "ix_line_items_return_expiry_date",
        "receipt_line_items",
        ["return_expiry_date"],
        unique=False,
    )

    # ── 3. Data migration ─────────────────────────────────────────────────
    # Run inline SQL to migrate receipt-level warranty data to line items.
    # We use raw SQL for portability (no ORM models needed mid-migration).
    connection = op.get_bind()

    # Fetch receipts that have any warranty/product data worth migrating
    receipts = connection.execute(
        sa.text(
            """
        SELECT id, product_name, product_category, product_image_url,
               warranty_period_months, warranty_expiry_date,
               return_period_days, return_expiry_date, purchase_date
        FROM receipts
        WHERE deleted_at IS NULL
          AND (
            product_name IS NOT NULL
            OR warranty_period_months IS NOT NULL
            OR return_expiry_date IS NOT NULL
            OR warranty_expiry_date IS NOT NULL
          )
    """
        )
    ).fetchall()

    for row in receipts:
        receipt_id = row[0]

        # Check if any line items exist for this receipt
        item_count = connection.execute(
            sa.text(
                "SELECT COUNT(*) FROM receipt_line_items WHERE receipt_id = :rid AND deleted_at IS NULL"
            ),
            {"rid": receipt_id},
        ).scalar()

        if item_count == 0:
            # No line items — create a synthetic "Primary Item" row
            new_id = str(uuid.uuid4())
            connection.execute(
                sa.text(
                    """
                INSERT INTO receipt_line_items (
                    id, receipt_id, row_index,
                    item_description, product_name, product_category,
                    product_image_url, warranty_period_months,
                    warranty_expiry_date, return_period_days,
                    return_expiry_date, created_at, updated_at
                ) VALUES (
                    :id, :receipt_id, 0,
                    :item_description, :product_name, :product_category,
                    :product_image_url, :warranty_period_months,
                    :warranty_expiry_date, :return_period_days,
                    :return_expiry_date, NOW(), NOW()
                )
            """
                ),
                {
                    "id": new_id,
                    "receipt_id": receipt_id,
                    "item_description": row[1],  # product_name used as description
                    "product_name": row[1],
                    "product_category": row[2],
                    "product_image_url": row[3],
                    "warranty_period_months": row[4],
                    "warranty_expiry_date": row[5],
                    "return_period_days": row[6],
                    "return_expiry_date": row[7],
                },
            )
        else:
            # Line items exist — update the first one (lowest row_index).
            # PostgreSQL does not support ORDER BY/LIMIT in UPDATE;
            # use a subquery that selects the target row's ctid instead.
            connection.execute(
                sa.text(
                    """
                UPDATE receipt_line_items
                SET product_name = :product_name,
                    product_category = :product_category,
                    product_image_url = :product_image_url,
                    warranty_period_months = :warranty_period_months,
                    warranty_expiry_date = :warranty_expiry_date,
                    return_period_days = :return_period_days,
                    return_expiry_date = :return_expiry_date
                WHERE ctid = (
                    SELECT ctid FROM receipt_line_items
                    WHERE receipt_id = :receipt_id
                      AND deleted_at IS NULL
                    ORDER BY row_index ASC
                    LIMIT 1
                )
            """
                ),
                {
                    "receipt_id": receipt_id,
                    "product_name": row[1],
                    "product_category": row[2],
                    "product_image_url": row[3],
                    "warranty_period_months": row[4],
                    "warranty_expiry_date": row[5],
                    "return_period_days": row[6],
                    "return_expiry_date": row[7],
                },
            )

    # ── 4. Drop old indexes from receipts ─────────────────────────────────
    op.drop_index("ix_receipts_warranty_expiry_date", table_name="receipts")
    op.drop_index("ix_receipts_return_expiry_date", table_name="receipts")

    # ── 5. Remove migrated columns from receipts ──────────────────────────
    op.drop_column("receipts", "product_name")
    op.drop_column("receipts", "product_category")
    op.drop_column("receipts", "product_image_url")
    op.drop_column("receipts", "warranty_period_months")
    op.drop_column("receipts", "warranty_expiry_date")
    op.drop_column("receipts", "return_period_days")
    op.drop_column("receipts", "return_expiry_date")


def downgrade() -> None:
    # ── Re-add columns to receipts ─────────────────────────────────────────
    op.add_column("receipts", sa.Column("product_name", sa.String(512), nullable=True))
    op.add_column(
        "receipts", sa.Column("product_category", sa.String(128), nullable=True)
    )
    op.add_column(
        "receipts", sa.Column("product_image_url", sa.String(2048), nullable=True)
    )
    op.add_column(
        "receipts", sa.Column("warranty_period_months", sa.Integer(), nullable=True)
    )
    op.add_column(
        "receipts",
        sa.Column("warranty_expiry_date", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "receipts", sa.Column("return_period_days", sa.Integer(), nullable=True)
    )
    op.add_column(
        "receipts",
        sa.Column("return_expiry_date", sa.DateTime(timezone=True), nullable=True),
    )

    op.create_index(
        "ix_receipts_warranty_expiry_date", "receipts", ["warranty_expiry_date"]
    )
    op.create_index(
        "ix_receipts_return_expiry_date", "receipts", ["return_expiry_date"]
    )

    # ── Remove indexes from line_items ─────────────────────────────────────
    op.drop_index("ix_line_items_warranty_expiry_date", table_name="receipt_line_items")
    op.drop_index("ix_line_items_return_expiry_date", table_name="receipt_line_items")

    # ── Remove warranty columns from line_items ────────────────────────────
    op.drop_column("receipt_line_items", "product_name")
    op.drop_column("receipt_line_items", "product_category")
    op.drop_column("receipt_line_items", "product_image_url")
    op.drop_column("receipt_line_items", "warranty_period_months")
    op.drop_column("receipt_line_items", "warranty_expiry_date")
    op.drop_column("receipt_line_items", "return_period_days")
    op.drop_column("receipt_line_items", "return_expiry_date")
