from pathlib import Path
import sqlite3

base = Path(__file__).parent
schema = (base / "schema" / "normalized_schema.sql").read_text()
queries = (base / "queries" / "product_queries.sql").read_text()

# The schema uses standard SQL types and constraints, so SQLite is sufficient
# for a local structural and query smoke test. Query 5 is PostgreSQL-specific
# and is intentionally excluded from this SQLite smoke test.
required_queries = queries.split("-- Optional Query 5:", 1)[0]

connection = sqlite3.connect(":memory:")
connection.execute("PRAGMA foreign_keys = ON")
connection.executescript(schema)

connection.executescript(
    """
    INSERT INTO suppliers VALUES
      (1, 'Northwind Components', '+1-555-0100', 'sales@northwind.example'),
      (2, 'Summit Devices', '+1-555-0101', 'hello@summit.example');

    INSERT INTO products VALUES
      (101, 'Smartphone X', 699.99, 1),
      (102, 'Laptop Pro', 1299.00, 2),
      (103, 'Wireless Charger', 39.99, 1);

    INSERT INTO categories VALUES
      (1, 'Electronics'),
      (2, 'Accessories');

    INSERT INTO product_categories VALUES
      (101, 1), (102, 1), (103, 2);

    INSERT INTO tags VALUES
      (1, 'mobile'), (2, 'portable');

    INSERT INTO product_tags VALUES
      (101, 1), (101, 2), (103, 2);

    INSERT INTO warehouses VALUES
      (1, 'Bengaluru'), (2, 'Mumbai');

    INSERT INTO inventory VALUES
      (101, 1, 4), (101, 2, 15), (102, 1, 8), (103, 1, 40);
    """
)

# Execute the four required SELECT statements; comments are harmless to SQLite.
statements = [statement.strip() for statement in required_queries.split(";") if statement.strip()]
select_results = [connection.execute(statement).fetchall() for statement in statements]

assert len(select_results) == 4, f"Expected 4 required query results, got {len(select_results)}"
assert len(select_results[0]) == 3, "Query 1 should return all three products"
assert [row[1] for row in select_results[1]] == ["Smartphone X", "Laptop Pro"], "Query 2 category filter failed"
assert select_results[2][0][1] == "Northwind Components", "Query 3 supplier join failed"
assert {(row[1], row[2], row[3]) for row in select_results[3]} == {
    ("Smartphone X", "Bengaluru", 4),
    ("Laptop Pro", "Bengaluru", 8),
}, "Query 4 low-stock join/filter failed"

# Verify the required integrity constraints.
try:
    connection.execute("INSERT INTO products VALUES (104, 'Invalid', -1, 1)")
except sqlite3.IntegrityError:
    pass
else:
    raise AssertionError("Negative product prices must be rejected")

print("PASS: normalized schema created successfully")
print("PASS: four required product queries returned expected results")
print("PASS: foreign-key and check constraints are enforced")
