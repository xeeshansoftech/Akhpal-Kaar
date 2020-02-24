CREATE OR REPLACE PROCEDURE auto_user_generation(P_USER_ID      VARCHAR2,
                                        P_NAME         VARCHAR2,
                                        P_CLIENT       VARCHAR2,
                                        P_LOG_ID       NUMBER,
                                        P_Err_Msg  OUT VARCHAR2) IS
/*
This procedure will create a USER in the system from scrach level
i.e. with EMPLOYEE and other relevant entries.
*/
  v_Expiry                 DATE;
  v_Encr_Pwd               users.password%TYPE;
  MyException              EXCEPTION;
  ---------------------
  v_user_type              users.user_type%TYPE;
  v_role_id                users.role_code%TYPE;
  v_Status                 users.status_code%TYPE;
  V_CHK_DUPLICATE          NUMBER(1) := 0;
  v_EMPLOYEE_CODE          EMPLOYEE.EMPLOYEE_CODE%TYPE;
  v_FIRST_NAME             EMPLOYEE.FIRST_NAME%TYPE;
  v_LAST_NAME              EMPLOYEE.LAST_NAME%TYPE;
  v_BRANCH_CODE            EMPLOYEE.BRANCH_CODE%TYPE;
  v_LOCATION_CODE          EMPLOYEE.LOCATION_CODE%TYPE;          
  v_CITY_CODE              EMPLOYEE.CITY_CODE%TYPE;
  v_DEPT_CODE              EMPLOYEE.DEPT_CODE%TYPE;
  v_DATE_OF_JOINING        EMPLOYEE.DATE_OF_JOINING%TYPE;
  -- Trader Fields...
  v_TRADER_CODE            Trader.Trader_Code%TYPE;
  v_St_Ex_code             trader.st_ex_code%TYPE;
  v_pos                    NUMBER := 0;    
BEGIN
  P_Err_Msg := 'VALID';
  -- Check User Duplication...
  BEGIN
      SELECT 1 INTO v_chk_duplicate FROM users u
       WHERE u.user_id = P_USER_ID;
      P_ERR_MSG := 'User ('||P_USER_ID||') already opened.';
      RAISE MyException;
  EXCEPTION
    WHEN no_data_found THEN
      NULL;
  END;
  -- Fetch User Configuration...
  BEGIN
      SELECT ucs.user_type, ucs.role_id, ucs.status_code
        INTO v_user_type, v_role_id, v_Status
        FROM User_Config_System ucs;
  EXCEPTION
    WHEN No_Data_Found THEN
      P_Err_Msg := 'User configurations not found.';
      RAISE MyException;
  END;    
  
  -- Check Employee Duplication...
  BEGIN
      SELECT 1 INTO v_chk_duplicate FROM employee e
       WHERE e.first_name||' '||e.last_name = P_Name;
      P_ERR_MSG := 'Employee with name ('||P_NAME||') already opened.';
      RAISE MyException;
  EXCEPTION
    WHEN no_data_found THEN
      NULL;
  END;
  
  -- EMPLOYeE_ID
  v_EMPLOYEE_CODE := get_next_code('EMPLOYEE_CODE', 'EMPLOYEE');
  SELECT instr(P_NAME, ' ', 1) INTO v_pos FROM dual;
  IF v_pos > 0 THEN
    v_FIRST_NAME := substr(P_Name, 1, v_pos-1);
    v_LAST_NAME := substr(P_Name, 1, v_pos+1);
  ELSE
    v_FIRST_NAME := substr(P_Name, 1, 30);
    v_LAST_NAME  := '-';
  END IF;  
  
  SELECT s.st_ex_code, s.system_date, s.location_code, l.branch_code, b.city_code
    INTO v_ST_EX_CODE, v_DATE_OF_JOINING, v_LOCATION_CODE, v_BRANCH_CODE, v_CITY_CODE
    FROM SYSTEM s, locations l, branch b, city c
   WHERE s.location_code = l.location_code
     AND l.branch_code = b.branch_code
     AND b.city_code = c.city_code;
  
  SELECT es.equity_dept_code INTO v_DEPT_CODE FROM equity_system es;
  
  -- Check for Trader Type user...
  IF v_User_Type = 'TR' THEN
        -- Employee...
        BEGIN
            INSERT INTO employee(EMPLOYEE_CODE, FIRST_NAME, LAST_NAME, F_H_NAME, INITIALS, TITLES,                            
                                 BRANCH_CODE, LOCATION_CODE, JOB_TITLE_CODE, CITY_CODE, BANK_CODE,                             
                                 EXECUTIVE_GRADE_CODE, DEPT_CODE, EMPLOYEE_TYPE, EMPLOYEE_CATEGORY, 
                                 RELIGION_CODE, NATIONALITY, DATE_OF_JOINING, DATE_CONFIRMED, GENDER,              
                                 MARITAL_STATUS, ADDRESS_TYPE, ADDRESS1, POST, LOG_ID, 
                                 salary_structure_code, SHIFT )
                          VALUES(v_EMPLOYEE_CODE, v_FIRST_NAME, v_LAST_NAME, '-', '-', '-',                            
                                 v_BRANCH_CODE, v_LOCATION_CODE, '00', v_CITY_CODE, '01',                            
                                 '00', v_DEPT_CODE, 0, 0, 
                                 '01', 'PAK', v_DATE_OF_JOINING, v_DATE_OF_JOINING, 'M',              
                                 'S', 'P', '--', 1, P_LOG_ID, 0, 0);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              P_ERR_MSG := 'Employee ('||P_NAME||') already opened.';
              RAISE MyException;                         
            WHEN OTHERS THEN
              P_ERR_MSG := 'Error while opening Employee: '||SQLERRM;
              RAISE MyException;
        END;
          
        -- Trader...
        v_TRADER_CODE := get_next_code('TRADER_CODE', 'TRADER');
        BEGIN
            INSERT INTO TRADER(TRADER_CODE, EMPLOYEE_CODE, ST_EX_CODE, POST, LOG_ID)
                          VALUES(v_TRADER_CODE, v_EMPLOYEE_CODE, v_ST_EX_CODE, 1, P_LOG_ID);
        EXCEPTION                         
            WHEN OTHERS THEN
              P_ERR_MSG := 'Error while opening Trader: '||SQLERRM;
              RAISE MyException;
        END;
  END IF;
  ----------------------------------------------------------------------------
  -- User Expiry Date...
  v_Expiry := Trunc(SYSDATE) + 365;
  -- Encrypt Password....
  --Encryption.Encryptpassword(p_User_id, P_PASSWORD, v_Encr_Pwd);
  v_Encr_Pwd := '0000';
  --4..================ Inserting User ================--
  BEGIN
    INSERT INTO Users
      (User_Id, NAME, Short_Name, Password, Multiple_Login, Max_Login,
       Active_Login, Unsucc_Login, Time_Override, User_Type, Client_Code,
       Status_Code, Role_Code, employee_code, User_Expire_Date,
       Expire_Immediate, Post, Log_Id)
    VALUES
      (p_User_id, P_Name, 'SHORT-NAME', v_Encr_Pwd, 0, 0,
       0, 0, 0, v_User_Type, DECODE(v_User_Type, 'CL', P_Client, NULL), 'ACT',
       v_role_id, DECODE(v_User_Type, 'TR', v_EMPLOYEE_CODE, NULL),
       v_Expiry, 1, 1, P_LOG_ID);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      P_Err_Msg := 'User '||P_USER_ID||' already opened.';
      RAISE Myexception;
    WHEN OTHERS THEN
      P_Err_Msg := 'Error while opening User: '||SQLERRM;
      RAISE Myexception;
  END;
  --5..================ Inserting Online User Entry ================--
  BEGIN
    INSERT INTO Onl_User_Det(User_Id, Mobile_Applicable, Mbo_Applicable, Mbp_Applicable, Post, Log_Id)
    VALUES(p_User_id, 1, 0, 0, 1, P_LOG_ID);
  EXCEPTION
    WHEN OTHERS THEN
      P_Err_Msg := 'Error while inserting online user detail: '||SQLERRM;
      RAISE Myexception;
  END;
  --=====================
  -- Client Opening Cash Deposit...
  --=====================
  IF P_Err_Msg <> 'VALID' THEN
    RAISE MyException;
  ELSE
    P_Err_Msg := 'VALID';
  END IF;
EXCEPTION
  WHEN MyException THEN
    ROLLBACK;
  WHEN OTHERS THEN
    P_Err_Msg := SQLERRM;
    ROLLBACK;
END auto_user_generation;
/
