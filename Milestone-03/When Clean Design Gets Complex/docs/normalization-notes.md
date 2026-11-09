# Database Normalization Notes

## Scope

The original `products` table combined product, supplier, category, tagging, and inventory data. That structure made the table difficult to maintain because one row represented several different entities and some columns stored multiple values as comma-separated text.

## Problems identified

| Original attribute or design | Normalization issue | Consequence |
| --- | --- | --- |
| `categories` | A multi-valued, comma-separated attribute violates 1NF. | Category filtering requires string matching and is vulnerable to inconsistent spelling. |
| `product_tags` | A multi-valued, comma-separated attribute violates 1NF. | Individual tags cannot be indexed or constrained as rows. |
| `supplier_name`, `supplier_phone`, `supplier_email` in `products` | Supplier facts are repeated for every product and depend on `supplier_name`/`supplier_id`, not on the product entity. | Updates can become inconsistent and supplier data is duplicated. |
| `warehouse_location`, `stock_quantity` in `products` | Inventory is a separate entity and stock is specific to a product/warehouse combination. | A product cannot represent multiple warehouses without adding more repeating columns or rows. |
| No relationship tables | Many-to-many relationships are encoded as text instead of keys. | Joins, referential integrity, and selective indexes are unavailable. |
| No supporting indexes | Foreign-key and common filter paths are not explicitly optimized. | Joins and low-stock filtering can degrade as data grows. |

## Redesign

The solution in `schema/normalized_schema.sql` separates the model into the following entities and relationships:

| Table | Responsibility | Key relationship |
| --- | --- | --- |
| `products` | Product-level attributes and price. | Each product references one supplier. |
| `suppliers` | Supplier identity and contact information. | One supplier can provide many products. |
| `categories` | A reusable category vocabulary. | Products connect through `product_categories`. |
| `product_categories` | Product/category many-to-many relationship. | Composite primary key prevents duplicate assignments. |
| `tags` | A reusable tag vocabulary. | Products connect through `product_tags`. |
| `product_tags` | Product/tag many-to-many relationship. | Composite primary key prevents duplicate assignments. |
| `warehouses` | A reusable warehouse/location vocabulary. | Inventory rows reference a warehouse. |
| `inventory` | Stock quantity for each product at each warehouse. | Composite primary key is `(product_id, warehouse_id)`. |

This design satisfies 1NF by storing one value per column, 2NF by placing attributes in tables where they depend on the complete key, and 3NF by removing attributes that depend transitively on another non-key attribute. Primary keys, foreign keys, unique constraints, and check constraints make those relationships explicit.

## Query changes

The original category predicate used `LIKE` against a comma-separated string. The revised query joins `products` to `product_categories` and then to `categories`, allowing the database to compare one category value at a time. Supplier lookup now joins `products` to `suppliers`, and low-stock lookup joins `inventory` to both `products` and `warehouses` so the result identifies where the stock is held.

Normalization introduces additional joins. That is the principal usability and performance trade-off: the schema is cleaner and safer to update, while read queries become more explicit. The schema therefore adds indexes on foreign keys and on the low-stock access path. If analytics later require a repeated reporting shape, a materialized view or a carefully controlled read model could be introduced without weakening the source-of-truth schema.

## Verification

`test_normalized_schema.py` builds the schema in an in-memory SQLite database, loads representative suppliers, products, categories, tags, warehouses, and inventory rows, and executes the four required query patterns. It verifies that the joins return the expected products and supplier data, that warehouse-specific low-stock rows are returned, and that a negative product price is rejected by a check constraint.

Run the verification from this challenge directory with:

```bash
python3 test_normalized_schema.py
```

Expected output:

```text
PASS: normalized schema created successfully
PASS: four required product queries returned expected results
PASS: foreign-key and check constraints are enforced
```
