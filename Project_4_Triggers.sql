use BookDatabase;

-- Triggers
-- Trigger to record any changes to orders table
drop table if exists orders_changes;
create table orders_changes(
change_id int auto_increment,
old_order_id bigint(10),
old_isbn bigint(13),
old_customer_id bigint(10),
old_quantity int(2),
old_cost float,
new_order_id bigint(10),
new_isbn bigint(13),
new_customer_id bigint(10),
new_quantity int(2),
new_cost float,
change_date datetime,
action varchar(60),
primary key (change_id)
);

drop trigger if exists before_orders_change;
delimiter $$
create trigger before_orders_change
before update on orders
for each row
begin
insert into orders_changes
set action = 'update',
old_order_id = old.order_id,
old_isbn = old.isbn,
old_customer_id = old.customer_id,
old_quantity = old.quantity,
old_cost = old.cost,
new_order_id = old.order_id,
new_isbn = new.isbn,
new_customer_id = new.customer_id,
new_quantity = new.quantity,
new_cost = new.cost,
change_date = NOW(); 
end $$
delimiter ;

-- Try it out
update orders set cost=30.14 where order_id=1; 
select * from orders_changes;

-- Trigger to record any changes to prices table
drop table if exists prices_changes;
create table prices_changes(
change_id int auto_increment,
old_price float(5,2),
old_isbn bigint(13),
new_price float(5,2),
new_isbn bigint(13),
change_date datetime,
action varchar(60),
primary key (change_id)
);

drop trigger if exists before_prices_changes;
delimiter $$
create trigger before_prices_changes
before update on prices
for each row
begin
insert into prices_changes
set action = 'update',
old_price = old.price,
old_isbn = old.isbn,
new_price = new.price,
new_isbn = new.isbn,
change_date = NOW(); 
end $$
delimiter ;

-- Try it out
update prices set price=30.14 where isbn=9780007422579; 
select * from prices_changes;

-- trigger to prevent bought items entering the viewings table
-- if viewed, check if bought. If bought, then do not add.
drop trigger if exists before_insert_viewings;
delimiter $$
create trigger before_insert_viewings
before insert on viewings
for each row 
begin
	if (exists(select isbn, customer_id from orders where customer_id=new.customer_id and isbn=new.isbn))
	then signal sqlstate '45000' set message_text = "Don't add a bought item to viewings_table";
	end if; 
end$$
delimiter ;

-- Try it out
insert into viewings values (9780300210798,77,'2018-07-08',578);
select * from orders where isbn = 9780300210798 and customer_id = 77;

-- trigger to prevent non-purchased items from being rated
-- if rated, check if bought. If not bought, then do not add.
drop trigger if exists before_insert_ratings;
delimiter $$
create trigger before_insert_ratings
before insert on ratings
for each row 
begin
	if not (exists(select isbn, customer_id from orders where customer_id=new.customer_id and isbn=new.isbn))
	then signal sqlstate '45000' set message_text = "Don't add rating if not bought";
	end if; 
end$$
delimiter ;

-- Try it out
insert into ratings values (9780300210798,78,'2018-07-08',4);
select * from orders where isbn = 9780300210798 and customer_id = 78;

-- trigger to delete now-bought items from viewings table
drop trigger if exists after_orders_insert;
delimiter $$
create trigger after_orders_insert
after insert on orders
for each row
begin
if exists(select isbn from viewings where isbn=new.isbn and customer_id=new.customer_id)
then delete from viewings where isbn=NEW.isbn and customer_id=new.customer_id;
end if;
end $$
delimiter ;

-- try it out
-- it exists
select * from viewings where isbn = 9780006473299 and customer_id = 167;
insert into orders values (2919,9780006473299,167,1,'2019-01-01',100.00);
-- now it has been deleted
select * from viewings where isbn = 9780006473299 and customer_id = 167;