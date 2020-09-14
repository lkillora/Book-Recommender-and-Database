use BookDatabase;

-- Views
drop view if exists book_metrics;
create view book_metrics as 
select title, ttt1.isbn, price, total_spent, num_sales, num_recent_sales,
    num_customers, num_ratings, avg_rating,
    ifnull(num_views,0) as num_views,
    ifnull(num_recent_views,0) as num_recent_views from
(select title, tt1.isbn, price, num_sales, num_recent_sales, total_spent,
    num_customers, ifnull(num_ratings,0) as num_ratings, avg_rating from
(select t1.title, t1.isbn, price, ifnull(num_sales,0) as num_sales,
	ifnull(num_recent_sales,0) as num_recent_sales, 
	ifnull(total_spent,0) as total_spent,
    ifnull(num_customers,0) as num_customers from
(select titles.isbn, titles.title, prices.price 
from (titles inner join prices on titles.isbn = prices.isbn)) as t1
-- for each isbn, get book title and price
left join
(select isbn, sum(quantity) as num_sales,
sum(case when purchase_date > '2018-01-01' then quantity else 0 end) 
as num_recent_sales, 
sum(cost) as total_spent,
count(distinct(customer_id)) as num_customers
from orders
group by isbn) as t2
-- for each isbn in orders table, get isbn, num_sales, num_recent_sales, and total_cost
on t1.isbn=t2.isbn) as tt1
left join
(select isbn, avg(rating) as avg_rating, 
count(customer_id) as num_ratings
from ratings
group by isbn) as tt2
-- for each isbn in ratings table, get avg_rating and num_ratings
on tt1.isbn=tt2.isbn) as ttt1
left join
(select isbn, count(customer_id) as num_views, 
sum(case when viewing_date > '2018-01-01' then 1 else 0 end) as num_recent_views
from viewings
group by isbn) as ttt2
-- for each isbn in viewings table, get number of views and number of recent views
on ttt1.isbn=ttt2.isbn
order by total_spent desc;

/*
-- Create user that cannot see orders or customers table
drop user if exists 'Restricted_User'@'localhost';
create user 'Restricted_User'@'localhost'
identified by 'password';
grant select on ProjectDatabase_13434418.book_metrics to 'Restricted_User'@'localhost';
show grants for 'Restricted_User'@'localhost';
*/

drop view if exists theme_metrics;
create view theme_metrics as
select ttt1.theme, total_spent, 
avg_price, num_sales/num_books as sales_per_book, 
num_books, num_sales, num_recent_sales,
    num_customers, num_ratings, avg_rating,
    ifnull(num_views,0) as num_views,
    ifnull(num_recent_views,0) as num_recent_views from 
(select tt1.theme, avg_price, num_books, num_sales, num_recent_sales, total_spent,
    num_customers, ifnull(num_ratings,0) as num_ratings, avg_rating from
(select t1.theme, avg_price, num_books,
	ifnull(num_sales,0) as num_sales,
	ifnull(num_recent_sales,0) as num_recent_sales, 
	ifnull(total_spent,0) as total_spent,
    ifnull(num_customers,0) as num_customers
    from 
(select theme, avg(price) as avg_price, count(themes.isbn) as num_books from 
themes inner join prices on themes.isbn=prices.isbn
group by theme) as t1
left join
(select theme, sum(quantity) as num_sales,
sum(case when purchase_date > '2018-01-01' then quantity else 0 end) 
as num_recent_sales, 
sum(cost) as total_spent,
count(distinct(customer_id)) as num_customers
from orders inner join themes on orders.isbn=themes.isbn
group by theme) as t2
on t1.theme=t2.theme) as tt1
left join
(select theme, count(customer_id) as num_ratings, 
avg(rating) as avg_rating
from ratings 
inner join themes on ratings.isbn=themes.isbn
group by theme) as tt2
on tt1.theme=tt2.theme) as ttt1
left join
(select theme, count(customer_id) as num_views, 
sum(case when viewing_date > '2018-01-01' then 1 else 0 end) as num_recent_views
from viewings 
inner join themes on viewings.isbn=themes.isbn
group by theme) as ttt2
on ttt1.theme = ttt2.theme
order by total_spent desc;

drop view if exists quality_metrics;
create view quality_metrics as
select ttt1.quality, total_spent, 
avg_price, num_sales/num_books as sales_per_book, 
num_books, num_sales, num_recent_sales,
    num_customers, num_ratings, avg_rating,
    ifnull(num_views,0) as num_views,
    ifnull(num_recent_views,0) as num_recent_views from 
(select tt1.quality, avg_price, num_books, num_sales, num_recent_sales, total_spent,
    num_customers, ifnull(num_ratings,0) as num_ratings, avg_rating from
(select t1.quality, avg_price, num_books,
	ifnull(num_sales,0) as num_sales,
	ifnull(num_recent_sales,0) as num_recent_sales, 
	ifnull(total_spent,0) as total_spent,
    ifnull(num_customers,0) as num_customers
    from 
(select quality, avg(price) as avg_price, count(qualities.isbn) as num_books from 
qualities inner join prices on qualities.isbn=prices.isbn
group by quality) as t1
left join
(select quality, sum(quantity) as num_sales,
sum(case when purchase_date > '2018-01-01' then quantity else 0 end) 
as num_recent_sales, 
sum(cost) as total_spent,
count(distinct(customer_id)) as num_customers
from orders inner join qualities on orders.isbn=qualities.isbn
group by quality) as t2
on t1.quality=t2.quality) as tt1
left join
(select quality, count(customer_id) as num_ratings, 
avg(rating) as avg_rating
from ratings 
inner join qualities on ratings.isbn=qualities.isbn
group by quality) as tt2
on tt1.quality=tt2.quality) as ttt1
left join
(select quality, count(customer_id) as num_views, 
sum(case when viewing_date > '2018-01-01' then 1 else 0 end) as num_recent_views
from viewings 
inner join qualities on viewings.isbn=qualities.isbn
group by quality) as ttt2
on ttt1.quality = ttt2.quality
order by total_spent desc;

drop view if exists author_metrics;
create view author_metrics as
select ttt1.author, total_spent, 
avg_price, num_sales/num_books as sales_per_book, 
num_books, num_sales, num_recent_sales,
    num_customers, num_ratings, avg_rating,
    ifnull(num_views,0) as num_views,
    ifnull(num_recent_views,0) as num_recent_views from 
(select tt1.author, avg_price, num_books, num_sales, num_recent_sales, total_spent,
    num_customers, ifnull(num_ratings,0) as num_ratings, avg_rating from
(select t1.author, avg_price, num_books,
	ifnull(num_sales,0) as num_sales,
	ifnull(num_recent_sales,0) as num_recent_sales, 
	ifnull(total_spent,0) as total_spent,
    ifnull(num_customers,0) as num_customers
    from 
(select author, avg(price) as avg_price, count(authors.isbn) as num_books from 
authors inner join prices on authors.isbn=prices.isbn
group by author) as t1
left join
(select author, sum(quantity) as num_sales,
sum(case when purchase_date > '2018-01-01' then quantity else 0 end) 
as num_recent_sales, 
sum(cost) as total_spent,
count(distinct(customer_id)) as num_customers
from orders inner join authors on orders.isbn=authors.isbn
group by author) as t2
on t1.author=t2.author) as tt1
left join
(select author, count(customer_id) as num_ratings, 
avg(rating) as avg_rating
from ratings 
inner join authors on ratings.isbn=authors.isbn
group by author) as tt2
on tt1.author=tt2.author) as ttt1
left join
(select author, count(customer_id) as num_views, 
sum(case when viewing_date > '2018-01-01' then 1 else 0 end) as num_recent_views
from viewings 
inner join authors on viewings.isbn=authors.isbn
group by author) as ttt2
on ttt1.author = ttt2.author
order by total_spent desc;

drop view if exists customer_metrics;
create view customer_metrics as 
select ttt1.customer_id, first_name, surname, dob, sex, date_joined, city_id,
num_purchases, num_recent_purchases, total_spent, num_ratings,
avg_rating, ifnull(num_views, 0) as num_views, ifnull(num_recent_views, 0) as num_recent_views,
(case when num_purchases=0 then '0'
when num_purchases between 1 and 10 then '1-10'
when num_purchases between 11 and 20 then '11-20'
when num_purchases between 21 and 30 then '21-30'
when num_purchases between 31 and 40 then '31-40'
when num_purchases>40 then 'Over 40' end) as purchases_band
from
(select tt1.customer_id, first_name, surname, dob, sex, date_joined, city_id,
num_purchases, num_recent_purchases, total_spent, ifnull(num_ratings, 0) as num_ratings,
avg_rating
from
(select t1.customer_id, first_name, surname, dob, sex, date_joined, city_id,
ifnull(num_purchases, 0) as num_purchases, 
ifnull(num_recent_purchases, 0) as num_recent_purchases, 
ifnull(total_spent, 0) as total_spent
from 
(customers as t1
left join
(select customers.customer_id,
sum(quantity) as num_purchases,
sum(case when purchase_date > '2018-01-01' then quantity else 0 end) as num_recent_purchases,
sum(cost) as total_spent
from (customers inner join orders 
on customers.customer_id = orders.customer_id)
group by customers.customer_id) as t2
on t1.customer_id=t2.customer_id)) as tt1
left join
(select customer_id, count(customer_id) as num_ratings,
avg(rating) as avg_rating
from ratings
group by customer_id) as tt2
on tt1.customer_id=tt2.customer_id) as ttt1
left join
(select customer_id, 
count(customer_id) as num_views,
sum(case when viewing_date > '2018-01-01' then 1 else 0 end) as num_recent_views
from viewings
group by customer_id) as ttt2
on ttt1.customer_id = ttt2.customer_id
order by total_spent desc;

-- using the customer_metrics view
-- grouping by purchases_band
select 
purchases_band,
sum(total_spent) as total_spent,
count(customer_id) as num_members,
sum(case when dob < '1979-01-01' then 1 else 0 end) as num_elderly,
sum(case when dob < '1999-01-01' and dob >= '1979-01-01' then 1 else 0 end) as num_adults,
sum(case when dob >= '1999-01-01' then 1 else 0 end) as num_teenagers,
sum(sex)/count(customer_id) as proportion_male,
sum(num_purchases) as num_purchases,
sum(num_recent_purchases) as num_recent_purchases,
sum(num_ratings) as num_ratings,
sum(num_ratings*avg_rating)/sum(num_ratings) as avg_rating,
sum(num_views) as num_views,
sum(num_recent_views) as num_recent_views
from customer_metrics
group by purchases_band
order by total_spent desc;

drop view if exists city_breakdown;
create view city_breakdown as
select city_name, ttt2.city_id, country, ifnull(total_spent,0) as total_spent, 
		ifnull(num_book_sales,0) as num_book_sales,
		ifnull(num_customers,0) as num_customers,
        avg_customer_value, 
        num_elderly, num_adults, num_teenagers, proportion_male from
		(select tt1.city_id, total_spent, num_book_sales, num_customers,
		avg_customer_value, num_elderly, num_adults, num_teenagers, proportion_male from 
			(select city_id,
			sum(cost) as total_spent, 
			sum(quantity) as num_book_sales, 
			count(distinct(customer_id)) as num_customers,
			sum(cost)/count(distinct(customer_id)) as avg_customer_value from 
				(select t1.isbn, t1.customer_id, t1.quantity, t1.cost, t2.city_id from 
					(select isbn, customer_id, quantity, cost from orders) as t1 
					inner join 
					(select customer_id, city_id from customers) as t2
                    -- get city_id
					on t1.customer_id = t2.customer_id) as t
                    -- remove redundant information
			group by city_id) as tt1
            -- group by city to get summary statistics
		join
			(select city_id,
			sum(case when dob < '1979-01-01' then 1 else 0 end) as num_elderly,
			sum(case when dob < '1999-01-01' and dob >= '1979-01-01' then 1 else 0 end) as num_adults,
			sum(case when dob >= '1999-01-01' then 1 else 0 end) as num_teenagers,
			sum(sex)/count(customer_id) as proportion_male 
			from customers
			group by city_id) as tt2
            -- join ciy statistics with customer statistics from customers table
		on tt1.city_id = tt2.city_id) as ttt1
        right join cities as ttt2  -- could change to right join to get all cities
        on ttt1.city_id=ttt2.city_id
        order by total_spent desc;

