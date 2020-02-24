create type colnames as object 
(
colname  varchar2(50)
)
/
create type colnames_tb as table of colnames 
/
create type clearing as object 
(
cler  varchar2(50)
)
/
create type clearing_tb as table of clearing
/
create type tradetype as object 
(
 trade   varchar2(5)
)
/
create type tradetype_tb as table of tradetype
/
create type markettype as object 
(
 market    varchar2(8)
)
/
create type markettype_tb as table of markettype 
/
create type stockexchange as object 
(
 stock    varchar2(5)
)
/
create type stockexchange_tb as table of stockexchange
/
create type tradercode as object 
(
 trdcode varchar2(9)
)
/
create type tradercode_tb as table of tradercode
/
create type clienttype as object 
(
 client varchar2(30)
)
/
create type clienttype_tb as table of clienttype
/

create type clients as object 
(
 clientone varchar2(100),
 clienttwo varchar2(100)
)
/
create type clients_tb as table of clients
/


/*
 Table Periodic Save
 =================== 
*/

create table PERIODIC_SAVE
(
  REP_NAME VARCHAR2(100),
  COL      COLNAMES_TB,
  CLE      CLEARING_TB,
  TRD      TRADETYPE_TB,
  MKT      MARKETTYPE_TB,
  STK      STOCKEXCHANGE_TB,
  TCD      TRADERCODE_TB,
  CTP      CLIENTTYPE_TB,
  GRPNAME  VARCHAR2(100),
  BILL     VARCHAR2(100),
  STOCK    VARCHAR2(100),
  SEC      VARCHAR2(100),
  CLI      CLIENTS_TB,
  FROMDATE varchar2(25),
  TODATE   varchar2(25)
)
nested table COL store as COL_TAB
nested table CLE store as CLE_TAB
nested table TRD store as TRD_TAB
nested table MKT store as MKT_TAB
nested table STK store as STK_TAB
nested table TCD store as TCD_TAB
nested table CTP store as CTP_TAB
nested table CLI store as CLI_TAB

/


/*
  Periodic Columns Table
*/

create table PERIODIC_COLUMNS
(
  COLUMN_NAME  VARCHAR2(50),
  COLUMN_VALUE VARCHAR2(50),
  COLUMN_TYPE  VARCHAR2(10)
)
/

insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('client_code', 'client_code', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('client_name', 'clients_short_name', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('client_type', 'client_type', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('client_group', 'group_code', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('security_symbol', 'symbol', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('isin', 'isin', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('exchange_name', 'short_name', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('security_name', 'security_short_name', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('clearing_type', 'description', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('market_type', 'market_type', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('trade_type', 'trade_type', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('settlement_date', 'settlement_date', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('trade_date', 'trade_date', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('trade_number', 'trade_number', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('bill_number', 'bill_number', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('buy_or_sell', 'buy_or_sell', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('buy_volume', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('sell_volume', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('volume', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('share_rate', 'rate', 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('buy_amount', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('sell_amount', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('amount', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('brokerage', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('cvt', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('wht_sell', null, 'number');
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('wht_cot', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('wht', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('ptr', null, 'number')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('se_trade', 'se_trade', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('trader_code', 'trader_code', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('trader_name', '(emp.first_name||emp.last_name)', 'varchar2')
/
insert into PERIODIC_COLUMNS (COLUMN_NAME, COLUMN_VALUE, COLUMN_TYPE)
values ('brokerage rate', null, 'number')
/


create table PERIODIC
(
  COLUMN_NAME  VARCHAR2(100),
  COLUMN_VALUE VARCHAR2(100),
  SEQ_NO       NUMBER,
  valid        varchar2(1)  	
)
/


create table AGG_STRING
(
  LEV        NUMBER,
  ROLL_ONE   VARCHAR2(50),
  ROLL_TWO   VARCHAR2(50),
  ROLL_THREE VARCHAR2(100),
  ROLL_FOUR  VARCHAR2(100)
)
/


create global temporary table header_columns(item varchar2(50),narr varchar2(1000),seq number) on commit preserve rows 
/

create table WHERE_CLAUSE
(
  STR VARCHAR2(100)
)
/
create global temporary table COLUU
(
  ITEM VARCHAR2(100),
  NME  VARCHAR2(100)
)
on commit delete rows;
/


alter table agg_string add roll_five varchar2(100)
/