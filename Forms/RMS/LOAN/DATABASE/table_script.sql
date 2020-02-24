-- Create table
create table RMS_CLIENTS_LOAN
(
  RMS_LOAN_ID NUMBER(12) not null,
  LOAN_DATE   DATE,
  CLIENT_CODE VARCHAR2(100) not null,
  LOAN_AMOUNT NUMBER(15,2) default 0 not null,
  APPROVED_BY VARCHAR2(30),
  EXECUTED    NUMBER(1) default 0 not null,
  POST        NUMBER(1) default 0 not null,
  LOG_ID      NUMBER(12) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table RMS_CLIENTS_LOAN
  add constraint RMS_LOAN_ID_PK primary key (RMS_LOAN_ID);

-- Create table
create table AUDIT_RMS_CLIENTS_LOAN
(
  rms_loan_id NUMBER(12) not null,
  loan_date   DATE,
  client_code VARCHAR2(100) not null,
  loan_amount NUMBER(15,2) not null,
  approved_by VARCHAR2(300),
  executed    NUMBER(1) not null,
  post        NUMBER(1) not null,
  log_id      NUMBER(12) not null,
  version_no  NUMBER(5) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table AUDIT_RMS_CLIENTS_LOAN
  add constraint AUDIT_RMS_CLIENTS_LOAN_PK primary key (RMS_LOAN_ID, VERSION_NO);


-- Create table
create table RMS_CLIENTS_TRADABLE_CASH_LOG
(
  RMS_CTC_LOG_ID              NUMBER(12) not null,
  CTC_DATE                    DATE,
  CLIENT_CODE                 VARCHAR2(100) not null,
  ST_EX_CODE                  VARCHAR2(2) not null,
  LOAN_AMOUNT                 NUMBER(15,2) default 0 not null,
  PREV_TRADABLE_CASH          NUMBER(15,2) default 0 not null,
  PREV_LEDGER_CASH            NUMBER(15,2) default 0 not null,
  PREV_PROJECTED_EX_WISE_CASH NUMBER(15,2) default 0 not null,
  PREV_DEPOSITED_EX_WISE_CASH NUMBER(15,2) default 0 not null,
  PREV_FUT_BLOCKED_CASH       NUMBER(15,2) default 0 not null,
  PREV_READY_UNSETT_CASH      NUMBER(15,2) default 0 not null,
  PREV_FPR_BASED_BLOCKED_CASH NUMBER(15,2) default 0,
  TRADABLE_CASH               NUMBER(15,2) default 0 not null,
  LEDGER_CASH                 NUMBER(15,2) default 0 not null,
  PROJECTED_EX_WISE_CASH      NUMBER(15,2) default 0 not null,
  DEPOSITED_EX_WISE_CASH      NUMBER(15,2) default 0 not null,
  FUT_BLOCKED_CASH            NUMBER(15,2) default 0 not null,
  READY_UNSETT_CASH           NUMBER(15,2) default 0 not null,
  FPR_BASED_BLOCKED_CASH      NUMBER(15,2) default 0,
  RMS_LOAN_ID                 NUMBER(12) not null,
  LOG_ID                      NUMBER(12) not null
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table RMS_CLIENTS_TRADABLE_CASH_LOG
  add constraint PK_RMS_CTC primary key (RMS_CTC_LOG_ID);
alter table RMS_CLIENTS_TRADABLE_CASH_LOG
  add constraint FK_RMS_LOAN_ID foreign key (RMS_LOAN_ID)
  references RMS_CLIENTS_LOAN (RMS_LOAN_ID);


-- Create sequence 
create sequence SEQ_RMS_CTC_LOG
minvalue 1
maxvalue 999999999999999
start with 122
increment by 1
nocache
order;

