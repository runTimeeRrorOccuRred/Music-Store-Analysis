-- CREATE DATABASE
CREATE DATABASE MSTORE ;

-- ACCESS THE DATABASE
USE MSTORE ;

-- IMPORT CSV USING THE TABLE IMPORT WIZARD

/* Q1 . Who is the senior most employee based on job title? */
SELECT TOP 1 employee_id, first_name, last_name, title, levels
FROM employee 
ORDER BY levels DESC;

/* Q2. Which countries have the most Invoices? */
SELECT TOP 1 billing_country, count(*) total_invoices
FROM invoice 
GROUP BY billing_country
ORDER BY 2 DESC;

/* Q3. What are top 3 values of total invoice? */
SELECT TOP 3 * FROM invoice 
ORDER BY total desc;

/* Q4. Which city has the best customers? We would like to throw a promotional Music
Festival in the city we made the most money. Write a query that returns one city that
has the highest sum of invoice totals. Return both the city name & sum of all invoice
totals */
SELECT TOP 1 billing_city, sum(total) total_invoice_amount 
FROM invoice
GROUP BY billing_city
ORDER BY 2 DESC ;

/* Q5. Who is the best customer? The customer who has spent the most money will be
declared the best customer. Write a query that returns the person who has spent the
most money */
SELECT TOP 1 I.customer_id, first_name, last_name, ROUND(sum(total),2) total_invoice_amount
FROM customer C 
INNER JOIN invoice I 
ON C.customer_id = I.customer_id 
GROUP by I.customer_id, first_name, last_name 
ORDER BY 4 DESC;

/* MODERATE */
/* Q1. Write query to return the email, first name, last name, & Genre of all Rock Music
listeners. Return your list ordered alphabetically by email starting with A */

SELECT DISTINCT C.email, C.first_name, C.last_name, G.name 
FROM customer C
INNER JOIN invoice I ON C.customer_id = I.customer_id
INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
INNER JOIN track T ON IL.track_id = T.track_id
INNER JOIN genre G ON T.genre_id = G.genre_id 
WHERE G.name LIKE 'Rock'
ORDER BY 1 ;

/* Q2, Let's invite the artists who have written the most rock music in our dataset. Write a
query that returns the Artist name and total track count of the top 10 rock bands */

SELECT TOP 10 AT.artist_id, AT.name, COUNT(*) number_of_songs
FROM GENRE G 
INNER JOIN TRACK T ON G.genre_id = T.genre_id 
INNER JOIN ALBUM A ON T.album_id = A.album_id
INNER JOIN ARTIST AT ON A.artist_id = AT.artist_id 
WHERE G.name LIKE 'Rock'
GROUP BY AT.artist_id, AT.name
ORDER BY 3 DESC;

/* Q3. Return all the track names that have a song length longer than the average song length.
Return the Name and minutes for each track. Order by the song length with the
longest songs listed first*/

SELECT name, milliseconds/60000 minutes 
FROM track 
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY 2 DESC ;

-- ## ADVANCE ## --
/* Q1. Find how much amount spent by each customer on artists? Write a query to return
customer name, artist name and total spent */

-- Use CTE if you want to each customer spent on top n artist
WITH best_selling_artist as (
    select top 3 Ar.artist_id, AR.name, sum(I.unit_price*quantity) as total_sales
    from invoice_line I
    inner join track T on T.track_id = I.track_id
    inner join album A on A.album_id = T.album_id
    inner join artist AR on AR.artist_id = A.artist_id
    GROUP BY AR.artist_id, AR.name
    ORDER BY 3 DESC)
select C.customer_id, C.first_name, C.last_name, BSA.name, SUM(IL.unit_price*IL.quantity) AS total_spent
FROM customer C 
INNER JOIN invoice I ON C.customer_id = I.customer_id
INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
INNER JOIN track T ON T.track_id = IL.track_id
INNER JOIN album A ON A.album_id = T.album_id
INNER JOIN artist AR ON A.artist_id = AR.artist_id
INNER JOIN best_selling_artist BSA ON  BSA.artist_id = AR.artist_id
GROUP BY C.customer_id, first_name, last_name, BSA.NAME 
ORDER BY 5 DESC;

-- Use joins for per customer spent on each artists
select C.customer_id, C.first_name, C.last_name, AR.name, SUM(IL.unit_price*IL.quantity) AS total_spent
FROM customer C 
INNER JOIN invoice I ON C.customer_id = I.customer_id
INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
INNER JOIN track T ON T.track_id = IL.track_id
INNER JOIN album A ON A.album_id = T.album_id
INNER JOIN artist AR ON A.artist_id = AR.artist_id
GROUP BY C.customer_id, first_name, last_name, AR.NAME 
ORDER BY 5 DESC;

/* Q2. We want to find out the most popular music Genre for each country. We determine the
most popular genre as the genre with the highest amount of purchases. Write a query
that returns each country along with the top Genre. For countries where the maximum
number of purchases is shared return all Genres */
WITH popular_genre as (
    SELECT COUNT(IL.quantity) quantity, C.country, G.name, G.genre_id,
    ROW_NUMBER() OVER(PARTITION BY C.country ORDER BY COUNT(IL.quantity) DESC) AS RN
    FROM customer C 
    INNER JOIN invoice I ON C.customer_id = I.customer_id
    INNER JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
    INNER JOIN TRACK T ON T.track_id = IL.track_id
    INNER JOIN genre G ON G.genre_id = T.genre_id
    GROUP BY C.country, G.name, G.genre_id)
SELECT * FROM popular_genre WHERE RN <= 1
ORDER BY 1 DESC ;

/* Q3. Write a query that determines the customer that has spent the most on music for each
country. Write a query that returns the country along with the top customer and how
much they spent. For countries where the top amount spent is shared, provide all
customers who spent this amount */

WITH top_customer_spent as (
    SELECT C.customer_id, first_name, last_name, billing_country, SUM(total) AS 'total_spent',
    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RN
    FROM customer C 
    INNER JOIN invoice I 
    ON C.customer_id = I.customer_id
    GROUP by C.customer_id, first_name, last_name, billing_country)
SELECT * FROM top_customer_spent
WHERE RN <= 1
ORDER BY 5 DESC ;