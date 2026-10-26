-- ЛР2. Створення складних SQL запитів. Самойло Тарас, ІПЗ-32

-- ===== 2.1 INNER JOIN: товари з категоріями та постачальниками =====
SELECT p.product_name, c.category_name, s.company_name, p.unit_price
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN suppliers s ON p.supplier_id = s.supplier_id
ORDER BY c.category_name, p.product_name;

-- ===== 2.2 LEFT JOIN: усі клієнти з кількістю замовлень =====
SELECT c.contact_name, c.customer_type, r.region_name,
       COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN regions r ON c.region_id = r.region_id
GROUP BY c.customer_id, c.contact_name, c.customer_type, r.region_name
ORDER BY order_count DESC;

-- ===== 2.3 Множинне з'єднання (6 таблиць): деталі доставлених замовлень =====
SELECT o.order_id, o.order_date,
       cu.contact_name AS customer,
       e.last_name || ' ' || e.first_name AS employee,
       p.product_name, c.category_name,
       oi.quantity, oi.unit_price, oi.discount,
       ROUND(oi.quantity * oi.unit_price * (1 - oi.discount), 2) AS line_total
FROM orders o
JOIN customers cu   ON o.customer_id = cu.customer_id
JOIN employees e    ON o.employee_id = e.employee_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
JOIN categories c   ON p.category_id = c.category_id
WHERE o.order_status = 'delivered'
ORDER BY o.order_date, o.order_id;

-- ===== 3.1 Кількість товарів і ціни по категоріях =====
SELECT c.category_name,
       COUNT(p.product_id) AS product_count,
       ROUND(AVG(p.unit_price), 2) AS avg_price,
       MIN(p.unit_price) AS min_price,
       MAX(p.unit_price) AS max_price
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC;

-- ===== 3.2 Загальні продажі за регіонами (SUM, GROUP BY, HAVING) =====
SELECT r.region_name,
       COUNT(DISTINCT o.order_id) AS orders_count,
       SUM(oi.quantity) AS items_sold,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS total_sales,
       ROUND(AVG(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS avg_line_value
FROM regions r
JOIN customers cu   ON cu.region_id = r.region_id
JOIN orders o       ON o.customer_id = cu.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status <> 'pending'
GROUP BY r.region_id, r.region_name
HAVING COUNT(DISTINCT o.order_id) >= 2
ORDER BY total_sales DESC;

-- ===== 3.3 Постачальники з кількістю товарів більше 2 =====
SELECT s.company_name,
       COUNT(p.product_id) AS products_count,
       ROUND(AVG(p.unit_price), 2) AS avg_price,
       SUM(p.units_in_stock) AS total_in_stock
FROM suppliers s
JOIN products p ON p.supplier_id = s.supplier_id
GROUP BY s.supplier_id, s.company_name
HAVING COUNT(p.product_id) > 2
ORDER BY products_count DESC;

-- ===== 4.1 Корельований підзапит: товари дорожчі за середню ціну своєї категорії =====
SELECT p.product_name, p.unit_price, c.category_name
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY c.category_name, p.unit_price DESC;

-- ===== 4.2 Клієнти із замовленнями у 2024 році (IN) =====
SELECT customer_id, contact_name, city, customer_type
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'
)
ORDER BY contact_name;

-- ===== 4.3 EXISTS / NOT EXISTS: товари, які жодного разу не продавались =====
SELECT p.product_id, p.product_name, p.unit_price, p.units_in_stock
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id
)
ORDER BY p.product_name;

-- ===== 4.4 Підзапити у SELECT: загальна кількість продажів кожного товару =====
SELECT p.product_name, p.unit_price,
       (SELECT COALESCE(SUM(oi.quantity), 0)
          FROM order_items oi WHERE oi.product_id = p.product_id) AS total_sold,
       (SELECT COUNT(DISTINCT oi.order_id)
          FROM order_items oi WHERE oi.product_id = p.product_id) AS orders_count,
       (SELECT ROUND(AVG(unit_price), 2) FROM products) AS avg_price_all
FROM products p
ORDER BY total_sold DESC, p.product_name;

-- ===== 5.1 RIGHT JOIN: категорії та наявність товарів =====
SELECT c.category_name,
       COUNT(p.product_id) AS products_count,
       COALESCE(ROUND(AVG(p.unit_price), 2), 0) AS avg_price
FROM products p
RIGHT JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY products_count DESC;

-- ===== 5.2 FULL OUTER JOIN: усі категорії та всі товари =====
SELECT c.category_name, p.product_name, p.unit_price,
       CASE WHEN p.product_id IS NULL THEN 'категорія без товарів'
            WHEN c.category_id IS NULL THEN 'товар без категорії'
            ELSE 'є зв''язок' END AS link_status
FROM categories c
FULL OUTER JOIN products p ON c.category_id = p.category_id
ORDER BY (p.product_id IS NULL OR c.category_id IS NULL) DESC, c.category_name, p.product_name;

-- ===== 5.3 Self-join: співробітники та їхні керівники =====
SELECT e1.first_name || ' ' || e1.last_name AS employee,
       e1.title AS employee_title,
       e2.first_name || ' ' || e2.last_name AS manager,
       e2.title AS manager_title
FROM employees e1
LEFT JOIN employees e2 ON e1.reports_to = e2.employee_id
ORDER BY e2.last_name NULLS FIRST, e1.last_name;

-- ===== 5.4 Умовне з'єднання: додаткові умови в ON =====
SELECT cu.contact_name, cu.customer_type,
       COUNT(o.order_id) AS delivered_since_march,
       COALESCE(SUM(o.freight), 0) AS freight_sum
FROM customers cu
LEFT JOIN orders o
       ON o.customer_id = cu.customer_id
      AND o.order_status = 'delivered'
      AND o.order_date >= '2024-03-01'
GROUP BY cu.customer_id, cu.contact_name, cu.customer_type
ORDER BY delivered_since_march DESC, cu.contact_name;

-- ===== 5.5 ROW_NUMBER, RANK, DENSE_RANK: ранжування товарів у категорії =====
SELECT p.product_name, c.category_name, p.unit_price,
       RANK()       OVER (PARTITION BY c.category_name ORDER BY p.unit_price DESC) AS price_rank,
       DENSE_RANK() OVER (PARTITION BY c.category_name ORDER BY p.unit_price DESC) AS price_dense_rank,
       ROW_NUMBER() OVER (PARTITION BY c.category_name ORDER BY p.unit_price DESC) AS row_num
FROM products p
JOIN categories c ON p.category_id = c.category_id
ORDER BY c.category_name, p.unit_price DESC;

-- ===== 5.5б Різниця RANK / DENSE_RANK / ROW_NUMBER при однакових значеннях =====
SELECT p.product_name,
       COALESCE(SUM(oi.quantity), 0) AS total_sold,
       ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(oi.quantity), 0) DESC) AS row_num,
       RANK()       OVER (ORDER BY COALESCE(SUM(oi.quantity), 0) DESC) AS sold_rank,
       DENSE_RANK() OVER (ORDER BY COALESCE(SUM(oi.quantity), 0) DESC) AS sold_dense_rank
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_sold DESC, p.product_name;

-- ===== 5.6 LAG / LEAD: порівняння замовлення клієнта з попереднім =====
WITH order_totals AS (
    SELECT o.order_id, o.customer_id, o.order_date,
           ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS order_total
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
)
SELECT cu.contact_name, t.order_id, t.order_date, t.order_total,
       LAG(t.order_total)  OVER w AS prev_total,
       t.order_total - LAG(t.order_total) OVER w AS diff_vs_prev,
       t.order_date - LAG(t.order_date) OVER w AS days_since_prev,
       LEAD(t.order_date)  OVER w AS next_order_date
FROM order_totals t
JOIN customers cu ON cu.customer_id = t.customer_id
WINDOW w AS (PARTITION BY t.customer_id ORDER BY t.order_date, t.order_id)
ORDER BY cu.contact_name, t.order_date;

-- ===== 5.7 PARTITION BY: продажі співробітників по місяцях =====
WITH monthly AS (
    SELECT o.employee_id,
           DATE_TRUNC('month', o.order_date)::date AS month,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.employee_id, DATE_TRUNC('month', o.order_date)
)
SELECT m.month,
       e.last_name || ' ' || e.first_name AS employee,
       ROUND(m.revenue, 2) AS revenue,
       RANK() OVER (PARTITION BY m.month ORDER BY m.revenue DESC) AS rank_in_month,
       ROUND(100 * m.revenue / SUM(m.revenue) OVER (PARTITION BY m.month), 1) AS pct_of_month,
       ROUND(SUM(m.revenue) OVER (PARTITION BY m.employee_id ORDER BY m.month), 2) AS employee_running_total
FROM monthly m
JOIN employees e ON e.employee_id = m.employee_id
ORDER BY m.month, rank_in_month;

-- ===== 7.1 Наявні індекси =====
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ===== 7.2 EXPLAIN ANALYZE: корельовані підзапити у SELECT (запит 4.4) =====
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_name, p.unit_price,
       (SELECT COALESCE(SUM(oi.quantity), 0)
          FROM order_items oi WHERE oi.product_id = p.product_id) AS total_sold,
       (SELECT COUNT(DISTINCT oi.order_id)
          FROM order_items oi WHERE oi.product_id = p.product_id) AS orders_count
FROM products p
ORDER BY total_sold DESC;

-- ===== 7.3 EXPLAIN ANALYZE: той самий запит, переписаний через LEFT JOIN + GROUP BY =====
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_name, p.unit_price,
       COALESCE(SUM(oi.quantity), 0) AS total_sold,
       COUNT(DISTINCT oi.order_id) AS orders_count
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.unit_price
ORDER BY total_sold DESC;

-- ===== 7.4 Складені / покриваючі індекси та план з ними =====
CREATE INDEX IF NOT EXISTS idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX IF NOT EXISTS idx_order_items_product_cover ON order_items(product_id) INCLUDE (quantity, order_id);
ANALYZE orders;
ANALYZE order_items;

-- на 25-47 рядках планувальник обирає Seq Scan, тому для демонстрації вимикаємо його
SET enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_date
FROM orders
WHERE customer_id = 1
ORDER BY order_date;