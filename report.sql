--analyze;
--explain analyze 
drop if exist view report;

create view report 
as with ac as (
	select *
		from project.accounts a 
		NATURAL join project.clients c 		
),
tt as (
	select *
		from project.terminals tr 
		NATURAL join project.fact_transactions ft 	
),
acc as (
	select *
		from project.cards cr 
		NATURAL join ac
),
bigt as (
	select *
		from tt
		NATURAL join acc
),                                       --cte со всеми данными

podbor as (         -- вспомогательная cte для выявления мошеннических действи №4
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
diff_city as (               -- вспомогательная cte для выявления мошеннических действи №4
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
select                   -- селект для выявления мошеннических действи №4 
	date as FRAUD_DT, 
	passport, 
	FIO, 
	phone, 
	'type 4' as fraud_type,
	current_timestamp as report_dt
from podbor
where (date - lag_date3) < interval '20 minute' and oper_result = 'Успешно' 
	and lag_result1 = 'Отказ' and lag_result2 = 'Отказ' and lag_result3 = 'Отказ'
	and amount < lag_amount1 and lag_amount1 < lag_amount2 and lag_amount2 < lag_amount3
union
select                  -- селект для выявления мошеннических действи №3 
	date as FRAUD_DT, 
	passport, 
	FIO, 
	phone, 
	'type 3' as fraud_type,
	current_timestamp as report_dt
from diff_city
where (date - lag_date) < interval '1 hour' and lag_city <> terminal_city
	union
select                           -- селект для выявления мошеннических действи №1 
	date as FRAUD_DT, 
	passport, 
	last_name ||' '|| first_name||' ' || patrinymic as FIO, 
	phone, 
	'type 1' as fraud_type,
	current_timestamp as report_dt
from bigt
where passport_valid_to < date
	union 
select                            -- селект для выявления мошеннических действи №2 
	date as FRAUD_DT, 
	passport, 
	last_name ||' '|| first_name||' ' || patrinymic as FIO, 
	phone, 
	'type 2' as fraud_type,
	current_timestamp as report_dt
from bigt 
where account_valid_to < date;

select * from report;