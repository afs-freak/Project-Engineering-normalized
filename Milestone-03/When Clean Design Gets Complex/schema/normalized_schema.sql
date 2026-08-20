-- NORMALIZED DATABASE SCHEMA (3NF)
-- E-commerce products, suppliers, categories, tags, and inventory.
-- The schema is intentionally data-independent: seed data can be loaded separately.

-- A supplier is an independent entity. Supplier contact details depend only
-- on supplier_id, not on a product or any other non-key attribute.
CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_phone VARCHAR(20),
    supplier_email VARCHAR(100),
    CONSTRAINT uq_suppliers_email UNIQUE (supplier_email)
);

-- A product contains only product-level attributes. Supplier details are
-- referenced through supplier_id rather than duplicated in every product row.
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    supplier_id INT NOT NULL,
    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id) REFERENCES suppliers (supplier_id),
    CONSTRAINT ck_products_price_non_negative CHECK (price >= 0)
);

-- Categories are independent entities and can be shared by many products.
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    CONSTRAINT uq_categories_name UNIQUE (category_name)
);

-- Many-to-many product/category relationship. The composite primary key
-- prevents the same category from being assigned twice to one product.
CREATE TABLE product_categories (
    product_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_product_categories_product
        FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_product_categories_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
);

-- Tags are also independent, reusable entities. This removes the
-- comma-separated product_tags column and preserves one value per row.
CREATE TABLE tags (
    tag_id INT PRIMARY KEY,
    tag_name VARCHAR(100) NOT NULL,
    CONSTRAINT uq_tags_name UNIQUE (tag_name)
);

CREATE TABLE product_tags (
    product_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (product_id, tag_id),
    CONSTRAINT fk_product_tags_product
        FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_product_tags_tag
        FOREIGN KEY (tag_id) REFERENCES tags (tag_id)
);

-- Warehouses are independent from inventory quantities. A location is stored
-- once and referenced by inventory rows.
CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_location VARCHAR(100) NOT NULL,
    CONSTRAINT uq_warehouses_location UNIQUE (warehouse_location)
);

-- Inventory is an associative entity between products and warehouses. A
-- product can therefore have one quantity per warehouse without repeating
-- warehouse data in the products table.
CREATE TABLE inventory (
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    PRIMARY KEY (product_id, warehouse_id),
    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_inventory_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    CONSTRAINT ck_inventory_quantity_non_negative CHECK (stock_quantity >= 0)
);

-- Foreign-key indexes improve joins and common filtering without duplicating
-- business attributes. Primary and unique constraints already index their keys.
CREATE INDEX idx_products_supplier_id ON products (supplier_id);
CREATE INDEX idx_product_categories_category_id ON product_categories (category_id);
CREATE INDEX idx_product_tags_tag_id ON product_tags (tag_id);
CREATE INDEX idx_inventory_warehouse_id ON inventory (warehouse_id);
CREATE INDEX idx_inventory_low_stock ON inventory (stock_quantity, product_id);
