use BookDatabase;


-- Bestselling or Bestrated Titles/Authors/Themes/Qualities 
drop procedure if exists bestsellers_or_bestrated;
delimiter $$
create procedure bestsellers_or_bestrated(attribute_name varchar(30), page_num int(1), ratings_indicator bit(1))
-- variables: attribute you want to examine, page_number (0: top 10, 1: top 10-20, 2: top 20-30, etc.),
-- order by ratings if 1 and orders if 0
begin
	declare command1 varchar(150); -- this holds the select command string
    declare info_table varchar(20);
    declare attribute_table varchar(20);
    if attribute_name = 'title' then
	if ratings_indicator=1 then 
	set command1 = 
	'select isbn from ratings
	group by isbn
	having count(rating) > 4
	order by avg(rating) desc';
    -- if 1, then get the ratings figures; otherwise, get the sales figures
	else set command1 = 
	'select isbn from orders
	group by isbn
	order by sum(quantity) desc';
	end if;
	set @sql := 
    concat('select title from (',
    command1,' 
	limit ',page_num*10,',10) as t1
	inner join titles as t2
	on t1.isbn = t2.isbn;');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement;
    
    else if ratings_indicator=1 then 
    set command1 = 
    'having count(rating) > 8
	order by avg(rating) desc';
    set info_table = 'ratings';
    else set command1 = 
    'order by sum(quantity) desc';
    set info_table = 'orders';
    end if;
    if attribute_name = 'quality' then set attribute_table = 'qualities';
    else set attribute_table = concat(attribute_name,'s');
    end if;
	set @sql := 
    concat('select ',attribute_name,' from
	',attribute_table,' as t1
	inner join
	',info_table,' as t2 
	on t1.isbn=t2.isbn
	group by ',attribute_name,' ',
    command1,'
    limit ',page_num*10,',10;');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement;
    end if;
end $$
delimiter ;

-- try it out
call bestsellers_or_bestrated('title',0,0);  -- bestsellers
call bestsellers_or_bestrated('theme',0,1);  -- top 10 ranked themes

-- Bestselling or Best-Rated Titles by Author/Theme/Quality 
drop procedure if exists best_titles_by_category;
delimiter $$
create procedure best_titles_by_category(attribute_name varchar(30), attribute_value varchar(50), 
page_num int(1), ratings_indicator bit(1))
begin
	declare attribute_table varchar(30);
	if attribute_name = 'quality' then set attribute_table = 'qualities';
    else set attribute_table = concat(attribute_name,'s');
    end if;
    
	if ratings_indicator=1 then
	set @sql := 
    concat('select title, avg(rating) as avg_rating from
	(select title, t1.isbn from
	titles as t1 inner join ',attribute_table,' as t2
	on t1.isbn = t2.isbn where ',attribute_name,' = "',attribute_value,'") as tt1
	inner join
	ratings as tt2
    on tt1.isbn=tt2.isbn
	group by tt1.isbn
	having count(rating) > 3
	order by avg_rating desc
	limit ',page_num*10,',10;');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement;
    
    else
	set @sql := 
    concat('select title from
	(select title, t1.isbn from
	titles as t1 inner join ',attribute_table,' as t2
	on t1.isbn = t2.isbn where ',attribute_name,' = "',attribute_value,'") as tt1
	inner join
	orders as tt2
    on tt1.isbn=tt2.isbn
	group by tt1.isbn
	order by sum(quantity) desc
	limit ',page_num*10,',10;');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement;
    end if;
end $$
delimiter ;

-- try it out
call best_titles_by_category('theme','dystopia',0,1);

-- What you recently viewed
drop procedure if exists recently_viewed;
delimiter $$
create procedure recently_viewed(customer_id bigint(10))
begin
select title from (select isbn from viewings 
where customer_id=customer_id and view_time>2
order by viewing_date desc limit 5) as t1 inner join
titles as t2 on t1.isbn=t2.isbn;
end $$
delimiter ;

-- try it out
call recently_viewed(2);

-- Bestsellers in your favorite category
drop procedure if exists other_bestsellers_in_your_fav_category;
delimiter $$
create procedure other_bestsellers_in_your_fav_category(custmr_id bigint(10))
begin 
	declare att_val varchar(50);
    declare att_nam varchar(50);
    declare att_tbl varchar(50);
    select attribute_value, attribute_name, attribute_tbl 
		into att_val, att_nam, att_tbl from
		(select * from (select t2.theme as attribute_value, sum(t1.sales) as sales, 
		"theme" as attribute_name, "themes" as attribute_tbl from
		((select isbn, sum(quantity) as sales
		from orders
		where customer_id = custmr_id
		group by isbn) as t1
		inner join themes
		as t2 on t1.isbn=t2.isbn)
		group by theme
		order by sales desc
		limit 1) as t
		union
		(select t2.quality, sum(t1.sales) as sales, 
		"quality" as attribute_name, "qualities" as attribute_tbl from
		((select isbn, sum(quantity) as sales
		from orders
		where customer_id = custmr_id
		group by isbn) as t1
		inner join qualities
		as t2 on t1.isbn=t2.isbn)
		group by quality
		order by sales desc
		limit 1)
		union
		(select t2.author, sum(t1.sales) as sales, 
		"author" as attribute_name, "authors" as attribute_tbl from
		((select isbn, sum(quantity) as sales
		from orders
		where customer_id = custmr_id
		group by isbn) as t1
		inner join authors
		as t2 on t1.isbn=t2.isbn)
		group by author
		order by sales desc
		limit 1)
		order by sales desc
		limit 1) as t;
    	
	set @sql := 
    concat('select title as other_', att_val,'_bestsellers from
	(select isbn, title from titles 
	where isbn in (select isbn from ', att_tbl,' 
	where ', att_nam,' = "', att_val,'")
	and isbn not in (select distinct(isbn) from orders 
	where customer_id = ',custmr_id,')) as t1
	inner join (select isbn, quantity from orders) 
	as t2 on t1.isbn=t2.isbn
	group by t1.isbn
	order by sum(quantity) desc
	limit 10;');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement;  
end $$
delimiter ;

call other_bestsellers_in_your_fav_category(54);

select quality, sum(quantity) as num_purchases from 
(select isbn, quantity from orders where customer_id = 54) as t1
inner join qualities as t2 on t1.isbn=t2.isbn
group by quality
order by num_purchases desc
limit 5;

-- Recommended By Content
drop procedure if exists recommended_for_you_by_content;
delimiter $$
create procedure recommended_for_you_by_content(custmr_id bigint(10))
begin        
	select title, num_matches from
	(select isbn, count(isbn) as num_matches from
	(select isbn from
	(select isbn from themes 
		where theme in (
			select theme from 
			(select t2.theme from
				((select isbn, sum(quantity) as sales
				from orders
				where customer_id = custmr_id
				group by isbn) as t1
				inner join themes
				as t2 on t1.isbn=t2.isbn)
				group by theme
				order by sales desc
				limit 10) as theme_tbl)
		union all 
		select isbn from qualities 
		where quality in ( 
			select quality from 
			(select t2.quality from
				((select isbn, sum(quantity) as sales
				from orders
				where customer_id = custmr_id
				group by isbn) as t1
				inner join qualities
				as t2 on t1.isbn=t2.isbn)
				group by quality
				order by sales desc
				limit 10) as quality_tbl)
		union all 
		select isbn from authors 
		where author in ( 
			select author from 
			(select t2.author from
				((select isbn, sum(quantity) as sales
				from orders
				where customer_id = custmr_id
				group by isbn) as t1
				inner join authors
				as t2 on t1.isbn=t2.isbn)
				group by author
				order by sales desc
				limit 10) as author_tbl)
		union all 
		select isbn from viewings 
		where customer_id= custmr_id) as t
		where isbn not in 
		(select distinct(isbn) from orders
		where customer_id= custmr_id)) as tt
		group by isbn
		order by num_matches desc limit 10) as tab1
		inner join titles as tab2
		on tab1.isbn=tab2.isbn;
end $$
delimiter ;

call recommended_for_you_by_content(9);

select title, num_purchases from (
select isbn, sum(quantity) as num_purchases from orders 
where customer_id = 9 group by isbn
order by num_purchases desc limit 10) as t1
inner join titles as t2
on t1.isbn=t2.isbn;

-- Now procedure for calculating similarity between books
-- purchase similarity function
-- for any given two books, calculate the (bought) similarity between them
drop function if exists purchase_similarity;
delimiter $$
create function 
purchase_similarity(book1 bigint(13), book2 bigint(13))
returns float deterministic
begin
    declare common int;
    declare num_ip int;
    declare num_iq int;
    declare k float;
    declare sim float;
    set num_ip = (select count(customer_id) from 
    (select distinct(customer_id) from orders where isbn=book1) as t);
    set num_iq = (select count(customer_id) from 
    (select distinct(customer_id) from orders where isbn=book2) as t);
    set common = (select count(t1.customer_id) from (select distinct(customer_id) from orders where isbn=book1) as t1
    inner join (select distinct(customer_id) from orders where isbn=book2) as t2
    on t1.customer_id = t2.customer_id);
    if num_ip<15 or num_iq<15 then set k = least(num_ip , num_iq)/15;
    else set k = 1;
    end if;
    set sim = k*(common/(num_ip*num_iq));
    return ifnull(sim,0);
end $$
delimiter ;

-- Test function
select purchase_similarity(9780006473299,9780007289486);

-- rating similarity function
-- for any given two books, calculate the (bought) similarity between them
drop function if exists rating_similarity;
delimiter $$
create function 
rating_similarity(book1 bigint(13), book2 bigint(13))
returns float deterministic
begin
	declare avg_r1 float;
    declare avg_r2 float;
    declare denom float;
    declare num_common int;
    declare corr float;
    
	select avg(r1), avg(r2), (std(r1)*std(r2)), count(r1)
    into avg_r1, avg_r2, denom, num_common
	from (select r1, r2 from 
	((select distinct(customer_id), rating as r1 
    from ratings where isbn = book1) as t1 
	inner join (select distinct(customer_id), rating as r2 
    from ratings where isbn = book2) as t2
	on t1.customer_id = t2.customer_id)) as t;
    
	select sum((r1-avg_r1)*(r2-avg_r2))/(num_common*denom) into corr 
    from (select r1, r2 from 
	((select distinct(customer_id), rating as r1 
    from ratings where isbn = book1) as t1 
	inner join (select distinct(customer_id), rating as r2 
    from ratings where isbn = book2) as t2
	on t1.customer_id = t2.customer_id)) as t;
    
    return ifnull(corr,0);
end $$
delimiter ;

-- Testing function
select rating_similarity(9788893456142,9781328829023);

-- can't refer to the same temporary table twice in the same query
-- so I am forced to create a view

-- example to show how to select all pairs
select * from titles limit 3;
with top3 as (select * from titles limit 3)
select t1.isbn as isbn1, t2.isbn as isbn2
from top3 as t1 join top3 t2
on t1.title < t2.title;

-- obviously in reality you would create a copy a make a new one
drop table if exists similarities;
create table similarities(
isbn1 bigint(13), 
isbn2 bigint(13), 
purchase_similarity float,
rating_similarity float,
primary key (isbn1, isbn2)
);

insert into similarities
with bought_books as
	(select isbn, title from titles
    where isbn in (select isbn from orders 
	group by isbn
	having count(distinct(customer_id))>10))
    -- select isbn, title for books that have been bought by at least 10 customers
select isbn1, isbn2, purchase_sim, rating_sim from
(select isbn1, isbn2, 
purchase_similarity(isbn1, isbn2) as purchase_sim,
rating_similarity(isbn1, isbn2) as rating_sim
from (select t1.isbn as isbn1, t2.isbn as isbn2
from bought_books as t1 join bought_books t2
on t1.title < t2.title) as t) as tt
-- only select half the pairs
where purchase_sim > 0.01
order by purchase_sim desc;

insert into similarities (isbn1, isbn2, purchase_similarity, rating_similarity) 
select isbn2, isbn1, purchase_similarity, rating_similarity from similarities;
-- duplicate pairs so that we only have to search one column

drop procedure if exists recommender;
delimiter $$
create procedure recommender(customer_identifier bigint(10), viewed_indicator bit(1))
begin
	if viewed_indicator=1 then
    select tab2.title as recommended_title, from_title from
	(select isbn1, isbn2, t2.title as from_title from
		(select isbn1, isbn2 from similarities
		where isbn1 in (select distinct(isbn) from viewings where customer_id=customer_identifier
                and view_time>2 and viewing_date > '2018-01-01')
		and isbn2 not in (select distinct(isbn) from viewings where customer_id=customer_identifier)
		order by purchase_similarity desc
		limit 10) as t1
		inner join titles as t2 
		on t1.isbn1=t2.isbn) as tab1
		inner join titles as tab2 on tab1.isbn2 = tab2.isbn;
	else 
    select tab2.title as recommended_title, from_title from
	(select isbn1, isbn2, t2.title as from_title from
		(select isbn1, isbn2 from similarities
		where isbn1 in (select distinct(isbn) from orders where customer_id=customer_identifier)
        -- if they bought this book
		and isbn2 not in (select distinct(isbn) from orders where customer_id=customer_identifier)
        -- if they didn't buy this book
		order by purchase_similarity desc
		limit 10) as t1
		inner join titles as t2 
		on t1.isbn1=t2.isbn) as tab1
		inner join titles as tab2 on tab1.isbn2 = tab2.isbn;
	end if;
end $$
delimiter ;

-- Recommended by your purchases
call recommender(89,0);

-- Similar to what you recently viewed
call recommender(89,1);

-- Find a Customer's Favourite Type of Books
drop procedure if exists customer_favorites;
delimiter $$
create procedure customer_favorites(custmr_id bigint(10), attribute_name varchar(30), limit_num int(2), ratings_indicator bit(1))
begin  
	declare attribute_table varchar(30);
    declare order_by_attribute varchar(50);
	if attribute_name = "quality" then set attribute_table = "qualities";
    else set attribute_table = concat(attribute_name, "s");
    end if;
    
	if attribute_name="title" then
    if ratings_indicator = 1 then
    select title, rating, rating_date from 
	(select isbn, rating, rating_date from ratings where customer_id = custmr_id) as t1
	inner join titles as t2 on t1.isbn=t2.isbn
	order by rating desc
	limit limit_num;
    
    else
 	select t2.title, most_recent_purchase_date, sum(t1.sales) as num_purchases from
	((select isbn, sum(quantity) as sales, max(purchase_date) as most_recent_purchase_date
	from orders
    where customer_id = custmr_id
	group by isbn) as t1
	inner join titles
	as t2 on t1.isbn=t2.isbn)
	group by t1.isbn
	order by most_recent_purchase_date desc
	limit limit_num;
    end if;
    
    else
    if ratings_indicator = 1 then set order_by_attribute = "avg_rating";
    else set order_by_attribute = "num_purchases";
    end if;
    
	set @sql := 
    concat('select tt1.',attribute_name,', num_purchases, most_recent_purchase_date, 
    ifnull(num_ratings, 0) as num_ratings,
	avg_rating from
	(select ',attribute_name,', sum(quantity) as num_purchases,
	max(purchase_date) as most_recent_purchase_date,
	sum(case when purchase_date > "2018-01-01" then quantity else 0 end) as num_recent_purchases
	from (select isbn, purchase_date, quantity, cost from orders where customer_id = ',custmr_id,') as t1
	inner join ',attribute_table,' as t2
	on t1.isbn=t2.isbn
	group by ',attribute_name,') as tt1
	left join
	(select ',attribute_name,', avg(rating) as avg_rating, count(t1.isbn) as num_ratings
	from (select isbn, rating, rating_date from ratings where customer_id=',custmr_id,') as t1 inner join ',attribute_table,' as t2 on t1.isbn=t2.isbn
	group by ',attribute_name,') as tt2
	on tt1.',attribute_name,' = tt2.',attribute_name,'
	order by ',order_by_attribute,' desc
	limit ',limit_num,';');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement;  
    end if;
end $$
delimiter ;

call customer_favorites(54,'title',10,1);
call customer_favorites(54,'theme',5,0);

-- Find a Customer's Favourite Type of Books
drop procedure if exists city_favorites;
delimiter $$
create procedure city_favorites(city_id int(3), attribute_name varchar(30), 
limit_num int(2), ratings_indicator bit(1))
begin  
	declare attribute_table varchar(30);
    declare order_by_attribute varchar(50);
    declare extra_condition varchar(50);
	if attribute_name = "quality" then set attribute_table = "qualities";
    else set attribute_table = concat(attribute_name, "s");
    end if;
    
    if ratings_indicator = 1 then set order_by_attribute = "avg_rating";
    set extra_condition = "
    where num_ratings > 3";
    
    else set order_by_attribute = "num_purchases";
    set extra_condition = "";
    end if;
    
	if attribute_name="title" then
 	set @sql := 
    concat('select * from
    (select title, sum(quantity) as num_purchases, 
	sum(case when purchase_date > "2018-01-01" then quantity else 0 end) as num_recent_purchases,
	sum(cost) as total_spent,
	count(rating) as num_ratings,
	avg(rating) as avg_rating 
	 from
	(select t1.isbn, title, quantity, cost, purchase_date from
	(select isbn, quantity, cost, purchase_date from orders 
	inner join customers on orders.customer_id = customers.customer_id
	where city_id=',city_id,') as t1
	inner join titles as t2
	on t1.isbn=t2.isbn) as tt1
	left join
	(select isbn, rating from ratings
	inner join customers on ratings.customer_id = customers.customer_id
	where city_id=',city_id,') as tt2
	on tt1.isbn = tt2.isbn
	group by tt1.isbn
	order by ',order_by_attribute,' desc) as t ',
    extra_condition,'
	limit ',limit_num,';');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement; 
    
    else
	set @sql := 
    concat('select * from
    (select tt1.',attribute_name,', num_purchases, num_recent_purchases,
    ifnull(num_ratings, 0) as num_ratings,
	avg_rating from
	(select ',attribute_name,', sum(quantity) as num_purchases,
	sum(case when purchase_date > "2018-01-01" then quantity else 0 end) as num_recent_purchases,
	sum(cost) as total_spent
	from (select isbn, quantity, cost, purchase_date from orders 
	inner join customers on orders.customer_id = customers.customer_id
	where city_id = ',city_id,') as t1
	inner join ',attribute_table,' as t2
	on t1.isbn=t2.isbn
	group by ',attribute_name,') as tt1
	left join
	(select ',attribute_name,', avg(rating) as avg_rating, count(t1.isbn) as num_ratings
	from (select isbn, rating from ratings 
	inner join customers on ratings.customer_id = customers.customer_id
	where city_id=',city_id,') as t1 
	inner join ',attribute_table,' as t2 on t1.isbn=t2.isbn
	group by ',attribute_name,') as tt2
	on tt1.',attribute_name,' = tt2.',attribute_name,'
	order by ',order_by_attribute,' desc) as t ',
    extra_condition,'
	limit ',limit_num,';');
    prepare statement from @sql;
    execute statement;
    deallocate prepare statement;  
    end if;
end $$
delimiter ;

call city_favorites(5,'title',5,0);
call city_favorites(5,'author',3,1);




