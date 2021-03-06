analyze;

drop view if exists report;

--explain analyze 
create view report 
as with ac as (
	select account,account_valid_to,client,last_name,first_name,patrinymic,date_of_birth,passport,passport_valid_to,phone
		from project.dim_accounts a 
		join project.dim_clients c using(client)		
),
tt as (
	select trans_id,date,card,oper_type,amount,oper_result ,terminal,terminal_type,terminal_city,address
		from project.dim_transactions tr 
		join project.dim_terminals ter using(terminal)
),
acc as (
	select card, account, account_valid_to,client,last_name,first_name,patrinymic,date_of_birth,passport,passport_valid_to,phone
		from project.dim_cards cr 
		join ac using(account)
),
bigt as (
	select *
		from tt
		join acc using(card)
),                      --cte ?? ????? ???????
podbor as (         -- ??????????????? cte ??? ????????? ????????????? ??????? ?4
select 
	lag(date,3) over(partition by card  order by date) lag_date3,
	lag(oper_result,3) over(partition by card  order by date) lag_result3,
	lag(oper_result,2) over(partition by card  order by date) lag_result2,
	lag(oper_result,1) over(partition by card  order by date) lag_result1,
	lag(amount,3) over(partition by card  order by date) lag_amount3,
	lag(amount,2) over(partition by card  order by date) lag_amount2,
	lag(amount,1) over(partition by card  order by date) lag_amount1,
	amount,
	date, 
	passport, 
	last_name ||' '|| first_name||' ' || patrinymic as FIO,
	oper_result,
	phone 
from bigt order by card
),                                         
diff_city as (               -- ??????????????? cte ??? ????????? ????????????? ??????? ?4
select 
	lag(date) over(partition by card  order by date) lag_date,
	lag(terminal_city) over(partition by card  order by date) lag_city,
	terminal_city,
	date, 
	passport, 
	last_name ||' '|| first_name||' ' || patrinymic as FIO, 
	phone 
from bigt order by card
)
select                   -- ?????? ??? ????????? ????????????? ??????? ?4 
	date as FRAUD_DT, 
	passport, 
	FIO, 
	phone, 
	'type 4' as fraud_type,
	current_timestamp as report_dt
from podbor
where (date - lag_date3) < interval '20 minute' and oper_result = '	???????	' 
	and lag_result1 = '	?????	' and lag_result2 = '	?????	' and lag_result3 = '	?????	'
	and amount < lag_amount1 and lag_amount1 < lag_amount2 and lag_amount2 < lag_amount3
union
select                  -- ?????? ??? ????????? ????????????? ??????? ?3 
	date as FRAUD_DT, 
	passport, 
	FIO, 
	phone, 
	'type 3' as fraud_type,
	current_timestamp as report_dt
from diff_city
where (date - lag_date) < interval '1 hour' and lag_city <> terminal_city
	union
select                           -- ?????? ??? ????????? ????????????? ??????? ?1 
	date as FRAUD_DT, 
	passport, 
	last_name ||' '|| first_name||' ' || patrinymic as FIO, 
	phone, 
	'type 1' as fraud_type,
	current_timestamp as report_dt
from bigt
where passport_valid_to < date
	union 
select                            -- ?????? ??? ????????? ????????????? ??????? ?2 
	date as FRAUD_DT, 
	passport, 
	last_name ||' '|| first_name||' ' || patrinymic as FIO, 
	phone, 
	'type 2' as fraud_type,
	current_timestamp as report_dt
from bigt 
where account_valid_to < date;


select * from report;