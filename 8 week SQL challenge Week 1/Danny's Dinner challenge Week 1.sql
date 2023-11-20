create schema Dannys_dinner;
use Dannys_dinner;

CREATE TABLE sales(
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  -- Case Study Questions --
  
-- 1. What is the total amount each customer spent at the restaurant?

select Customer_id,
 concat('$',sum(price)) as total_spend
from menu as m
inner join sales as s  on m.product_id=s.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
 select customer_id,
 count(Distinct order_date) as customer_visit
 from sales
 group by customer_id;
 
 -- 3.what was the first iteam from the menu purchased by each customer?
 
WITH order_info_cte AS
  (SELECT customer_id,
          order_date,
          product_name,
          DENSE_RANK() OVER(PARTITION BY s.customer_id
                            ORDER BY s.order_date) asrank
   FROM sales AS s
   JOIN menu AS m ON s.product_id = m.product_id)
SELECT customer_id,
       product_name
FROM order_info_cte
WHERE asrank = 1
GROUP BY customer_id,
         product_name;
         
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name AS most_purchased_item,
       count(sales.product_id) AS order_count
FROM menu
INNER JOIN sales ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY order_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH cte_order_count AS (
  SELECT
    sales.customer_id,
    menu.product_name,
    COUNT(*) as order_count
  FROM sales
  JOIN menu
    ON sales.product_id = menu.product_id
  GROUP BY 
    customer_id,
    product_name
  ORDER BY
    customer_id,
    order_count DESC
),
cte_popular_rank AS (
  SELECT 
    *,
    RANK() OVER(PARTITION BY customer_id ORDER BY order_count DESC) AS Count
  FROM cte_order_count
)
SELECT * FROM cte_popular_rank
WHERE Count = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH joined_as_member AS (
  SELECT
    members.customer_id, 
    sales.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY members.customer_id
      ORDER BY sales.order_date) AS row_num
  FROM members
  INNER JOIN sales
    ON members.customer_id = sales.customer_id
    AND sales.order_date > members.join_date
)

SELECT 
  customer_id, 
  product_name 
FROM joined_as_member
INNER JOIN menu
  ON joined_as_member.product_id = menu.product_id
WHERE row_num = 1
ORDER BY customer_id ASC;
			
-- 7. Which item was purchased just before the customer became a member?
WITH purchased_prior_member AS (
  SELECT 
    members.customer_id, 
    sales.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY members.customer_id
      ORDER BY sales.order_date DESC) AS ranking
  FROM members
  INNER JOIN sales
    ON members.customer_id = sales.customer_id
    AND sales.order_date < members.join_date
)

SELECT 
  p_member.customer_id, 
  menu.product_name 
FROM purchased_prior_member AS p_member
INNER JOIN menu
  ON p_member.product_id = menu.product_id
WHERE ranking = 1
ORDER BY p_member.customer_id ASC;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
  sales.customer_id, 
  COUNT(sales.product_id) AS total_items, 
  SUM(menu.price) AS total_sales
FROM sales
INNER JOIN members
  ON sales.customer_id = members.customer_id
  AND sales.order_date < members.join_date
INNER JOIN menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
WITH points_cte AS (
  SELECT 
    menu.product_id, 
    CASE
      WHEN product_id = 1 THEN price * 20
      ELSE price * 10 END AS points
  FROM menu
)

SELECT 
  sales.customer_id, 
  SUM(points_cte.points) AS total_points
FROM sales
INNER JOIN points_cte
  ON sales.product_id = points_cte.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
SELECT s.customer_id,
SUM(CASE WHEN s.order_date > mm.join_date THEN price*20
WHEN s.order_date < mm.join_date AND m.product_name='sushi' THEN price*20
ELSE price*10
END) as Points
FROM menu as m
JOIN sales as s
ON m.product_id = s.product_id
JOIN members as mm
ON mm.customer_id = s.customer_id
GROUP BY s.customer_id
ORDER BY s.customer_id

--- The End ---
