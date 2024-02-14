create table album
( album_id int8 ,
  title varchar(100),
  artist_id int8
) ;

create table artist (
artist_id int8 ,
name varchar(100)
	) ;
	
	
create table customer (
customer_id int8 , 
first_name varchar(50) ,
last_name varchar(50),
company varchar(50),
address varchar(70),
city varchar(50), 
state char(10),
country  char(20) ,
postal_code varchar(50) ,
phone varchar(50),
fax varchar(50),
email varchar(50),
support_rep_id numeric
) ;	

create table employee (
employee_id int8 , 
first_name varchar(50) ,
last_name varchar(50),
title varchar(50),
reports_to numeric,
levels varchar(10), 
birthdate timestamp, 
hire_date timestamp,
address varchar(50),
city char(20),
state char(10),
country char(20),
postal_code varchar(20),
phone varchar(50),
fax varchar(50),
email varchar(50)
	) ;
	
create table invoice (
invoice_id integer NOT NULL,
    customer_id integer,
    invoice_date timestamp without time zone,
    billing_address character varying(120),
    billing_city character varying(30),
    billing_state character varying(30),
    billing_country character varying(30),
    billing_postal_code character varying(30),
    total decimal
) ;

create table genre (
genre_id int8, 
name varchar(30)
);

create table invoice_line(
invoice_line_id int8,
invoice_id int8,
track_id int8,
unit_price decimal,
quantity int ) ;	

create table media_type(
media_type_id int8 ,
media_name varchar(50)
);

create table playlist (
	playlist_id int8,
	name varchar(50)
)
	
create table playlist_track(
	playlist_id int8,
	track_id int8
)

create table track(
track_id int8,
name varchar(100),
album_id  int8,	
media_type_id int8,
genre_id int8,	
composer varchar(100),
milliseconds int8,
bytes int8,
unit_price decimal
);


--query1
--Who is the senior most employee based on job title?

select first_name , last_name , levels from employee
order by levels desc 
limit 1 ;

--query2 
--Which countries have the most Invoices?

SELECT billing_country , count(billing_country) as total_invoice
from invoice 
group by billing_country 
order by total_invoice desc ;

--query3 
--What are top 3 values of total invoice?

select total from invoice
order by total desc 
limit 3 ;

--query4
--Which city has the best customers? We would like to throw a promotional Music Festival in the city
--we made the most money. Write a query that returns one city
--that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.

select billing_city , sum(total) as sum_invoice_totals 
from invoice 
group by billing_city 
order by sum_invoice_totals desc 
limit 1 ; 

--query5
--Who is the best customer? The customer who has spent the 
--most money will be declared the best customer. Write a query that returns the 
--person who has spent the most money

select c.first_name , c.last_name , sum(i.total) as total_money_spent 
from customer as c
join invoice as i
on c.customer_id=i.customer_id
group by first_name , last_name 
order by total_money_spent desc 
limit 1;

--query6
--Write query to return the email, first name, 
--last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by 
--email starting with A 

select c.first_name , c.last_name ,g.name ,  c.email 
from customer as c
join invoice i on i.customer_id=c.customer_id
join invoice_line on invoice_line.invoice_id=i.invoice_id
join track t on t.track_id=invoice_line.track_id
join genre g on g.genre_id=t.genre_id
where g.name = 'Rock'
group by first_name , last_name , g.name , email 
order by email asc ;

--query7
--Let's invite the artists
--who have written the most rock music in our dataset. Write a query that returns the 
--Artist name and total track count of the top 10 rock bands.

select a.artist_id , a.name ,  g.name , count(a.artist_id) as total_number_songs
from artist as a
join album on album.artist_id = a.artist_id
join track t on t.album_id = album.album_id
join genre g on g.genre_id=t.genre_id
where g.name ='Rock'
group by a.artist_id , a.name , g.name 
order by total_number_songs desc ;

--query8
--Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first

select name , milliseconds as song_length 
from track
where milliseconds > ( select avg(milliseconds) from track )
group by name , song_length 
order by song_length desc ;

--query9
--Find how much amount spent by each customer on the best selling artist ?
--Write a query to return customer name, artist name and total money spent

with best_selling_artist as (
    select artist.artist_id as artist_id , artist.name as artist_name , 
	                                     sum(il.unit_price * il.quantity) as total_sales
	from invoice_line as il
	join track on track.track_id=il.track_id
	join album on album.album_id=track.album_id
	join artist on artist.artist_id=album.artist_id
	group by 1 , 2
	order by 3 desc 
	limit 1 
)

select c.first_name , c.last_name , bsa.artist_name , sum(il.unit_price*il.quantity) as Amount
from customer as c
join invoice on invoice.customer_id=c.customer_id
join invoice_line as il on il.invoice_id=invoice.invoice_id
join track on track.track_id=il.track_id
join album on album.album_id=track.album_id
join best_selling_artist as bsa  on bsa.artist_id=album.artist_id
group by 1 ,2 ,3  
order by 4 desc ;

--query10
--We want to find out the most popular music Genre for each country. We determine the most popular genre
--as the genre with the highest number of purchases. Write a query that returns each 
--country along with the top Genre. For countries where the maximum number of purchases is shared 
--return all Genres

with popular_genre as (
select customer.country as country ,genre.name as name , count(il.quantity) as Quantity,
	dense_rank() over(partition by customer.country  order by count(il.quantity) desc) as row_number
from invoice_line as il
join invoice on invoice.invoice_id=il.invoice_id
join customer on customer.customer_id=invoice.customer_id	
join track on track.track_id=il.track_id
join genre on genre.genre_id=track.track_id
group by 1,2 
order by 1 asc, 3 desc 
)
select * from popular_genre 
where row_number <=1 ;


--query 11
--Write a query that determines the customer that has spent the most on music for each country.
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount.

with top_customer as (
    select invoice.billing_country as country , customer.first_name as first_name ,
	customer.last_name as lastname , sum(invoice.total) as total_sales ,
	dense_rank() over(partition by invoice.billing_country  order by sum(invoice.total)) 
	as rank
from invoice 
join customer on customer.customer_id=invoice.customer_id	      
group by 1 ,2,3
order by 1 asc , 4 desc 	
)

select * from top_customer 
where rank <=1 ;
	