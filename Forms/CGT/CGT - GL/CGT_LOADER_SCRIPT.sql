drop TABLE AUDIT_CGT_LOADER_CONFIGURATION;
drop table CGT_LOADER_CONFIGURATION;
DROP TABLE CGT_LOADER_BATCH;
DROP TABLE cgt_batch;
DROP TABLE TEMP_INVALID_CGT_LOADER;
DROP TABLE TEMP_INVALID_UIN;
DROP TABLE TEMP_CREDIT_CLIENTS;
DROP TABLE TEMP_CGT_FILE;
DROP SEQUENCE CGT_SEQ;
--=======================
insert into trn_code (trn_code, description, menu_label,Module_code, 
post, log_id) values('T752','CGT FILE LOADER',NULL,'T',1,0)
/
insert into trn_code (trn_code, description, menu_label,Module_code, 
post, log_id) values('T754','CGT LOADER ROLLBACK',NULL,'T',1,0);
/
insert into trn_code (trn_code, description, menu_label,Module_code, 
post, log_id) values('T755','CGT LOADER CONFIG FORM',NULL,'T',1,0)
/
insert into trn_code (trn_code, description, menu_label,Module_code, post, log_id) 
values('E237','CGT VOUCHER LOADER REPORT ',NULL,'T',1,0) 
/
insert into trn_code (trn_code, description, menu_label,Module_code, post, log_id) 
values('E238','CGT INVOICE REPORT ',NULL,'T',1,0)
/ 
begin
run;
end;
/
commit
/
-- Create table
create table CGT_LOADER_CONFIGURATION
(
  VOUCHER_TYPE            VARCHAR2(3) default 'GJV' not null,
  VOUCHER_MODE            CHAR(1) default 'S' not null,
  GL_BOOK_TYPE            VARCHAR2(6) not null,
  GL_GLMF_CODE            VARCHAR2(100),
  GL_SL_TYPE              NUMBER(5),
  GL_SL_CODE              VARCHAR2(100),
  ALLOW_CREDIT_CLIENT     NUMBER(1) default 0,
  Voucher_Rollback 				CHAR(1) DEFAULT 'R',
  DR_NARRATION						VARCHAR2(100), 
  CR_NARRATION						VARCHAR2(100), 
  CONTRA_NARRATION				VARCHAR2(100), 
  POST                    NUMBER(1) DEFAULT 0,
  LOG_ID                  NUMBER(12)  
);
-- Add Comments
COMMENT ON COLUMN CGT_LOADER_CONFIGURATION.VOUCHER_MODE IS 'M = Multiple (Client Wise),  S = Single (Collective)'
/
COMMENT ON COLUMN CGT_LOADER_CONFIGURATION.VOUCHER_ROLLBACK IS 'R = Reversal,  D = Deletion'
/
-- Check constraints...
ALTER TABLE cgt_loader_configuration 
  ADD CONSTRAINT CHK_VCHR_REVERSAL CHECK(Voucher_Rollback IN ('R', 'D'));
ALTER TABLE cgt_loader_configuration 
  ADD CONSTRAINT CHK_VCHR_MODE CHECK(VOUCHER_MODE IN ('S', 'M'));
-- Create/Recreate primary, unique and foreign key constraints 
alter table CGT_LOADER_CONFIGURATION
  add constraint FK_CGT_GL_GLMF foreign key (GL_GLMF_CODE)
  references GL_GLMF (GL_GLMF_CODE);
alter table CGT_LOADER_CONFIGURATION
  add constraint FK_CGT_GL_SL foreign key (GL_SL_TYPE, GL_SL_CODE)
  references GL_SL_MF (GL_SL_TYPE, GL_SL_CODE);
ALTER TABLE Cgt_Loader_Configuration 
  ADD CONSTRAINT FK_CGT_BOOK_TYPE  FOREIGN KEY (GL_BOOK_TYPE)
  REFERENCES GL_BOOK_TYPE(GL_BOOK_TYPE);
ALTER TABLE Cgt_Loader_Configuration 
  ADD CONSTRAINT FK_CGT_LOG_ID  FOREIGN KEY (LOG_ID)
  REFERENCES USER_OP_LOG(LOG_ID);
    
-- Create/Recreate check constraints 
alter table CGT_LOADER_CONFIGURATION
  add constraint CHK_CGT_CONFIG_VCHR_MODE
  check (VOUCHER_MODE IN ('M', 'S'));
alter table CGT_LOADER_CONFIGURATION
  add constraint CHK_CGT_CONFIG_VCHR_TYPE
  check (VOUCHER_TYPE IN ('GJV', 'GBP'));
-- Create Audit Table...
create table AUDIT_CGT_LOADER_CONFIGURATION
(
  VERSION_NO              NUMBER(5) PRIMARY KEY,      
  VOUCHER_TYPE            VARCHAR2(3) default 'GJV' not null,
  VOUCHER_MODE            CHAR(1) default 'S' not null,
  GL_BOOK_TYPE            VARCHAR2(6) not null,
  GL_GLMF_CODE            VARCHAR2(100),
  GL_SL_TYPE              NUMBER(5),
  GL_SL_CODE              VARCHAR2(100),
  ALLOW_CREDIT_CLIENT     NUMBER(1) default 0,
  Voucher_Rollback 				CHAR(1) DEFAULT 'R',
  DR_NARRATION						VARCHAR2(100), 
  CR_NARRATION						VARCHAR2(100), 
  CONTRA_NARRATION				VARCHAR2(100), 
  POST                    NUMBER(1) DEFAULT 0,
  LOG_ID                  NUMBER(12)
);
-- Audit Trigger...
CREATE OR REPLACE TRIGGER AUD_TRG_CGT_LOADER_CONFIG
BEFORE UPDATE OR DELETE ON CGT_LOADER_CONFIGURATION
FOR EACH ROW
DECLARE
    v_nextversion_no       audit_cgt_loader_configuration.version_no%TYPE;
BEGIN
  SELECT NVL(MAX(version_no),0) + 1 INTO v_nextversion_no FROM audit_cgt_loader_configuration;
  INSERT INTO audit_cgt_loader_configuration(
              version_no, voucher_type, voucher_mode,
              gl_book_type, gl_glmf_code, gl_sl_type,
              gl_sl_code, allow_credit_client, voucher_rollback,
              DR_NARRATION, CR_NARRATION, CONTRA_NARRATION, POST, LOG_ID, INACTIVE_CLIENT)
      VALUES(v_nextversion_no, :old.voucher_type, :old.voucher_mode,
              :old.gl_book_type, :old.gl_glmf_code, :old.gl_sl_type,
              :old.gl_sl_code, :old.allow_credit_client, :OLD.voucher_rollback,
              :OLD.DR_NARRATION, :OLD.CR_NARRATION, :OLD.CONTRA_NARRATION, :OLD.POST, :old.LOG_ID, :OLD.INACTIVE_CLIENT);
END AUD_TRG_CGT_LOADER_CONFIG;
/
-- create table
CREATE TABLE cgt_loader_batch(
gl_voucher_no      NUMBER(12), 
Batch_No           NUMBER(12),
CNIC               VARCHAR2(20),
CLIENT_CODE        VARCHAR2(100), 
Amount             NUMBER(15,2),
Voucher_Date       DATE,
LOG_ID             NUMBER(12),
IS_ROLLBACK  			 NUMBER(1) DEFAULT 0
);
ALTER TABLE cgt_loader_batch ADD CONSTRAINT PK_CGT_LOADER PRIMARY KEY (Batch_No, CNIC)
/
ALTER TABLE cgt_loader_batch ADD CONSTRAINT FK_CGT_LOADER_CLIENT  
FOREIGN KEY (client_code) REFERENCES client(client_code)
/
ALTER TABLE cgt_loader_batch ADD CONSTRAINT FK_CGT_LOADER_LOG_ID
FOREIGN KEY (LOG_ID) REFERENCES User_Op_Log(Log_Id)
/
-- Create Table
CREATE TABLE TEMP_INVALID_CGT_LOADER(
LINE_NO      NUMBER(5),
REMARKS      VARCHAR2(500)
);
-- Create Table
CREATE TABLE TEMP_INVALID_UIN(
LINE_NO      NUMBER(5), 
UIN          VARCHAR2(25),
UIN_NAME		 VARCHAR2(100)
);

-- Create Table
CREATE TABLE TEMP_CREDIT_CLIENTS(
LINE_NO      NUMBER(5), 
UIN          VARCHAR2(25), 
CLIENT_CODE  VARCHAR2(100)
);

-- Create table
create table TEMP_CGT_FILE
(
  LINE_NO     NUMBER(5),
  FILE_LINE   VARCHAR2(1500), 
  CLIENT_CODE VARCHAR2(100),
  CLIENT_NAME VARCHAR2(100),
  UIN         VARCHAR2(25),
  AMOUNT      NUMBER(15,2),
  LOAD_CLIENT NUMBER(1) default 0
);

-- Create sequence 
CREATE SEQUENCE CGT_SEQ
MINVALUE 1
MAXVALUE 999999999999
START WITH 1
INCREMENT BY 1
NOCACHE
ORDER;

---- FOR CGT FEE

ALTER TABLE CGT_LOADER_CONFIGURATION
ADD   (CGT_FEE_GL_CODE VARCHAR2(100),CGT_FEE_SL_TYPE NUMBER(5), CGT_FEE_SL_CODE VARCHAR2(100),CGT_FEE_DR_NARRATION VARCHAR2(100),CGT_FEE_CR_NARRATION VARCHAR2(100))
/
ALTER TABLE CGT_LOADER_BATCH
ADD   BATCH_TYPE CHAR(3) DEFAULT 'REF'
/
ALTER TABLE CGT_LOADER_BATCH
DROP CONSTRAINT PK_CGT_LOADER
/
DROP INDEX PK_CGT_LOADER
/
ALTER TABLE CGT_LOADER_BATCH
ADD CONSTRAINT  PK_CGT_LOADER PRIMARY KEY (BATCH_NO,CNIC,BATCH_TYPE)
/
COMMENT ON COLUMN CGT_LOADER_BATCH.BATCH_TYPE
IS '''FEE'' for CGT Fee, ''REF'' for CGT Re-Fund, ''CGT'' CGT Charges, ''CDC'' CDC Charges'
/
ALTER TABLE CGT_LOADER_BATCH
ADD CONSTRAINT CHK_BATCH_TYPE CHECK (BATCH_TYPE IN ('FEE', 'REF', 'CGT', 'CDC'))
/
--===============================================================
-- CGT BATCH MANAGEMENT, CHANGES DONE @ 11-JUN-2013 BY IRFAN KHAN
--===============================================================
ALTER TABLE CGT_LOADER_BATCH DROP CONSTRAINT CHK_BATCH_TYPE
/
ALTER TABLE CGT_LOADER_BATCH DROP CONSTRAINT PK_CGT_LOADER
/
DROP INDEX PK_CGT_LOADER
/
ALTER TABLE CGT_LOADER_BATCH
ADD CONSTRAINT  PK_CGT_LOADER PRIMARY KEY (BATCH_NO,CNIC)
/
-- Create Table...
CREATE TABLE cgt_batch(
BATCH_NO      NUMBER(12),
BATCH_TYPE    CHAR(3)
);
    
COMMENT ON COLUMN CGT_BATCH.BATCH_TYPE
IS '''FEE'' for CGT Fee, ''REF'' for CGT Re-Fund, ''UIN'' UIN Charges, ''CDC'' CDC Charges'
/
ALTER TABLE CGT_BATCH
ADD CONSTRAINT PK_CGT_BATCH PRIMARY KEY (BATCH_NO)
/
ALTER TABLE CGT_BATCH
ADD CONSTRAINT CHK_BATCH_TYPE CHECK (BATCH_TYPE IN ('FEE', 'REF', 'UIN', 'CDC'))
/
-- Insert already created batch entries...
INSERT INTO cgt_BATCH(Batch_No, Batch_Type)
SELECT UNIQUE b.batch_no, DECODE(b.batch_type, 'R', 'REF', 'F', 'FEE') batch_Type
 FROM cgt_loader_batch b
/
COMMIT
/
ALTER TABLE CGT_LOADER_BATCH DROP COLUMN BATCH_TYPE
/
ALTER TABLE CGT_LOADER_BATCH
ADD CONSTRAINT  FK_CGT_BATCH FOREIGN KEY (BATCH_NO) REFERENCES CGT_BATCH(BATCH_NO)
/

-- Added by Irfan @ 22-MAR-2016
ALTER TABLE CGT_LOADER_CONFIGURATION ADD INACTIVE_CLIENT  NUMBER(1) DEFAULT 0
/
ALTER TABLE AUDIT_CGT_LOADER_CONFIGURATION ADD INACTIVE_CLIENT  NUMBER(1) DEFAULT 0
/
