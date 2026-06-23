-- 2. Buat tabel item pesanan (Sesuai olist_order_items_dataset.csv)
CREATE TABLE olist_order_items (
    order_id VARCHAR(500),
    order_item_id VARCHAR(500),
    product_id VARCHAR(500),
    seller_id VARCHAR(500),
    shipping_limit_date VARCHAR(500),
    price VARCHAR(500),
    freight_value VARCHAR(500)
);

-- 3. Buat tabel produk (Sesuai olist_products_dataset.csv)
CREATE TABLE olist_products (
    product_id VARCHAR(500),
    product_category_name VARCHAR(500),
    product_name_lenght VARCHAR(500),
    product_description_lenght VARCHAR(500),
    product_photos_qty VARCHAR(500),
    product_weight_g VARCHAR(500),
    product_length_cm VARCHAR(500),
    product_height_cm VARCHAR(500),
    product_width_cm VARCHAR(500)
);

-- 4. Buat tabel kamus bahasa (Sesuai product_category_name_translation.csv)
CREATE TABLE olist_category_translation (
    product_category_name VARCHAR(500),
    product_category_name_english VARCHAR(500)
);

CREATE OR REPLACE VIEW v_order_items_english AS
SELECT 
    oi.order_id,
    oi.product_id,
    -- Jika terjemahan inggris kosong, gunakan nama asli Portugis. Jika kosong semua, beri tanda 'unknown'
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category_english
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
LEFT JOIN olist_category_translation t ON p.product_category_name = t.product_category_name;

WITH product_pairs AS (
    SELECT 
        a.category_english AS product_a,
        b.category_english AS product_b,
        a.order_id
    FROM v_order_items_english a
    -- Self-join menggunakan order_id yang sama
    JOIN v_order_items_english b ON a.order_id = b.order_id
    -- FILTER UTAMA: 
    -- 1. Memastikan tidak memasangkan produk dengan dirinya sendiri (misal: Baju A dengan Baju A)
    -- 2. Menggunakan tanda '<' agar pasangan tidak terhitung ganda (misal: jika sudah ada paket A-B, tidak perlu memunculkan paket B-A)
    WHERE a.category_english < b.category_english
)
SELECT 
    product_a AS kategori_produk_1,
    product_b AS kategori_produk_2,
    COUNT(DISTINCT order_id) AS frekuensi_dibeli_bersamaan
FROM product_pairs
GROUP BY product_a, product_b
ORDER BY frekuensi_dibeli_bersamaan DESC
LIMIT 20;