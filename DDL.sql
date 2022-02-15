CREATE SCHEMA project AUTHORIZATION miron;

drop table if exists project.fact_transactions;
drop table if exists project.terminals;
drop table if exists project.cards;
drop table if exists project.accounts;
drop table if exists project.clients;

create table project.FACT_TRANSACTIONS(
	trans_id varchar(100) not null,
	date timestamp not null,
	card varchar(100) not null,
	oper_type varchar(100) not null,
	amount numeric not null,
	oper_result varchar(100) not null,
	terminal varchar(100) not null)
distributed by (trans_id);

create table project.terminals(
	terminal varchar(100) primary key,
	terminal_type varchar(100) not null,
	terminal_city varchar(100) not null,
	address varchar(100) not null
	);

create table project.cards(
	card varchar(100) primary key,
	account varchar(100) not null);

create table project.accounts(
	account varchar(100) primary key,
	account_valid_to date not null,
	client varchar(100) not null);

create table project.clients(
	client varchar(100) primary key,
	last_name varchar(100) not null,
	first_name varchar(100) not null,
	patrinymic varchar(100) not null,
	date_of_birth date not null,
	passport varchar(100) not null,
	passport_valid_to date not null,
	phone varchar(20) not null);