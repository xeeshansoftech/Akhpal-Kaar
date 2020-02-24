drop table cgt_opening;
drop table cgt_buy_sell_reference;
drop table cgt_sell_det;
drop table cgt_buy_det;
drop table TEMP_CGT_CUSTODY_BALANCE;
drop table TEMP_CGT_REPORT;
drop table CGT_TAX_CONFIGURATION;
drop sequence CGT_BUYDETID_SEQ;
drop sequence CGT_SELLDETID_SEQ;
drop sequence Temp_CGT_BUYDETID_SEQ;
drop sequence Temp_CGT_SELLDETID_SEQ;
drop table temp_cgt_buy_sell_reference;
drop table temp_cgt_sell_det;
drop table temp_cgt_buy_det;
-- Create table
create table CUSTODY_MASTER_EXTRA
(
  TRANSACTION_ID NUMBER(12) not null,
  CUSTODY_TYPE   CHAR(1) default 'N' not null,
  CUSTODY_RATE   NUMBER(9,4) default 0
);
-- Add comments to the columns 
comment on column CUSTODY_MASTER_EXTRA.CUSTODY_TYPE
  is 'N=NORMAL, I=IPO, R=RIGHT, B=BONUS';
-- Create/Recreate primary, unique and foreign key constraints 
alter table CUSTODY_MASTER_EXTRA
  add constraint PK_CM_EXTRA primary key (TRANSACTION_ID)
/
alter table CUSTODY_MASTER_EXTRA
  add constraint FK_CM_EXTRA_CUST_MASTER foreign key (TRANSACTION_ID)
  references CUSTODY_MASTER (TRANSACTION_ID)
/
-- Create/Recreate check constraints 
alter table CUSTODY_MASTER_EXTRA
  add constraint CHK_CM_EXTRA_TYPE
  check (CustodY_Type IN ('N', 'I', 'R', 'B'))
/
-- Temporary table for holding report's data...
create table TEMP_CGT_REPORT
(
  CLIENT_CODE         VARCHAR2(100),
  CLIENT_NAME         VARCHAR2(100),
  SYMBOL              VARCHAR2(12),
  SELL_SYMBOL         VARCHAR2(20),
  SELL_ID             NUMBER(15),
  PREV_SALE_PURCHASE  NUMBER(15),
  SELL_DATE           DATE,
  SELL_VOLUME         NUMBER(15),
  SELL_NET_RATE       NUMBER(15,4),
  SELL_AMOUNT         NUMBER(15,2),
  BUY_SYMBOL          VARCHAR2(20),
  BUY_ID              NUMBER(15),
  BUY_DATE            DATE,
  BUY_VOLUME          NUMBER(15),
  BUY_NET_RATE        NUMBER(15,4),
  BUY_AMOUNT          NUMBER(15,2),
  GAIN_LOSS           NUMBER(15,2),
  NO_OF_DAYS          NUMBER(5),
  CGT_PAYABLE         NUMBER(15,2),
  SELL_ACTUAL_RATE    NUMBER(15,4),
  BUY_ACTUAL_RATE     NUMBER(15,4),
  SELL_ACTUAL_VOLUME  NUMBER(20),
  BUY_ACTUAL_VOLUME   NUMBER(20),
  SELL_ACTUAL_CHARGES NUMBER(15,4),
  BUY_ACTUAL_CHARGES  NUMBER(15,4)
);
-- Create table
create global temporary table TEMP_CGT_CUSTODY_BALANCE
(
  CLIENT_CODE VARCHAR2(100),
  ISIN        VARCHAR2(12),
  VOLUME      NUMBER(15)
) on commit delete rows;
-- Create/Recreate indexes 
create index IDX_CLIENT on TEMP_CGT_CUSTODY_BALANCE (CLIENT_CODE)
/
create index IDX_ISIN on TEMP_CGT_CUSTODY_BALANCE (ISIN)
/
-- Tax Configuration Table
create table CGT_TAX_CONFIGURATION
(
  CGT_DATE         DATE not null,
  DURATION_1       NUMBER(3) not null,
  DURATION_1_RATIO NUMBER(5,2) not null,
  DURATION_2       NUMBER(3) not null,
  DURATION_2_RATIO NUMBER(5,2) not null,
  DURATION_3       NUMBER(3) not null,
  DURATION_3_RATIO NUMBER(5,2) not null,
  INCLUDE_WHT      NUMBER(1) DEFAULT 1 NOT NULL,
  HOUSE_ACC				 NUMBER(1)	DEFAULT 0					
);
insert into cgt_tax_configuration(CGT_Date, duration_1, duration_1_ratio, duration_2, duration_2_ratio, duration_3, duration_3_ratio, include_wht)
values('30-JUN-2010', 182, 10.00, 365, 7.50, 366, 0, 1)
/
commit
/
-- Create table
create table CGT_OPENING
(
  CGT_ID      NUMBER(15) not null,
  CLIENT_CODE VARCHAR2(100) not null,
  YEAR        NUMBER(4),
  QUARTER     NUMBER(1) DEFAULT 0,
  FROM_DATE   DATE,
  TO_DATE     DATE,
  REMARKS     VARCHAR2(255),
  POST        NUMBER(1) not null,
  LOG_ID      NUMBER(12) not null,
  HOUSE_ACC		NUMBER(1)	DEFAULT 0
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table CGT_OPENING
  add constraint PK_CGT_OPENING_ID primary key (CGT_ID, CLIENT_CODE)
/
COMMENT ON COLUMN CGT_OPENING.QUARTER IS '"0" Defines Opening Position Calculations'
/
--=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- Create table
create table CGT_BUY_DET
(
  BUY_DET_ID      NUMBER(15) not null,
  TRADE_NUMBER    NUMBER(15),
  TRADE_DATE      DATE,
  SETTLEMENT_DATE DATE,
  CLEARING_NO     NUMBER(12),
  CLIENT_CODE     VARCHAR2(6),
  ISIN            VARCHAR2(12),
  RATE            NUMBER(15,4),
  VOLUME          NUMBER(15),
  BRK_AMOUNT      NUMBER(15,2),
  FED_AMOUNT      NUMBER(15,2),
  CVT             NUMBER(15,2),
  WHT							NUMBER(15,2),
  REM_VOLUME      NUMBER(15),
  CGT_ID          NUMBER(15),
  SELL_DET_ID     NUMBER(15),
  SYMBOL          VARCHAR2(12),
  HOUSE_ACC				NUMBER(1)	DEFAULT 0
);
-- Add comments to the columns 
comment on column CGT_BUY_DET.CGT_ID
  is 'CGT EXECUTION LOG ID';
-- Create/Recreate primary, unique and foreign key constraints 
alter table CGT_BUY_DET
  add constraint PK_CGT_BUYDET_BID primary key (BUY_DET_ID)
/
alter table CGT_BUY_DET
  add constraint FK_CGT_BUYDET_CLEARING foreign key (CLEARING_NO)
  references CLEARING_CALENDAR (CLEARING_NO)
/
alter table CGT_BUY_DET
  add constraint FK_CGT_BUYDET_CLIENT foreign key (CLIENT_CODE)
  references CLIENT (CLIENT_CODE)
/
alter table CGT_BUY_DET
  add constraint FK_CGT_BUYDET_ISIN foreign key (ISIN)
  references SECURITY (ISIN)
/
-- Create/Recreate indexes 
create index IDX_CGT_BUY_DET_SD on CGT_BUY_DET (CLIENT_CODE, ISIN, SETTLEMENT_DATE)
/
create index IDX_CGT_BUY_DET_TD on CGT_BUY_DET (CLIENT_CODE, ISIN, TRADE_DATE)
/
create index IDX_CGT_BUY_DET_TNO on CGT_BUY_DET (TRADE_NUMBER)
/
--=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- Create table
create table CGT_SELL_DET
(
  SELL_DET_ID     NUMBER(15) not null,
  TRADE_NUMBER    NUMBER(15),
  TRADE_DATE      DATE,
  SETTLEMENT_DATE DATE,
  CLEARING_NO     NUMBER(12),
  CLIENT_CODE     VARCHAR2(6),
  ISIN            VARCHAR2(12),
  RATE            NUMBER(15,4),
  VOLUME          NUMBER(15),
  BRK_AMOUNT      NUMBER(15,2),
  FED_AMOUNT      NUMBER(15,2),
  CVT             NUMBER(15,2),
  WHT							NUMBER(15,2),
  REM_VOLUME      NUMBER(15),
  CGT_ID          NUMBER(15),
  BUY_DET_ID      NUMBER(15),
  SYMBOL          VARCHAR2(12),
  HOUSE_ACC				NUMBER(1)	DEFAULT 0
);
-- Add comments to the columns 
comment on column CGT_SELL_DET.CGT_ID
  is 'CGT EXECUTION LOG ID';
-- Create/Recreate primary, unique and foreign key constraints 
alter table CGT_SELL_DET
  add constraint PK_CGT_SELLDET_BID primary key (SELL_DET_ID)
/
alter table CGT_SELL_DET
  add constraint FK_CGT_SELLDET_CLEARING foreign key (CLEARING_NO)
  references CLEARING_CALENDAR (CLEARING_NO)
/
alter table CGT_SELL_DET
  add constraint FK_CGT_SELLDET_CLIENT foreign key (CLIENT_CODE)
  references CLIENT (CLIENT_CODE)
/
alter table CGT_SELL_DET
  add constraint FK_CGT_SELLDET_ISIN foreign key (ISIN)
  references SECURITY (ISIN)
/
-- Create/Recreate indexes 
create index IDX_CGT_SELL_DET_SD on CGT_SELL_DET (CLIENT_CODE, ISIN, SETTLEMENT_DATE)
/
create index IDX_CGT_SELL_DET_TD on CGT_SELL_DET (CLIENT_CODE, ISIN, TRADE_DATE)
/
create index IDX_CGT_SELL_DET_TNO on CGT_SELL_DET (TRADE_NUMBER)
/
--=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- Create table
create table CGT_BUY_SELL_REFERENCE
(
  CGT_REFERENCE_ID NUMBER(15) not null,
  CGT_SELL_ID      NUMBER(15),
  CGT_BUY_ID       NUMBER(15),
  VOLUME_CONSUMED  NUMBER(15)
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table CGT_BUY_SELL_REFERENCE
  add constraint PK_CGT_REF_ID primary key (CGT_REFERENCE_ID)
/
alter table CGT_BUY_SELL_REFERENCE
  add constraint FK_CGT_REF_BUY_ID foreign key (CGT_BUY_ID)
  references CGT_BUY_DET (BUY_DET_ID) on delete cascade
/
alter table CGT_BUY_SELL_REFERENCE
  add constraint FK_CGT_REF_SELL_ID foreign key (CGT_SELL_ID)
  references CGT_SELL_DET (SELL_DET_ID) on delete cascade
/
--=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- Create sequence 
create sequence CGT_BUYDETID_SEQ
minvalue 1
maxvalue 999999999999
start with 1
increment by 1
nocache
order;
--=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- Create sequence 
create sequence CGT_SELLDETID_SEQ
minvalue 1
maxvalue 999999999999
start with 1
increment by 1
nocache
order;
--=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- SCRIPTS FOR REMAINING POSITION REPORT
--=-=-=-=-=-=-=-==-=--==-=-=-=--==-=-=-=-=-==-=-=-=-=-=-=-=-=-===-=-=-=-=-=-=-
-- Create sequence 
create sequence Temp_CGT_BUYDETID_SEQ
minvalue 1
maxvalue 999999999999
start with 1
increment by 1
nocache
order;
--=-=-=-=--=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- Create sequence 
create sequence Temp_CGT_SELLDETID_SEQ
minvalue 1
maxvalue 999999999999
start with 1
increment by 1
nocache
order;
--=-=-=-====-==-==-=-=-=-=-=-=-=
-- Create table
create table TEMP_CGT_BUY_DET
(
  BUY_DET_ID      NUMBER(15) not null,
  TRADE_NUMBER    NUMBER(15),
  TRADE_DATE      DATE,
  SETTLEMENT_DATE DATE,
  CLEARING_NO     NUMBER(12),
  CLIENT_CODE     VARCHAR2(6),
  ISIN            VARCHAR2(12),
  RATE            NUMBER(15,4),
  VOLUME          NUMBER(15),
  BRK_AMOUNT      NUMBER(15,2),
  FED_AMOUNT      NUMBER(15,2),
  CVT             NUMBER(15,2),
  WHT             NUMBER(15,2),
  REM_VOLUME      NUMBER(15),
  CGT_ID          NUMBER(15),
  SELL_DET_ID     NUMBER(15),
  SYMBOL          VARCHAR2(12)
);
-- Create table
create table TEMP_CGT_SELL_DET
(
  SELL_DET_ID     NUMBER(15) not null,
  TRADE_NUMBER    NUMBER(15),
  TRADE_DATE      DATE,
  SETTLEMENT_DATE DATE,
  CLEARING_NO     NUMBER(12),
  CLIENT_CODE     VARCHAR2(6),
  ISIN            VARCHAR2(12),
  RATE            NUMBER(15,4),
  VOLUME          NUMBER(15),
  BRK_AMOUNT      NUMBER(15,2),
  FED_AMOUNT      NUMBER(15,2),
  CVT             NUMBER(15,2),
  WHT             NUMBER(15,2),
  REM_VOLUME      NUMBER(15),
  CGT_ID          NUMBER(15),
  BUY_DET_ID      NUMBER(15),
  SYMBOL          VARCHAR2(12)
);
-- Create table
create table TEMP_CGT_BUY_SELL_REFERENCE
(
  CGT_REFERENCE_ID NUMBER(15) not null,
  CGT_SELL_ID      NUMBER(15),
  CGT_BUY_ID       NUMBER(15),
  VOLUME_CONSUMED  NUMBER(15)
);
-- Added by Irfan @ 19-MAY-2012
ALTER TABLE cgt_opening ADD IS_ROLLBACK NUMBER(1) DEFAULT 0 CHECK (IS_ROLLBACK IN (0,1))
/