# Market Basket Analysis for E-Commerce Product Bundling using SQL

Proyek ini berfokus pada **Market Basket Analysis (Analisis Keranjang Belanja)** menggunakan teknik *Self-Join* di SQL untuk mengidentifikasi kombinasi kategori produk yang paling sering dibeli secara bersamaan oleh pelanggan dalam satu transaksi tunggal. Data yang digunakan adalah data transaksi riil dari platform e-commerce Olist (Brasil).

---

## 1. Latar Belakang & Problem Statement

Menargetkan pelanggan baru membutuhkan biaya pemasaran yang besar. Strategi alternatif yang jauh lebih efisien untuk menaikkan pendapatan adalah dengan meningkatkan **Average Order Value (AOV)**—yaitu mendorong pelanggan yang sudah siap membeli agar menambah lebih banyak item ke dalam keranjang belanja mereka sebelum melakukan *checkout*.

**Problem Statement:**
Tim *Merchandising* dan *Marketing* ingin membuat program promo paket hemat (*product bundling*) dan fitur *cross-selling* otomatis di aplikasi, tetapi tidak tahu kombinasi kategori produk apa saja yang memiliki asosiasi kuat dan dibeli bersamaan oleh pelanggan.

**Tujuan Proyek:**
1. Mengidentifikasi pola hubungan (*association rules*) antar-kategori produk menggunakan logika *Self-Join* berbasis `order_id`.
2. Menyaring top 20 pasangan produk dengan frekuensi pembelian bersamaan tertinggi.
3. Memberikan rekomendasi taktis berupa strategi penempatan produk, promosi paket *bundling*, dan optimalisasi UI/UX aplikasi.

---

## 2. Dataset & Hubungan Data (ERD)

Analisis ini memanfaatkan 3 file data dari Olist dataset yang saling terhubung:
* **`olist_order_items`**: Menyediakan data `order_id` (nomor struk belanja) dan `product_id` (kode produk).
* **`olist_products`**: Menyediakan hubungan antara `product_id` dengan nama kategori produk asli (Bahasa Portugis).
* **`olist_category_translation`**: Berfungsi sebagai kamus bahasa untuk menerjemahkan nama kategori produk ke Bahasa Inggris agar siap digunakan untuk laporan internasional.

---

## 3. Implementasi SQL (Step-by-Step)

### Langkah 3.1: Data Ingestion (Membuat Tabel Kosong)
Membuat tiga struktur tabel baru dengan tipe data teks (`VARCHAR`) untuk memastikan seluruh data mentah dari CSV masuk dengan aman tanpa kendala format.

```sql
-- 1. Membuat tabel item pesanan
CREATE TABLE olist_order_items (
    order_id VARCHAR(500),
    order_item_id VARCHAR(500),
    product_id VARCHAR(500),
    seller_id VARCHAR(500),
    shipping_limit_date VARCHAR(500),
    price VARCHAR(500),
    freight_value VARCHAR(500)
);

-- 2. Membuat tabel spesifikasi produk
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

-- 3. Membuat tabel kamus bahasa terjemahan
CREATE TABLE olist_category_translation (
    product_category_name VARCHAR(500),
    product_category_name_english VARCHAR(500)
);
```

### Langkah 3.2: Penyelarasan Bahasa & Data (Pembuatan View)
Menggabungkan data item pesanan dengan kamus bahasa menggunakan `LEFT JOIN` untuk menerjemahkan nama kategori ke Bahasa Inggris (contoh: mengubah *beleza_saude* menjadi *health_beauty*).

```sql
CREATE OR REPLACE VIEW v_order_items_english AS
SELECT 
    oi.order_id,
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category_english
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
LEFT JOIN olist_category_translation t ON p.product_category_name = t.product_category_name;
```

### Langkah 3.3: Analisis Asosiasi Produk (SQL Self-Join)
Menggunakan teknik *Self-Join* pada View `v_order_items_english` berdasarkan nomor nota (`order_id`) yang sama. Filter `a.category_english < b.category_english` digunakan agar produk tidak berpasangan dengan dirinya sendiri dan menghindari duplikasi urutan pasangan (misal: jika sudah dihitung paket A-B, tidak perlu memunculkan paket B-A).

```sql
WITH product_pairs AS (
    SELECT 
        a.category_english AS product_a,
        b.category_english AS product_b,
        a.order_id
    FROM v_order_items_english a
    JOIN v_order_items_english b ON a.order_id = b.order_id
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
```

---

## 4. Temuan Utama (Key Insights Berdasarkan Data Riil)

Berdasarkan hasil eksekusi query yang tersimpan pada `olist_market_basket.csv`, ditemukan pola perilaku belanja kelompok (*cross-category purchasing*) yang sangat kuat:

1. **Kluster Home & Living Dominan:** 
   * Pasangan produk tertinggi di platform Olist adalah **`bed_bath_table` (perlengkapan kasur/mandi)** dan **`furniture_decor` (dekorasi perabot)** yang dibeli bersamaan sebanyak **70 kali** dalam satu transaksi.
   * Di peringkat kedua, **`bed_bath_table`** juga dibeli bersamaan dengan **`home_confort`** sebanyak **43 kali**.
   * Peringkat ketiga ditempati oleh kombinasi **`furniture_decor`** dan **`housewares` (peralatan rumah tangga)** sebanyak **24 kali**.
   
   *Insight Bisnis:* Hal ini mengindikasikan adanya segmen pelanggan yang sangat spesifik, yaitu kelompok pengguna yang sedang melakukan **pindahan rumah baru atau renovasi/dekorasi ulang kamar tidur**.

2. **Kluster Kebutuhan Anak (Baby & Kids):**
   * Produk kategori **`baby`** memiliki hubungan erat dengan **`cool_stuff`** (**20 kali**) dan **`toys` (mainan)** (**19 kali**). Pelanggan cenderung menyatukan kebutuhan dasar anak dengan produk hiburan/mainan sekaligus dalam satu pesanan.

---

## 5. Rekomendasi Strategi Bisnis

### A. Strategi Kampanye Pemasaran (Product Bundling Promo)
* **Paket "Isi Kamar Baru":** Buat paket promo gabungan khusus berisi produk *Bed & Bath Table* dan *Furniture Decor* dengan diskon khusus sebesar 10% jika dibeli secara bersamaan. Paket ini ditargetkan langsung kepada pengguna yang masuk ke dalam segmen *New Customers* pada analisis RFM sebelumnya.
* **Paket Hadiah Anak:** Buat kombo produk berkategori *Baby* dan *Toys* menjelang musim liburan atau hari anak internasional untuk meningkatkan volume penjualan barang-barang mainan.

### B. Strategi Optimalisasi Aplikasi (UI/UX & Recommender System)
* **Fitur Cross-Selling Otomatis:** Ketika seorang pelanggan memasukkan item dari kategori `bed_bath_table` ke dalam keranjang, algoritma aplikasi harus memicu *pop-up* rekomendasi di bagian bawah layar yang bertuliskan: *"Pelanggan lain juga membeli produk Dekorasi Perabot ini untuk mempercantik ruangan mereka. Tambahkan sekarang?"*.
* **Penempatan Tata Letak Banner:** Pada halaman beranda (*homepage*) aplikasi e-commerce, letakkan *banner* promosi kategori *Housewares* berdekatan atau sejajar dengan promosi kategori *Furniture Decor* untuk memicu ketertarikan belanja impulsif (*impulse buying*).
