-- PRODUCT QUERIES FOR THE NORMALIZED 3NF SCHEMA
-- These queries preserve the original application use cases while using
-- explicit JOINs for normalized relationships.

-- Query 1: Get all products with their supplier name.
SELECT
    p.product_id,
    p.product_name,
    p.price,
    s.supplier_name
FROM products AS p
JOIN suppliers AS s
    ON s.supplier_id = p.supplier_id
ORDER BY p.product_id;


-- Query 2: Find products in a specific category.
-- The relationship table allows a product to belong to multiple categories.
-- DISTINCT prevents duplicate products if the join is later extended.
SELECT DISTINCT
    p.product_id,
    p.product_name,
    p.price
FROM products AS p
JOIN product_categories AS pc
    ON pc.product_id = p.product_id
JOIN categories AS c
    ON c.category_id = pc.category_id
WHERE c.category_name = 'Electronics'
ORDER BY p.product_id;


-- Query 3: Find supplier details for each product.
SELECT
    p.product_name,
    s.supplier_name,
    s.supplier_phone,
    s.supplier_email
FROM products AS p
JOIN suppliers AS s
    ON s.supplier_id = p.supplier_id
ORDER BY p.product_id;


-- Query 4: Find products with low stock, including the warehouse location.
-- Inventory is warehouse-specific after normalization, so a product can
-- appear once for each warehouse where its quantity is below the threshold.
SELECT
    p.product_id,
    p.product_name,
    w.warehouse_location,
    i.stock_quantity
FROM inventory AS i
JOIN products AS p
    ON p.product_id = i.product_id
JOIN warehouses AS w
    ON w.warehouse_id = i.warehouse_id
WHERE i.stock_quantity < 10
ORDER BY i.stock_quantity ASC, p.product_id, w.warehouse_id;


-- Optional Query 5: List each product's categories and tags.
-- Aggregation keeps the result readable while the underlying data remains
-- atomic in product_categories and product_tags.
SELECT
    p.product_id,
    p.product_name,
    STRING_AGG(DISTINCT c.category_name, ', ' ORDER BY c.category_name) AS categories,
    STRING_AGG(DISTINCT t.tag_name, ', ' ORDER BY t.tag_name) AS tags
FROM products AS p
LEFT JOIN product_categories AS pc
    ON pc.product_id = p.product_id
LEFT JOIN categories AS c
    ON c.category_id = pc.category_id
LEFT JOIN product_tags AS pt
    ON pt.product_id = p.product_id
LEFT JOIN tags AS t
    ON t.tag_id = pt.tag_id
GROUP BY p.product_id, p.product_name
ORDER BY p.product_id;

-- Notes:
-- 1. Query 2 replaces the broken categories LIKE predicate with relationship joins.
-- 2. Query 3 reads supplier attributes from suppliers, eliminating duplication.
-- 3. Query 4 reads warehouse-specific quantities from inventory.
-- 4. Query 5 uses PostgreSQL STRING_AGG; omit it or use the equivalent aggregate
--    function when running on another SQL dialect.
