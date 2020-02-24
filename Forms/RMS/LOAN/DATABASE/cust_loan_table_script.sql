
-- Create table
create table RMS_CUST_CLIENTS_LOAN
(
  RMS_CUST_LOAN_ID NUMBER(12) not null,
  LOAN_DATE   DATE,
  CLIENT_CODE VARCHAR2(100) not null,
  ISIN        VARCHAR2(12) not null,
  LOAN_VOLUME NUMBER(15) default 0 not null,
  SETTLEMENT_DATE DATE not null,
  APPROVED_BY VARCHAR2(30),
  EXECUTED    NUMBER(1) default 0 not null,
  POST        NUMBER(1) default 0 not null,
  LOG_ID      NUMBER(12) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table RMS_CUST_CLIENTS_LOAN
  add constraint RMS_CUST_LOAN_ID_PK primary key (RMS_CUST_LOAN_ID);
alter table RMS_CUST_CLIENTS_LOAN add REJECTED    NUMBER(1) default 0 not null;

-- Create table
create table AUDIT_RMS_CUST_CLIENTS_LOAN
(
  rms_cust_loan_id NUMBER(12) not null,
  loan_date   DATE,
  client_code VARCHAR2(100) not null,
  isin        VARCHAR2(12) not null,
  loan_volume NUMBER(15,2) not null,
  SETTLEMENT_DATE DATE not null,
  approved_by VARCHAR2(300),
  executed    NUMBER(1) not null,
  post        NUMBER(1) not null,
  log_id      NUMBER(12) not null,
  version_no  NUMBER(5) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table AUDIT_RMS_CUST_CLIENTS_LOAN
  add constraint AUDIT_RMS_CUST_CLIENTS_LOAN_PK primary key (RMS_CUST_LOAN_ID, VERSION_NO);

alter table AUDIT_RMS_CUST_CLIENTS_LOAN add REJECTED    NUMBER(1) default 0 not null;

-- Create table
create table RMS_CLIENTS_TR_HOLDING_LOG
(
  RMS_CTH_LOG_ID              NUMBER(12) not null,
  CTH_DATE                    DATE,
  CLIENT_CODE                 VARCHAR2(100) not null,
  ISIN                        VARCHAR2(12) not null,
  LOAN_VOLUME                 NUMBER(15) default 0 not null,
  PREV_TRADABLE_HOLDING       NUMBER(15) default 0 not null,
  SETTLEMENT_DATE             DATE not null,
  RMS_CUST_LOAN_ID                 NUMBER(12) not null,
  LOG_ID                      NUMBER(12) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table RMS_CLIENTS_TR_HOLDING_LOG
  add constraint PK_RMS_CTH primary key (RMS_CTH_LOG_ID);
alter table RMS_CLIENTS_TR_HOLDING_LOG
  add constraint FK_RMS_CUST_LOAN_ID foreign key (RMS_CUST_LOAN_ID)
  references RMS_CUST_CLIENTS_LOAN (RMS_CUST_LOAN_ID);


-- Create sequence 
create sequence SEQ_RMS_CTH_LOG
minvalue 1
maxvalue 999999999999999
start with 122
increment by 1
nocache
order;

