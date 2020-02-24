  
CREATE TABLE USER_CONFIG_SYSTEM
(
USER_TYPE     VARCHAR2(2),    
ROLE_ID       VARCHAR2(5),
STATUS_CODE   VARCHAR2(3),
LOG_ID        NUMBER(12)
);
ALTER TABLE USER_CONFIG_SYSTEM 
ADD CONSTRAINT FK_USER_CONFIG_USER_TYPE FOREIGN KEY (USER_TYPE) REFERENCES User_Type(User_Type)
/
ALTER TABLE USER_CONFIG_SYSTEM 
ADD CONSTRAINT FK_USER_CONFIG_ROLE_ID FOREIGN KEY (ROLE_ID) REFERENCES User_Role(Role_Id)
/
ALTER TABLE USER_CONFIG_SYSTEM 
ADD CONSTRAINT FK_USER_CONFIG_STATUS_CODE FOREIGN KEY (STATUS_CODE) REFERENCES User_Status(Status_Id)
/
ALTER TABLE USER_CONFIG_SYSTEM 
ADD CONSTRAINT FK_USER_CONFIG_LOG_ID FOREIGN KEY (LOG_ID) REFERENCES User_Op_Log(Log_Id)
/
-- Audit Table...
CREATE TABLE AUDIT_USER_CONFIG_SYSTEM
(
VERSION_NO    NUMBER(5),
USER_TYPE     VARCHAR2(2),    
ROLE_ID       VARCHAR2(5),
STATUS_CODE   VARCHAR2(3),
LOG_ID        NUMBER(12)
);
ALTER TABLE AUDIT_USER_CONFIG_SYSTEM ADD PRIMARY KEY (VERSION_NO)
/
-- Audit Trigger...
CREATE TRIGGER audit_trg_user_config_system
BEFORE UPDATE OR DELETE ON user_config_system
FOR EACH ROW
DECLARE
  -- local variables
  v_next_version        audit_user_config_system.version_no%TYPE;
BEGIN
  -- Next version...
  SELECT NVL(MAX(version_no),0) + 1
    INTO v_next_version
    FROM audit_user_config_system;
  
  INSERT INTO audit_user_config_system(version_no, user_type, role_id, status_code, log_id)
  VALUES(v_next_version, :OLD.user_type, :OLD.role_id, :OLD.status_code, :OLD.log_id);
END audit_trg_user_config_system;
/