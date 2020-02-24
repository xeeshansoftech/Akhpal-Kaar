-- Create table
create table CDC_UIN_LOADER_CONFIG
(
  CDC_VOUCHER_TYPE      VARCHAR2(3) default 'GJV' not null,
  CDC_BOOK_TYPE         VARCHAR2(6) not null,
  CDC_GL_CODE           VARCHAR2(100),
  CDC_SL_TYPE           NUMBER(5),
  CDC_SL_CODE           VARCHAR2(100),
  CDC_DR_NARRATION      VARCHAR2(100),
  CDC_CONTRA_NARRATION  VARCHAR2(100),
  POST                  NUMBER(1) default 0,
  LOG_ID                NUMBER(12),
  UIN_VOUCHER_TYPE      VARCHAR2(3) default 'GJV' not null,
  UIN_BOOK_TYPE         VARCHAR2(6) not null,
  UIN_GL_CODE           VARCHAR2(100),
  UIN_SL_TYPE           NUMBER(5),
  UIN_SL_CODE           VARCHAR2(100),
  UIN_DR_NARRATION      VARCHAR2(100),
  UIN_CONTRA_NARRATION  VARCHAR2(100)
);
-- Create/Recreate primary, unique and foreign key constraints 
alter table CDC_UIN_LOADER_CONFIG
  add constraint FK_UIN_BOOK_TYPE foreign key (UIN_BOOK_TYPE)
  references GL_BOOK_TYPE (GL_BOOK_TYPE);
alter table CDC_UIN_LOADER_CONFIG
  add constraint FK_CDC_BOOK_TYPE foreign key (CDC_BOOK_TYPE)
  references GL_BOOK_TYPE (GL_BOOK_TYPE);

alter table CDC_UIN_LOADER_CONFIG
  add constraint FK_CDC_GL_GLMF foreign key (CDC_GL_CODE)
  references GL_GLMF (GL_GLMF_CODE);
alter table CDC_UIN_LOADER_CONFIG
  add constraint FK_UIN_GL_GLMF foreign key (UIN_GL_CODE)
  references GL_GLMF (GL_GLMF_CODE);

alter table CDC_UIN_LOADER_CONFIG
  add constraint FK_CDC_GL_SL foreign key (CDC_SL_TYPE, CDC_SL_CODE)
  references GL_SL_MF (GL_SL_TYPE, GL_SL_CODE);
alter table CDC_UIN_LOADER_CONFIG
  add constraint FK_UIN_GL_SL foreign key (UIN_SL_TYPE, UIN_SL_CODE)
  references GL_SL_MF (GL_SL_TYPE, GL_SL_CODE);
  
alter table CDC_UIN_LOADER_CONFIG
  add constraint FK_CDC_UIN_LOG_ID foreign key (LOG_ID)
  references USER_OP_LOG (LOG_ID);
-- Create/Recreate check constraints 
alter table CDC_UIN_LOADER_CONFIG
  add constraint CHK_CDC_CONFIG_VCHR_TYPE
  check (CDC_VOUCHER_TYPE IN ('GJV', 'GBP'));
alter table CDC_UIN_LOADER_CONFIG
  add constraint CHK_UIN_CONFIG_VCHR_TYPE
  check (UIN_VOUCHER_TYPE IN ('GJV', 'GBP'));
-- Create Audit table
create table AUDIT_CDC_UIN_LOADER_CONFIG
(
  VERSION_NO            NUMBER(5) PRIMARY KEY,
  CDC_VOUCHER_TYPE      VARCHAR2(3) default 'GJV' not null,
  CDC_BOOK_TYPE         VARCHAR2(6) not null,
  CDC_GL_CODE           VARCHAR2(100),
  CDC_SL_TYPE           NUMBER(5),
  CDC_SL_CODE           VARCHAR2(100),
  CDC_DR_NARRATION      VARCHAR2(100),
  CDC_CONTRA_NARRATION  VARCHAR2(100),
  POST                  NUMBER(1) default 0,
  LOG_ID                NUMBER(12),
  UIN_VOUCHER_TYPE      VARCHAR2(3) default 'GJV' not null,
  UIN_BOOK_TYPE         VARCHAR2(6) not null,
  UIN_GL_CODE           VARCHAR2(100),
  UIN_SL_TYPE           NUMBER(5),
  UIN_SL_CODE           VARCHAR2(100),
  UIN_DR_NARRATION      VARCHAR2(100),
  UIN_CONTRA_NARRATION  VARCHAR2(100)
);
-- Create Audit Trigger
CREATE OR REPLACE TRIGGER AUD_CDC_UIN_LOAD_CONFIG
BEFORE UPDATE OR DELETE ON CDC_UIN_LOADER_CONFIG
FOR EACH ROW
DECLARE
  v_nextversion         audit_CDC_UIN_LOADER_CONFIG.VERSION_NO%TYPE;
BEGIN
  SELECT NVL(MAX(VERSION_NO),0) + 1 INTO v_nextversion FROM AUDIT_CDC_UIN_LOADER_CONFIG;
  
  INSERT INTO AUDIT_CDC_UIN_LOADER_CONFIG(VERSION_NO, CDC_VOUCHER_TYPE, CDC_BOOK_TYPE, CDC_GL_CODE, CDC_SL_TYPE, 
                                          CDC_SL_CODE, CDC_DR_NARRATION, CDC_CONTRA_NARRATION, POST, LOG_ID, 
                                          UIN_VOUCHER_TYPE, UIN_BOOK_TYPE, UIN_GL_CODE, UIN_SL_TYPE, UIN_SL_CODE, 
                                          UIN_DR_NARRATION, UIN_CONTRA_NARRATION)
         VALUES(v_nextVersion, :OLD.CDC_VOUCHER_TYPE, :OLD.CDC_BOOK_TYPE, :OLD.CDC_GL_CODE, :OLD.CDC_SL_TYPE, 
                :OLD.CDC_SL_CODE, :OLD.CDC_DR_NARRATION, :OLD.CDC_CONTRA_NARRATION, :OLD.POST, :OLD.LOG_ID, 
                :OLD.UIN_VOUCHER_TYPE, :OLD.UIN_BOOK_TYPE, :OLD.UIN_GL_CODE, :OLD.UIN_SL_TYPE, :OLD.UIN_SL_CODE, 
                :OLD.UIN_DR_NARRATION, :OLD.UIN_CONTRA_NARRATION);
END AUD_CDC_UIN_LOAD_CONFIG;
/