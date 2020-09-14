-- add customer to customers table
insert into customers (first_name, surname, dob, sex, date_joined, email, password, city_id)
values ("Luke", "Killoran", "1995-01-01", 1, "2019-04-21", "lk@gmail.com", "password", 5);
select * from customers order by customer_id desc limit 5;

-- delete them
delete from customers where customer_id>200;

-- doesn't allow deletes without key column
-- delete from customers where first_name = "Luke" and surname = "Killoran";

-- doesn't catch some data formatting mistakes
insert into customers (first_name, surname, dob, sex, date_joined, email, password, city_id)
values ("Luke", 3.5, "1995-01-01", 1, "2019-04-21", "lk@gmail.com", "password", 5);
-- but does others (when data is too long)
insert into customers (first_name, surname, dob, sex, date_joined, email, password, city_id)
values ("Luke", "Killoran", "1995-01-01", "male", "2019-04-21", "lk@gmail.com", "password", 5);
delete from customers where customer_id>200;

-- adding duplicate information
insert into customers (customer_id, first_name, surname, dob, sex, date_joined, email, password, city_id)
values (200, "Luke", "Killoran", "1995-01-01", 1, "2019-04-21", "lk@gmail.com", "password", 5);
delete from customers where customer_id>200;

-- adding customer with missing unimportant values
insert into customers (first_name, surname, date_joined, email, password)
values ("Luke", "Killoran", "2019-04-21", "lk@gmail.com", "password");
select * from customers order by customer_id desc limit 5;
delete from customers where customer_id>200;

-- updating a customer
insert into customers (customer_id, first_name, surname, dob, sex, date_joined, email, password, city_id)
values (201, "Puke", "Killoran", "1995-01-01", 1, "2019-04-21", "lk@gmail.com", "password", 5);
select * from customers order by customer_id desc limit 5;
update customers set first_name = "Luke" where customer_id = 201;
select * from customers order by customer_id desc limit 5;

-- find the older residents of Luke's city
select * from customers where dob < '1995-01-01' and city_id=5 order by customer_id desc;

-- new city fails
delete from customers where customer_id>200;
insert into customers (customer_id, first_name, surname, dob, sex, date_joined, email, password, city_id)
values (201, "Luke", "Killoran", "1995-01-01", 1, "2019-04-21", "lk@gmail.com", "password", 51);

-- new city success
insert into cities values (51, "Dublin", "Ireland");
insert into customers (customer_id, first_name, surname, dob, sex, date_joined, email, password, city_id)
values (201, "Luke", "Killoran", "1995-01-01", 1, "2019-04-21", "lk@gmail.com", "password", 51);
select * from cities order by city_id desc limit 5;
select * from customers order by customer_id desc limit 5;

-- add order
insert into orders (order_id, isbn, customer_id, quantity, purchase_date, cost) 
values (2920, 9781514683682, 201, 1, '2019-04-21', 1*(select price from prices where isbn=9781514683682));
select * from orders order by order_id desc limit 5;

-- add rating
insert into ratings (isbn, customer_id, rating_date, rating) 
values (9781514683682, 201, '2019-04-21', 3.5);
select * from ratings order by rating_date desc limit 5;

-- add viewing
insert into viewings (isbn, customer_id, viewing_date, view_time) 
values (9780385537674, 201, '2019-04-21', 200);
select * from viewings order by viewing_date desc limit 3;

-- cannot delete the customer now due to restrict in foreign key constraint
delete from customers where customer_id=201;

-- update the customer works due to cascade
update customers set customer_id = 300 where customer_id = 201;
select * from orders order by order_id desc limit 3;
select * from ratings order by rating_date desc limit 3;
select * from viewings order by viewing_date desc limit 3;
