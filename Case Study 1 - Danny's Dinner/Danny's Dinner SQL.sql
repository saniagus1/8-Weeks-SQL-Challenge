/* --------------------
   Case Study Questions
   --------------------*/
--Author: Gede Agus Andika Sani
--Date: 15/11/2022
--Tool used: MS SQL Server

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS TotalPrice
FROM [SQL Tutorial]..sales sl
INNER JOIN [SQL Tutorial]..menu mn
	ON mn.product_id = sl.product_id 
GROUP BY customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS visitCount
FROM [SQL Tutorial]..sales
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?
WITH cteProdRank AS (
	SELECT customer_id, order_date, product_name,
		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS product_rank
	FROM sales sl
	INNER JOIN menu mn
		ON mn.product_id = sl.product_id
)
SELECT customer_id, product_name
FROM cteProdRank
WHERE product_rank = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 product_name, COUNT(*) purchased_count
FROM sales sl
INNER JOIN menu mn
	ON mn.product_id=sl.product_id
GROUP BY product_name
ORDER BY purchased_count DESC

-- 5. Which item was the most popular for each customer?
WITH favCustProd AS (
	SELECT customer_id, 
		product_name,
		COUNT(*) AS prodCount,
		DENSE_RANK() OVER (PARTITION BY customer_id 
		ORDER BY COUNT(product_name)DESC) AS rank
	FROM sales sl
	INNER JOIN menu mn
		ON mn.product_id=sl.product_id
	GROUP BY customer_id, product_name
)
SELECT customer_id, product_name
FROM favCustProd
WHERE rank=1

-- 6. Which item was purchased first by the customer after they became a member?
WITH datecte AS(
	SELECT sl.customer_id, 
			product_name, 
			DATEDIFF(DAY, join_date,order_date) AS deltadate,
			ROW_NUMBER() OVER (PARTITION BY sl.customer_id 
			ORDER BY DATEDIFF(DAY, join_date,order_date) ASC) AS rank
	FROM sales sl
	INNER JOIN menu mn
		ON mn.product_id = sl.product_id
	INNER JOIN members mm
		ON mm.customer_id = sl.customer_id
	WHERE DATEDIFF(DAY, join_date,order_date)>0
)
SELECT customer_id, product_name
FROM datecte
WHERE rank=1

-- 7. Which item was purchased just before the customer became a member?
WITH datecte AS(
	SELECT sl.customer_id, 
			product_name,
			join_date,
			order_date,
			DENSE_RANK() OVER (PARTITION BY sl.customer_id ORDER BY order_date DESC) AS rank
	FROM sales sl
	INNER JOIN menu mn
		ON mn.product_id = sl.product_id
	INNER JOIN members mm
		ON mm.customer_id = sl.customer_id
	WHERE join_date>order_date
)
SELECT customer_id, product_name
FROM datecte
WHERE rank = 1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT sl.customer_id,
		COUNT(sl.product_id)AS total_items,
		SUM(price) AS amount_spent
FROM sales sl
INNER JOIN menu mn
	ON mn.product_id = sl.product_id
LEFT JOIN members mm
	ON mm.customer_id = sl.customer_id
WHERE order_date<join_date
GROUP BY sl.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, 
	SUM(CASE
		WHEN product_name = 'sushi' THEN price*10*2
		ELSE price*10
	END) AS total_point
FROM sales sl
INNER JOIN menu mn
	ON mn.product_id = sl.product_id
GROUP BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?

SELECT sl.customer_id, 
	SUM(CASE
		WHEN DATEDIFF(DAY, join_date,order_date) BETWEEN 0 AND 6 THEN price*10*2
		WHEN product_name = 'sushi' THEN price*10*2
		ELSE price*10
	END) AS point 
FROM sales sl
INNER JOIN menu mn
	ON mn.product_id = sl.product_id
INNER JOIN members mm
	ON mm.customer_id = sl.customer_id
WHERE order_date<'2021/02/01'
GROUP BY sl.customer_id
