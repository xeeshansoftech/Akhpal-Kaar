CREATE OR REPLACE PACKAGE PCKG_CGT_LOADER IS

  PROCEDURE READ_FILE(P_Line             VARCHAR2,
                      P_Line_No          NUMBER,
                      P_Start_date       DATE,
                      P_End_Date         DATE,
                      P_Errmsg           OUT VARCHAR2);

  PROCEDURE LOAD_MULTIPLE_CGT(P_VCHR_DATE        DATE,
                              P_CGT_BATCH        NUMBER,
                              P_DR_NARRATION     VARCHAR2,
                              P_CR_NARRATION     VARCHAR2,
                              P_CONTRA_NARRATION VARCHAR2,
                              P_Logid            NUMBER,
                              P_Errmsg           OUT VARCHAR2);

  PROCEDURE LOAD_SINGLE_CGT(P_VCHR_DATE        DATE,
                            P_CGT_BATCH        NUMBER,
                            P_DR_NARRATION     VARCHAR2,
                            P_CR_NARRATION     VARCHAR2,
                            P_CONTRA_NARRATION VARCHAR2,
                            P_Logid            NUMBER,
                            P_Errmsg           OUT VARCHAR2);

  PROCEDURE ROLLBACK_CGT(P_BATCH_NO         NUMBER,
                         P_REVERSE_DELETE   CHAR,
                         P_VCHR_DATE_TYPE   CHAR,
                         P_VOUCHER_DATE     IN OUT DATE,
                         P_LOG_ID           NUMBER,
                         P_ErrMsg           OUT VARCHAR2);

  FUNCTION VOUCHER_REVERSAL_DELETION(P_VOUCHER_ID       Gl_Forms.Gl_Voucher_No%Type,
                                     P_REVERSE_DELETE   CHAR,
                                     P_VCHR_DATE_TYPE   CHAR,
                                     P_VOUCHER_DATE     IN OUT DATE ,
                                     P_LOG_ID           NUMBER)
                                     RETURN VARCHAR2;
 PROCEDURE CGT_FEE_READ_FILE        (P_Line             VARCHAR2,
                                     P_Line_No          NUMBER,
                                     P_Errmsg           OUT VARCHAR2);
  PROCEDURE CGT_FEE_LOAD_SINGLE_CGT(P_VCHR_DATE        DATE,
                            P_CGT_BATCH        NUMBER,
                            P_DR_NARRATION     VARCHAR2,
                            P_CR_NARRATION     VARCHAR2,
                            P_Logid            NUMBER,
                            P_Errmsg           OUT VARCHAR2);
END PCKG_CGT_LOADER;
/
CREATE OR REPLACE PACKAGE BODY PCKG_CGT_LOADER IS
  --=============================================
  -- Package : pckg_cgt_loader
  -- Created By : Irfan Khan
  -- Last Modification Date : 12-JUN-2013
  -- Change : Batch_Type column removed from CGT_LOADER_BATCH table and included in a new table CGT_BATCH
  --=============================================
  PROCEDURE READ_FILE(P_Line             VARCHAR2,
                      P_Line_No          NUMBER,
                      P_Start_Date       DATE,
                      P_End_Date         DATE,
                      P_Errmsg           OUT VARCHAR2) IS

    TYPE FIELDARRAY IS VARRAY(20) OF VARCHAR2(100);
    LineRead    VARCHAR2(2000);
    v_Str       Varchar2(200);
    FieldNumber NUMBER(8);
    DataArray   FIELDARRAY;
    len         number;

    v_Client_Code      Client.Client_code %type;
    v_Client_Name      Client.Client_name %type;
    V_CNIC             client.comp_id_card_number%type;
    v_NIC_NAME         VARCHAR2(100);
    v_CR_amt           gl_bank_payments_det.amount%TYPE := 0;
    v_DR_amt           gl_bank_payments_det.amount%TYPE := 0;
    v_amount           gl_bank_payments_det.amount%TYPE := 0;
    v_Active           NUMBER(1) := 0;
    MyException        EXCEPTION;
  BEGIN

    LineRead    := P_Line;
    DataArray   := FIELDARRAY('', '', '', '', '', '', '', '', '', '',
                              '', '', '', '', '', '', '', '', '', '');
    FieldNumber := 0;

    WHILE (Nvl(Length(LineRead), 0) <> 0) LOOP

      FieldNumber := FieldNumber + 1;
      If FieldNumber > 20 Then
        P_Errmsg := 'Invalid File Format. Check Total No Of Fields.';
        Raise MyException;
      End if;

      if Instr(LineRead, ',', 1, 1) <> 0 then
        v_str := Substr(LineRead, 1, Instr(LineRead, ',', 1, 1)-1);
        len :=Length(v_str);
        LineRead := Substr(LineRead, nvl(Length(v_str),0) + 2, Length(LineRead));
        DataArray(FieldNumber) := REPLACE(TRIM(V_Str),'"','');
      else
       DataArray(FieldNumber) := REPLACE(TRIM(lineRead),'"','');
       lineRead:=null;
      end if;

    END LOOP;

    If FieldNumber <> 20 Then
      P_Errmsg := 'Invalid File Format. Check Total No Of Fields.';
      Raise MyException;
    End if;

    V_CNIC     := Trim(DataArray(3));
    v_NIC_NAME := SUBSTR(Trim(DataArray(4)),1,100);

    /*
    Previously 20th column (ASOF_REPORTING_MONTH_CGT SHORT_FALL) of the file was used as CGT Amount.
    Now as per the instructions of Shahid(KASB) in reference to NCCPL we are using
    17th column (ASOF_REPORTING_MONTH_NET_CGT_PAYABLE_REFUND) of the file as it contains
    both DR as well as CR entries for Deduction and Refund of CGT amount.
    */
    IF NVL(TO_NUMBER(DataArray(17)),0) > 0 THEN
       v_dr_amt := ABS(ROUND(To_Number(DataArray(17)),2));
       v_Amount := ROUND(To_Number(DataArray(17)),2);
    ELSE
      v_cr_amt := ABS(ROUND(To_Number(DataArray(17)),2));
      v_Amount := ROUND(To_Number(DataArray(17)),2);
    END IF;
    -- check client...
    BEGIN
      SELECT c.Client_code, client_name, active
        INTO v_Client_code, v_client_name, v_Active
        FROM client c, branch b, equity_system es, cost_centre cc
       WHERE c.post = 1
         AND c.active = 1
         and c.branch_code = b.branch_code
         and cc.branch_code = b.branch_code
         and cc.dept_code = es.equity_dept_code
         AND REPLACE(NVL(c.comp_id_card_number, c.id_card_number),'-','') = V_CNIC;
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        BEGIN
          SELECT C.CLIENT_CODE, CLIENT_NAME, ACTIVE
            INTO v_Client_code, v_client_name, v_Active
            FROM CLIENT C, branch b, equity_system es, cost_centre cc
           WHERE C.POST = 1
             AND C.ACTIVE = 1
             and c.branch_code = b.branch_code
             and cc.branch_code = b.branch_code
             and cc.dept_code = es.equity_dept_code
             AND REPLACE(NVL(C.COMP_ID_CARD_NUMBER, C.ID_CARD_NUMBER), '-', '') = V_CNIC
             AND C.CLIENT_CODE =
                 (SELECT WORK_POOL.CLIENT_CODE
                    FROM (SELECT ET.CLIENT_CODE, COUNT(ET.TRADE_NUMBER) TOTAL_TRADES
                            FROM EQUITY_TRADE ET, client ct
                           WHERE ET.CLIENT_CODE = ct.CLIENT_CODE
                             AND ET.TRADE_TYPE <> (SELECT COT_TRADE FROM EQUITY_SYSTEM)
                             AND ET.TRADE_TYPE <> (SELECT RELEASE_COT_TRADE FROM EQUITY_SYSTEM)
                             AND ET.POST = 1
                             AND et.trade_date BETWEEN P_Start_Date AND P_End_Date
                             AND REPLACE(NVL(ct.COMP_ID_CARD_NUMBER, ct.ID_CARD_NUMBER),
                                         '-',
                                         '') = V_CNIC
                           GROUP BY ET.CLIENT_CODE
                           ORDER BY 2 DESC) WORK_POOL
                   WHERE ROWNUM = 1);
        EXCEPTION
          WHEN OTHERS THEN
            null;
        END;
      WHEN NO_DATA_FOUND THEN
          BEGIN
             -- Only In-Active clients...
             Select c.Client_code, client_name, active
               into v_Client_code, v_client_name, v_Active
               From client c, branch b, equity_system es, cost_centre cc
              Where c.post = 1
              and c.branch_code = b.branch_code
              and cc.branch_code = b.branch_code
              and cc.dept_code = es.equity_dept_code
                AND REPLACE(c.id_card_number,'-','') = V_CNIC
                AND rownum = 1;
          EXCEPTION
             WHEN OTHERS THEN
                  P_Errmsg := 'UIN Not Found.';
                  INSERT INTO TEMP_INVALID_UIN(LINE_NO, UIN, UIN_NAME)
                  VALUES(P_Line_No, V_CNIC, v_NIC_NAME);
                  Raise MyException;
          END;
    END;
    -- Check Amount...
    IF nvl(v_amount,0) = 0 THEN
       P_Errmsg := 'Ignored client with 0 CGT amount.';
       RAISE MyException;
    END IF;
    -- Check Active Clients...
    IF v_Active = 0 THEN
       P_Errmsg := 'Client ('||v_Client_code||') is Closed/Inactive.';
       RAISE MyException;
    END IF;
    INSERT INTO TEMP_CGT_FILE(LINE_NO, FILE_LINE, CLIENT_CODE, CLIENT_NAME, UIN, AMOUNT, LOAD_CLIENT)
    VALUES(P_Line_No, P_Line, v_client_code, v_client_name, V_CNIC, v_amount, 1);

    -- Log CREDIT clients...
    IF v_CR_Amt > 0 THEN
       INSERT INTO TEMP_CREDIT_CLIENTS(LINE_NO, UIN, CLIENT_CODE)
       VALUES(P_Line_No, V_CNIC, v_Client_Code);
    END IF;
    COMMIT;
  EXCEPTION
    WHEN MyException THEN
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (P_Line_no, P_ErrMsg);
      Commit;
    WHEN OTHERS THEN
        Rollback;
        P_Errmsg := 'Un-Handeled Exception: '||SqlErrm;
        Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
        VALUES (P_Line_no, P_ErrMsg);
        Commit;
  END READ_FILE;
  --=======================
  PROCEDURE LOAD_MULTIPLE_CGT(P_VCHR_DATE        DATE,
                              P_CGT_BATCH        NUMBER,
                              P_DR_NARRATION     VARCHAR2,
                              P_CR_NARRATION     VARCHAR2,
                              P_CONTRA_NARRATION VARCHAR2,
                              P_Logid            NUMBER,
                              P_Errmsg           OUT VARCHAR2) IS

    V_Form_Type_Code   CGT_LOADER_CONFIGURATION.VOUCHER_TYPE%TYPE;
    V_CONTRA_BOOK_TYPE CGT_LOADER_CONFIGURATION.GL_BOOK_TYPE%TYPE;
    V_CONTRA_GL_HEAD   CGT_LOADER_CONFIGURATION.GL_GLMF_CODE%TYPE;
    V_CONTRA_SL_CODE   CGT_LOADER_CONFIGURATION.GL_SL_CODE%TYPE;
    V_CONTRA_SL_TYPE   CGT_LOADER_CONFIGURATION.GL_SL_TYPE%TYPE;
    V_CREDIT_CLIENT    CGT_LOADER_CONFIGURATION.Allow_Credit_Client%TYPE;
    v_CR_AMT           gl_bank_payments_det.amount%TYPE := 0;
    c_sl_type          system.gl_sl_type_client %type;
    c_glmf_code        gl_glmf.Gl_Glmf_Code %type;
    v_cost_centre      cost_centre.cost_centre %type;
    v_Voucher_no       Gl_forms.Gl_Voucher_No%type;
    v_gl_trans_type    equity_system.gl_trans_type %type;
    v_Financial_id     Financial_Years.Financial_Id%type;
    v_Location_code    Locations.Location_Code%type;
    v_Form_no          Gl_forms.gl_form_no%type;
    v_Line_No          TEMP_CGT_FILE.LINE_NO%TYPE;

    MyException        EXCEPTION;
    MyVchrException    EXCEPTION;
  BEGIN

    -- Fetch CGT Configurations...
    SELECT c.voucher_type, c.gl_book_type, c.gl_glmf_code, c.gl_sl_type,
           c.gl_sl_code, c.allow_credit_client
      INTO V_Form_Type_Code, V_CONTRA_BOOK_TYPE, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE,
           V_CONTRA_SL_CODE, V_CREDIT_CLIENT
      FROM cgt_loader_configuration c
     WHERE rownum = 1;
    -- CONTRA GL HEAD
    IF V_CONTRA_GL_HEAD IS NULL THEN
        Begin
          Select t.gl_glmf_code
            into V_CONTRA_GL_HEAD
            From gl_book_type t
           Where t.gl_book_type = V_CONTRA_BOOK_TYPE
             and t.gl_form_type_code = V_Form_Type_Code;
        Exception
          when no_data_found then
            P_Errmsg := 'GL Head not found against Book Type: ' || V_CONTRA_BOOK_TYPE;
            Raise MyException;
          When others then
            P_Errmsg := 'Error While Getting GL Head against Book Type: '|| V_CONTRA_BOOK_TYPE ||' '|| SqlErrm;
            RAISE MyException;
        End;
    END IF;
    --- CLIENT SL HEAD AND GLMF CODE
    Begin
      Select s.Gl_sl_type_client into c_Sl_type from System s;

      Select Gl_glmf_code
        into c_Glmf_code
        from gl_sl_type
       where gl_sl_type = c_sl_type;
    Exception
      When no_data_found then
        P_ErrMsg := 'Equity gl-code / client sl-type not defined. '||SqlErrm;
        RAISE MyException;
      When others then
        P_ErrMsg := 'Error while getting equity gl-code / client sl-type. '|| SqlErrm;
        RAISE MyException;
    End;

    -- GL TRANSACTION TYPE
    Begin
      select t.gl_trans_type into v_gl_trans_type from equity_system t;
    Exception
      When no_data_found then
        P_ErrMsg := 'GL Transaction Type is not defined in Equity System.';
        RAISE MyException;
    END;

    Begin
      ------------------------------
      -- Pick data from TEMP_CGT_FILE...
      FOR REC IN (SELECT * FROM TEMP_CGT_FILE WHERE load_client = 1 ORDER BY LINE_NO)
      LOOP
          v_Line_No := REC.LINE_NO;
          -- Check CREDIT ENTRY...
          IF REC.AMOUNT > 0 THEN
            v_CR_AMT := 0;
          ELSE
            v_CR_AMT := ABS(REC.AMOUNT);
          END IF;
          -- Check Credit Client...
          IF V_CREDIT_CLIENT = 0 AND v_CR_AMT > 0 THEN
            GOTO NEXT_LINE;
          END IF;
          -- COST CENTER
          Begin
            Select cc.cost_centre
              into v_cost_centre
              from cost_centre cc, branch b, equity_system es, client c
             Where c.branch_code = b.branch_code
               AND cc.branch_code = b.branch_code
               and cc.dept_code = es.equity_dept_code
               and c.client_code = REC.CLIENT_CODE;
          Exception
            When no_data_found then
              P_ErrMsg := 'Cost Centre not defined for client '||REC.CLIENT_CODE;
              RAISE MyException;
          End;
          -- VOUCHER DETAILS ENTRY
          v_Financial_id  := Voucher_Util.Get_Financial_Id(P_VCHR_DATE);
          v_Location_code := Voucher_Util.Get_Location_Code;
          v_Form_no       := Voucher_Util.Generate_Voucher_No(
                             v_financial_id,
                             To_Number(To_Char(P_VCHR_DATE,'RRRR')),
                             To_Number(To_Char(P_VCHR_DATE,'MM')),
                             V_Form_Type_Code,
                             V_CONTRA_BOOK_TYPE);
          -- VOUCHER NUMBER
          Select Voucher_No_Seq.Nextval Into v_Voucher_no From dual;

          -- INSERT VOUCHER
          Insert Into Gl_Forms
            (gl_voucher_no, financial_id, location_code, gl_form_type_code,
             gl_year, gl_month, gl_book_type, gl_form_no, gl_trans_type,
             gl_form_date, form_narration, post, log_id)
          Values
            (v_Voucher_no, v_Financial_id, v_Location_code, V_Form_Type_Code,
             To_Number(To_Char(P_VCHR_DATE, 'RRRR')), To_Number(To_Char(P_VCHR_DATE, 'MM')),
             V_CONTRA_BOOK_TYPE, v_Form_no, v_gl_Trans_type, P_VCHR_DATE,
             'CGT DEDUCTION VOUCHER IMPORTED FROM FILE', 1, P_LogId);

          If V_Form_Type_Code = 'GJV' then
            -- Client Entry...
            Insert Into Gl_Journal_Det
              (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
               Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, 1, c_Glmf_code, c_Sl_type, REC.CLIENT_CODE, Null, v_Cost_centre,
               decode(v_CR_Amt, 0, 'D', 'C'), ABS(REC.AMOUNT), decode(v_CR_Amt, 0, P_DR_NARRATION, P_CR_NARRATION));
            -- Contra Head Entry...
            Insert Into Gl_Journal_Det
              (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
               Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, 2, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE, V_CONTRA_SL_CODE, Null, v_Cost_centre,
               decode(v_CR_Amt, 0, 'C', 'D'), ABS(REC.AMOUNT), P_CONTRA_NARRATION);
            -- Master Table...
            Insert into Gl_Journal_Mf (Gl_Voucher_No, Narration)
            VALUES (v_Voucher_no, P_CONTRA_NARRATION);

          ElsIf V_Form_Type_Code = 'GBP' then
            -- Client Entry...
            Insert Into Gl_Bank_Payments_Det
              (Gl_voucher_no, Gl_bp_line_no, Gl_glmf_code, Gl_sl_type, Gl_sl_code,
               Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, 1, c_Glmf_code, c_Sl_type, REC.CLIENT_CODE, Null, v_Cost_centre,
               decode(v_CR_Amt, 0, 'D', 'C'), ABS(REC.AMOUNT), decode(v_CR_Amt, 0, P_DR_NARRATION, P_CR_NARRATION));
            -- Contra Head Entry...
            Insert Into Gl_Bank_Payments_Det
              (Gl_voucher_no, Gl_bp_line_no, Gl_glmf_code, Gl_sl_type, Gl_sl_code,
               Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, 2, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE, V_CONTRA_SL_CODE, Null, v_Cost_centre,
               decode(v_CR_Amt, 0, 'C', 'D'), ABS(REC.AMOUNT), P_CONTRA_NARRATION);
            -- Master Entry....
            Insert Into Gl_Bank_Payments_Mf(Gl_Voucher_No, Cheque_No, Gl_Received_By, Cheque_Date)
            VALUES(v_Voucher_no, v_Voucher_no, 'CGT AUTO GENERATED', P_VCHR_DATE);
          end if;
          -- CGT Batch File Entry...
          Insert into cgt_loader_batch (GL_VOUCHER_NO, BATCH_NO, CNIC, CLIENT_CODE, AMOUNT, VOUCHER_DATE, log_id, is_rollback)
          VALUES (v_Voucher_no, P_CGT_BATCH, REC.UIN, REC.CLIENT_CODE, REC.AMOUNT, P_VCHR_DATE, P_Logid, 0);
          <<NEXT_LINE>>
          NULL;
      END LOOP;
    Exception
      When Dup_val_on_index then
        P_ErrMsg := 'Duplicate values while inserting voucher detail. ' ||SqlErrm;
        RAISE MyVchrException;
      When Value_error then
        P_ErrMsg := 'Invalid values while inserting voucher.' ||SqlErrm;
        RAISE MyVchrException;
      When Others then
        P_ErrMsg := 'Error while inserting voucher detail. ' ||SqlErrm;
        RAISE MyVchrException;
    End;

    COMMIT;
  EXCEPTION
    WHEN MyException THEN
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (v_Line_No, P_ErrMsg);
      Commit;
    WHEN MyVchrException THEN
      Rollback;
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (v_Line_No, P_ErrMsg);
      Commit;
    WHEN OTHERS THEN
        Rollback;
        P_Errmsg := 'Un-Handeled Exception: '||SqlErrm;
        Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
        VALUES (v_Line_No, P_ErrMsg);
        Commit;
  END LOAD_MULTIPLE_CGT;
  --================================
  PROCEDURE LOAD_SINGLE_CGT(P_VCHR_DATE        DATE,
                            P_CGT_BATCH        NUMBER,
                            P_DR_NARRATION     VARCHAR2,
                            P_CR_NARRATION     VARCHAR2,
                            P_CONTRA_NARRATION VARCHAR2,
                            P_Logid            NUMBER,
                            P_Errmsg           OUT VARCHAR2) IS

    V_Form_Type_Code   CGT_LOADER_CONFIGURATION.VOUCHER_TYPE%TYPE;
    V_CONTRA_BOOK_TYPE CGT_LOADER_CONFIGURATION.GL_BOOK_TYPE%TYPE;
    V_CONTRA_GL_HEAD   CGT_LOADER_CONFIGURATION.GL_GLMF_CODE%TYPE;
    V_CONTRA_SL_CODE   CGT_LOADER_CONFIGURATION.GL_SL_CODE%TYPE;
    V_CONTRA_SL_TYPE   CGT_LOADER_CONFIGURATION.GL_SL_TYPE%TYPE;
    V_CREDIT_CLIENT    CGT_LOADER_CONFIGURATION.Allow_Credit_Client%TYPE;
    v_CR_AMT           gl_bank_payments_det.amount%TYPE := 0;
    v_Contra_CR_Amount gl_bank_payments_det.amount%TYPE := 0;
    v_Contra_DR_Amount gl_bank_payments_det.amount%TYPE := 0;
    c_sl_type          system.gl_sl_type_client %type;
    c_glmf_code        gl_glmf.Gl_Glmf_Code %type;
    v_cost_centre      cost_centre.cost_centre %type;
    v_Voucher_no       Gl_forms.Gl_Voucher_No%type;
    v_gl_trans_type    equity_system.gl_trans_type %type;
    v_Financial_id     Financial_Years.Financial_Id%type;
    v_Location_code    Locations.Location_Code%type;
    v_Form_no          Gl_forms.gl_form_no%type;
    v_Line_No          TEMP_CGT_FILE.LINE_NO%TYPE;
    v_Vchr_Line_No     gl_journal_det.gl_jv_line_no%TYPE := 1;

    MyException        EXCEPTION;
    MyVchrException    EXCEPTION;
  BEGIN
    -- Fetch CGT Configurations...
    SELECT c.voucher_type, c.gl_book_type, c.gl_glmf_code, c.gl_sl_type,
           c.gl_sl_code, c.allow_credit_client
      INTO V_Form_Type_Code, V_CONTRA_BOOK_TYPE, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE,
           V_CONTRA_SL_CODE, V_CREDIT_CLIENT
      FROM cgt_loader_configuration c
     WHERE rownum = 1;
    -- CONTRA GL HEAD
    IF V_CONTRA_GL_HEAD IS NULL THEN
        Begin
          Select t.gl_glmf_code
            into V_CONTRA_GL_HEAD
            From gl_book_type t
           Where t.gl_book_type = V_CONTRA_BOOK_TYPE
             and t.gl_form_type_code = V_Form_Type_Code;
        Exception
          when no_data_found then
            P_Errmsg := 'GL Head not found against Book Type: ' || V_CONTRA_BOOK_TYPE;
            Raise MyException;
          When others then
            P_Errmsg := 'Error While Getting GL Head against Book Type: '|| V_CONTRA_BOOK_TYPE ||' '|| SqlErrm;
            RAISE MyException;
        End;
    END IF;
    --- CLIENT SL HEAD AND GLMF CODE
    Begin
      Select s.Gl_sl_type_client into c_Sl_type from System s;

      Select Gl_glmf_code
        into c_Glmf_code
        from gl_sl_type
       where gl_sl_type = c_sl_type;
    Exception
      When no_data_found then
        P_ErrMsg := 'Equity gl-code / client sl-type not defined. '||SqlErrm;
        RAISE MyException;
      When others then
        P_ErrMsg := 'Error while getting equity gl-code / client sl-type. '|| SqlErrm;
        RAISE MyException;
    End;

    -- GL TRANSACTION TYPE
    Begin
      select t.gl_trans_type into v_gl_trans_type from equity_system t;
    Exception
      When no_data_found then
        P_ErrMsg := 'GL Transaction Type is not defined in Equity System.';
        RAISE MyException;
    END;

    -- VOUCHER DETAILS ENTRY
    v_Financial_id  := Voucher_Util.Get_Financial_Id(P_VCHR_DATE);
    v_Location_code := Voucher_Util.Get_Location_Code;
    v_Form_no       := Voucher_Util.Generate_Voucher_No(
                       v_financial_id,
                       To_Number(To_Char(P_VCHR_DATE,'RRRR')),
                       To_Number(To_Char(P_VCHR_DATE,'MM')),
                       V_Form_Type_Code,
                       V_CONTRA_BOOK_TYPE);
    -- VOUCHER NUMBER
    Select Voucher_No_Seq.Nextval Into v_Voucher_no From dual;

    -- INSERT VOUCHER
    Begin
      Insert Into Gl_Forms
        (gl_voucher_no, financial_id, location_code, gl_form_type_code,
         gl_year, gl_month, gl_book_type, gl_form_no, gl_trans_type,
         gl_form_date, form_narration, post, log_id)
      Values
        (v_Voucher_no, v_Financial_id, v_Location_code, V_Form_Type_Code,
         To_Number(To_Char(P_VCHR_DATE, 'RRRR')), To_Number(To_Char(P_VCHR_DATE, 'MM')),
         V_CONTRA_BOOK_TYPE, v_Form_no, v_gl_Trans_type, P_VCHR_DATE,
         'CGT DEDUCTION VOUCHER IMPORTED FROM FILE', 1, P_LogId);
      ------------------------------
      -- Pick data from TEMP_CGT_FILE...
      FOR REC IN (SELECT * FROM TEMP_CGT_FILE WHERE load_client = 1 ORDER BY LINE_NO)
      LOOP
          v_Line_No := REC.LINE_NO;
          -- Check CREDIT ENTRY...
          IF REC.AMOUNT > 0 THEN
            v_CR_AMT := 0;
          ELSE
            v_CR_AMT := ABS(REC.AMOUNT);
          END IF;

          -- Check Credit Client...
          IF V_CREDIT_CLIENT = 0 AND v_CR_AMT > 0 THEN
            GOTO NEXT_LINE;
          END IF;
          -- Net Amount for Contra Head Entry...
          IF v_CR_AMT > 0 THEN
             -- If client is CR then Contra Head will be DR by the same amount...
             v_Contra_DR_Amount := v_Contra_DR_Amount + ABS(REC.AMOUNT);
          ELSE
             -- If client is DR then Contra Head will be CR by the same amount...
             v_Contra_CR_Amount := v_Contra_CR_Amount + ABS(REC.AMOUNT);
          END IF;

          -- COST CENTER
          Begin
            Select cc.cost_centre
              into v_cost_centre
              from cost_centre cc, branch b, equity_system es, client c
             Where c.branch_code = b.branch_code
               AND cc.branch_code = b.branch_code
               and cc.dept_code = es.equity_dept_code
               and c.client_code = REC.CLIENT_CODE;
          Exception
            When no_data_found then
              P_ErrMsg := 'Cost Centre not defined for client '||REC.CLIENT_CODE;
              RAISE MyException;
          End;
          -- Client Entry...
          If V_Form_Type_Code = 'GJV' then
            Insert Into Gl_Journal_Det
              (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
               Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, c_Glmf_code, c_Sl_type, REC.CLIENT_CODE, Null, v_Cost_centre,
               decode(v_CR_Amt, 0, 'D', 'C'), ABS(REC.AMOUNT), decode(v_CR_Amt, 0, P_DR_NARRATION, P_CR_NARRATION));
          ElsIf V_Form_Type_Code = 'GBP' then
            Insert Into Gl_Bank_Payments_Det
              (Gl_voucher_no, Gl_bp_line_no, Gl_glmf_code, Gl_sl_type, Gl_sl_code,
               Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, c_Glmf_code, c_Sl_type, REC.CLIENT_CODE, Null, v_Cost_centre,
               decode(v_CR_Amt, 0, 'D', 'C'), ABS(REC.AMOUNT), decode(v_CR_Amt, 0, P_DR_NARRATION, P_CR_NARRATION));
          end if;
          -- CGT Batch File Entry...
          Insert into cgt_loader_batch (GL_VOUCHER_NO, BATCH_NO, CNIC, CLIENT_CODE, AMOUNT, VOUCHER_DATE, log_id, is_rollback)
          VALUES (v_Voucher_no, P_CGT_BATCH, REC.UIN, REC.CLIENT_CODE, REC.AMOUNT, P_VCHR_DATE, P_Logid, 0);
          v_Vchr_Line_No := v_Vchr_Line_No + 1;
          <<NEXT_LINE>>
          NULL;
      END LOOP;
      ------------------------------
      /*-- Check CREDIT ENTRY...
      IF v_Net_Amount > 0 THEN
        v_CR_AMT := 0;
      ELSE
        v_CR_AMT := v_Net_Amount;
      END IF;*/
      --------------------------
      -- Contra Head Entry...
      --------------------------
      -- Master Table....
      IF V_Form_Type_Code = 'GJV' THEN
        Insert into Gl_Journal_Mf (Gl_Voucher_No, Narration)
        VALUES (v_Voucher_no, P_CONTRA_NARRATION);
      ELSIF V_Form_Type_Code = 'GBP' THEN
        Insert Into Gl_Bank_Payments_Mf(Gl_Voucher_No, Cheque_No, Gl_Received_By, Cheque_Date)
        VALUES(v_Voucher_no, v_Voucher_no, 'CGT AUTO GENERATED', P_VCHR_DATE);
      END IF;
      -- Detail Table...
      IF v_Contra_CR_Amount > 0 THEN
          IF V_Form_Type_Code = 'GJV' THEN
            Insert Into Gl_Journal_Det
              (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
               Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE,
              V_CONTRA_SL_CODE, Null, v_Cost_centre, 'C', ABS(v_Contra_CR_Amount), P_CONTRA_NARRATION);
          ELSIF V_Form_Type_Code = 'GBP' THEN
            Insert Into Gl_Bank_Payments_Det
              (Gl_voucher_no, Gl_bp_line_no, Gl_glmf_code, Gl_sl_type, Gl_sl_code,
               Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE, V_CONTRA_SL_CODE,
               Null, v_Cost_centre, 'C', ABS(v_Contra_CR_Amount), P_CONTRA_NARRATION);
          END IF;
      END IF;
      IF v_Contra_DR_Amount > 0 THEN
          v_Vchr_Line_No := v_Vchr_Line_No + 1;
          IF V_Form_Type_Code = 'GJV' THEN
            Insert Into Gl_Journal_Det
              (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
               Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE,
              V_CONTRA_SL_CODE, Null, v_Cost_centre, 'D', ABS(v_Contra_DR_Amount), P_CONTRA_NARRATION);
          ELSIF V_Form_Type_Code = 'GBP' THEN
            Insert Into Gl_Bank_Payments_Det
              (Gl_voucher_no, Gl_bp_line_no, Gl_glmf_code, Gl_sl_type, Gl_sl_code,
               Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE, V_CONTRA_SL_CODE,
               Null, v_Cost_centre, 'D', ABS(v_Contra_DR_Amount), P_CONTRA_NARRATION);
          END IF;
      END IF;

    Exception
      When Dup_val_on_index then
        P_ErrMsg := 'Duplicate values while inserting voucher detail. ' ||SqlErrm;
        RAISE MyVchrException;
      When Value_error then
        P_ErrMsg := 'Invalid values while inserting voucher.' ||SqlErrm;
        RAISE MyVchrException;
      When Others then
        P_ErrMsg := 'Error while inserting voucher detail. ' ||SqlErrm;
        RAISE MyVchrException;
    End;

    COMMIT;
  EXCEPTION
    WHEN MyException THEN
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (v_Line_No, P_ErrMsg);
      Commit;
    WHEN MyVchrException THEN
      Rollback;
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (v_Line_No, P_ErrMsg);
      Commit;
    WHEN OTHERS THEN
        Rollback;
        P_Errmsg := 'Un-Handeled Exception: '||SqlErrm;
        Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
        VALUES (v_Line_No, P_ErrMsg);
        Commit;
  END LOAD_SINGLE_CGT;
  --================================
  PROCEDURE ROLLBACK_CGT(P_BATCH_NO         NUMBER,
                         P_REVERSE_DELETE   CHAR,
                         P_VCHR_DATE_TYPE   CHAR,
                         P_VOUCHER_DATE     IN OUT DATE,
                         P_LOG_ID           NUMBER,
                         P_ErrMsg           OUT VARCHAR2) IS

    /*
    P_REVERSE_DELETE   CHAR DEFAULT 'R', -- 'R' - Reversal, 'D' - Delete
    P_VCHR_DATE_TYPE   CHAR DEFAULT 'S', -- 'S' - For System Date, 'V' - For Voucher Date, 'O' - Other given in Voucher Date Parameter
    */
    v_Status             VARCHAR2(1000);
    MyException          EXCEPTION;
  BEGIN
    FOR rec IN (SELECT unique clb.gl_voucher_no, clb.voucher_date
                  FROM cgt_loader_batch clb
                 WHERE clb.batch_no = P_BATCH_NO ORDER BY clb.gl_voucher_no ASC)
    LOOP
      v_status := VOUCHER_REVERSAL_DELETION(rec.gl_voucher_no,
                                            P_REVERSE_DELETE,
                                            P_VCHR_DATE_TYPE,
                                            P_VOUCHER_DATE,
                                            P_LOG_ID);
      IF v_Status <> 'VALID' THEN
        P_ErrMsg := v_status;
        RAISE MyException;
      END IF;
    END LOOP;
    -- Mark btahc as being reversed/rollback....
    UPDATE cgt_loader_batch b
       SET b.is_rollback = 1
     WHERE b.batch_no = P_BATCH_NO;

  EXCEPTION
    WHEN MyException THEN
      ROLLBACK;
    WHEN OTHERS THEN
      ROLLBACK;
      P_ErrMsg := 'Error In CGT Rollback Process: '||SQLERRM;
  END ROLLBACK_CGT;
  --================================
  FUNCTION VOUCHER_REVERSAL_DELETION(P_VOUCHER_ID       Gl_Forms.Gl_Voucher_No%Type,
                                     P_REVERSE_DELETE   CHAR,
                                     P_VCHR_DATE_TYPE   CHAR,
                                     P_VOUCHER_DATE     IN OUT DATE,
                                     P_LOG_ID           NUMBER)
                                     RETURN VARCHAR2 IS

    v_status                   VARCHAR2(1000) := 'VALID';
    v_voucher_type             Gl_Form_Types.Gl_Form_Type_Code%Type;
    V_CONTRA_GL_HEAD           Gl_Forms.Gl_Book_Type%Type;
    v_month                    Gl_Forms.Gl_Month%Type;
    v_year                     Gl_Forms.Gl_Year%Type;
    v_vc_no                    Gl_Forms.Gl_Voucher_No%Type;
    v_form_no                  Gl_Forms.Gl_Form_No%Type;
    v_financial_id             Gl_Forms.Financial_Id%Type;
    v_Voucher_Date             DATE;
BEGIN

    IF (P_VCHR_DATE_TYPE = 'S') THEN -- If System Date
      v_Voucher_Date := Get_System_Date;
      -- Gathering voucher information;
      Select Financial_Id,Gl_Form_Type_Code,Gl_Book_Type, Voucher_No_Seq.Nextval
        Into v_financial_id, v_voucher_type,V_CONTRA_GL_HEAD, v_vc_no
        From Gl_Forms Gf Where Gf.Gl_Voucher_No = P_VOUCHER_ID;
    ELSIF (P_VCHR_DATE_TYPE = 'V') THEN -- If Voucher Date
      -- Gathering voucher information;
      Select Financial_Id,Gl_Form_Type_Code,Gl_Form_Date,Gl_Book_Type, Voucher_No_Seq.Nextval
        Into v_financial_id,v_voucher_type,v_Voucher_Date,V_CONTRA_GL_HEAD, v_vc_no
        From Gl_Forms Gf Where Gf.Gl_Voucher_No = P_VOUCHER_ID;
    ELSIF (P_VCHR_DATE_TYPE = 'O') THEN -- If Voucher Date
      v_Voucher_Date := P_VOUCHER_DATE;
      -- Gathering voucher information;
      Select Financial_Id,Gl_Form_Type_Code, Gl_Book_Type, Voucher_No_Seq.Nextval
        Into v_financial_id,v_voucher_type,V_CONTRA_GL_HEAD, v_vc_no
        From Gl_Forms Gf Where Gf.Gl_Voucher_No = P_VOUCHER_ID;
    END IF;
    --========================
    IF P_REVERSE_DELETE = 'D' THEN
        IF v_voucher_type = 'GJV' THEN
          -- If Deletion Of Voucher Then
          begin
            delete from gl_journal_mf where gl_voucher_no = P_VOUCHER_ID;
            delete from gl_journal_det where gl_voucher_no = P_VOUCHER_ID;
            delete from gl_forms where gl_voucher_no = P_VOUCHER_ID;
          exception
            when others then
              ROLLBACK;
              RETURN('Exception while deleting JV. Error: ' || sqlerrm);
          end;
        ELSE
          begin
            delete from gl_bank_payments_mf where gl_voucher_no = P_VOUCHER_ID;
            delete from gl_bank_payments_det where gl_voucher_no = P_VOUCHER_ID;
            delete from gl_forms where gl_voucher_no = P_VOUCHER_ID;
          exception
            when others then
              ROLLBACK;
              RETURN('Exception while deleting BPV. Error: ' || sqlerrm);
          end;
        END IF;
    ELSE
        v_year    := Voucher_Util.get_Year(v_Voucher_Date);
        v_month   := Voucher_Util.get_Month(v_Voucher_Date);
        v_form_no := Voucher_Util.generate_Voucher_No(v_financial_id,v_year,v_month,v_voucher_type,V_CONTRA_GL_HEAD);

        INSERT INTO Gl_Forms
          (Gl_Voucher_No,Financial_Id,Location_Code,
           Gl_Form_Type_Code,Gl_Year,Gl_Month,Gl_Book_Type,
           Gl_Form_No,Gl_Trans_Type,Gl_Form_Date,Form_Narration,
           Post,Log_Id)
        (SELECT v_vc_no,Financial_Id,Location_Code,
           Gl_Form_Type_Code,v_year,v_month,Gl_Book_Type,
           v_form_no,Gl_Trans_Type,v_Voucher_Date,'Reversal-'||Form_Narration,
           Post,P_LOG_ID
         FROM Gl_Forms Gf WHERE Gf.Gl_Voucher_No = P_VOUCHER_ID);
        -- Generate voucher details reversal on the basis of voucher type
        IF (v_voucher_type = 'GBP') THEN -- Bank Payment Voucher
          Insert Into Gl_Bank_Payments_Mf
          (Select v_vc_no,Null,Vcm.Gl_Received_By,Vcm.Cheque_Date From Gl_Bank_Payments_Mf Vcm Where Vcm.Gl_Voucher_No = P_VOUCHER_ID);
          -- Voucher details
          INSERT INTO Gl_Bank_Payments_Det(Gl_Voucher_No, Gl_Bp_Line_No, Gl_Glmf_Code, Gl_Sl_Type,
                      Gl_Sl_Code, Clearing_No, Cost_Centre, Dc, Amount, Narration)
            (SELECT v_vc_no,Gl_Bp_Line_No,Gl_Glmf_Code,
                    Gl_Sl_Type,Gl_Sl_Code,Clearing_No,Cost_Centre,
                    Decode(Dc,'C','D','C') Dc, Amount,
                    'Reversal-'||Narration
               FROM Gl_Bank_Payments_Det Vcd
              WHERE Vcd.Gl_Voucher_No = P_VOUCHER_ID);
        ELSIF (v_voucher_type = 'GJV') THEN -- General Jouranl Voucher
          INSERT INTO Gl_Journal_Mf
          (SELECT v_vc_no,Vcm.Narration FROM Gl_Journal_Mf Vcm WHERE Vcm.Gl_Voucher_No = P_VOUCHER_ID);
          -- Voucher details
          INSERT INTO Gl_Journal_Det(Gl_Voucher_No, Gl_Jv_Line_No, Gl_Glmf_Code, Gl_Sl_Type, Gl_Sl_Code,
                      Clearing_No, Cost_Centre, Cheque_No, Invoice_No, Dc, Amount, Narration)
            (SELECT v_vc_no,Gl_Jv_Line_No,Gl_Glmf_Code,
                    Gl_Sl_Type,Gl_Sl_Code,Clearing_No,Cost_Centre,
                    Cheque_No,Invoice_No,Decode(DC, 'C', 'D', 'C') Dc,
                    Amount,'Reversal-' || Narration
               FROM Gl_Journal_Det Vcd
              WHERE Vcd.Gl_Voucher_No = P_VOUCHER_ID);
        END IF; -- Voucher type check ends
    END IF;
    -- Returning Status
    RETURN(v_status);
  EXCEPTION
    WHEN OTHERS THEN
      v_status:= 'Exception faced while voucher reversal, obtained exception is: '||Sqlerrm;
      RETURN(v_status);
  END VOUCHER_REVERSAL_DELETION;
  ----------------------------
  PROCEDURE CGT_FEE_READ_FILE(P_Line             VARCHAR2,
                              P_Line_No          NUMBER,
                              P_Errmsg           OUT VARCHAR2) IS
    TYPE FIELDARRAY IS VARRAY(20) OF VARCHAR2(100);
    LineRead    VARCHAR2(2000);
    v_Str       Varchar2(200);
    FieldNumber NUMBER(8);
    DataArray   FIELDARRAY;
    len         number;
    v_Client_Code      Client.Client_code %type;
    v_Client_Name      Client.Client_name %type;
    V_CNIC             client.comp_id_card_number%type;
    v_NIC_NAME         VARCHAR2(100);
    v_amount           gl_bank_payments_det.amount%TYPE := 0;
    v_Active           NUMBER(1) := 0;
    MyException        EXCEPTION;
  BEGIN

    LineRead    := P_Line;
    DataArray   := FIELDARRAY('', '', '', '', '', '', '','', '', '', '', '', '', '');
    FieldNumber := 0;

    WHILE (Nvl(Length(LineRead), 0) <> 0) LOOP

      FieldNumber := FieldNumber + 1;
      If FieldNumber > 8 Then
        P_Errmsg := 'Invalid File Format. Check Total No Of Fields.';
        Raise MyException;
      End if;

      if Instr(LineRead, ',', 1, 1) <> 0 then
        v_str := Substr(LineRead, 1, Instr(LineRead, ',', 1, 1)-1);
        len   :=Length(v_str);
        LineRead := Substr(LineRead, nvl(Length(v_str),0) + 2, Length(LineRead));
        DataArray(FieldNumber) := REPLACE(TRIM(V_Str),'"','');
      else
       DataArray(FieldNumber) := REPLACE(TRIM(lineRead),'"','');
       lineRead:=null;
      end if;

    END LOOP;

    If FieldNumber < 8 Then
      P_Errmsg := 'Invalid File Format. Check Total No Of Fields.';
      Raise MyException;
    End if;

   --v_NIC_NAME  := SUBSTR(Trim(DataArray(2)),1,100);
   V_CNIC      := Trim(DataArray(3));
   V_AMOUNT    := ABS(ROUND(To_Number(DataArray(8)),2));

    -- Check Amount...
    IF nvl(v_amount,0) = 0 THEN
       P_Errmsg := 'Ignored client with 0 CGT Fee.';
       RAISE MyException;
    END IF;

    -- check client...
    BEGIN
      SELECT c.Client_code, client_name, active
        INTO v_Client_code, v_client_name, v_Active
        FROM client c, branch b, equity_system es, cost_centre cc
       WHERE c.post = 1
         AND c.active = 1
         and c.branch_code = b.branch_code
         and cc.branch_code = b.branch_code
         and cc.dept_code = es.equity_dept_code
         AND REPLACE(NVL(c.comp_id_card_number, c.id_card_number),'-','') = V_CNIC;
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        BEGIN
          SELECT C.CLIENT_CODE, CLIENT_NAME, ACTIVE
            INTO v_Client_code, v_client_name, v_Active
            FROM CLIENT C, branch b, equity_system es, cost_centre cc
           WHERE C.POST = 1
             AND C.ACTIVE = 1
             and c.branch_code = b.branch_code
             and cc.branch_code = b.branch_code
             and cc.dept_code = es.equity_dept_code
             AND REPLACE(NVL(C.COMP_ID_CARD_NUMBER, C.ID_CARD_NUMBER), '-', '') = V_CNIC
             AND C.CLIENT_CODE =
                 (SELECT WORK_POOL.CLIENT_CODE
                    FROM (SELECT ET.CLIENT_CODE, COUNT(ET.TRADE_NUMBER) TOTAL_TRADES
                            FROM EQUITY_TRADE ET, client ct
                           WHERE ET.CLIENT_CODE = ct.CLIENT_CODE
                             AND ET.TRADE_TYPE <> (SELECT COT_TRADE FROM EQUITY_SYSTEM)
                             AND ET.TRADE_TYPE <> (SELECT RELEASE_COT_TRADE FROM EQUITY_SYSTEM)
                             AND ET.POST = 1
                             AND (get_system_date - et.trade_date) BETWEEN 0 AND 180
                             AND REPLACE(NVL(ct.COMP_ID_CARD_NUMBER, ct.ID_CARD_NUMBER),
                                         '-',
                                         '') = V_CNIC
                           GROUP BY ET.CLIENT_CODE
                           ORDER BY 2 DESC) WORK_POOL
                   WHERE ROWNUM = 1);
        EXCEPTION
          WHEN OTHERS THEN
            null;
        END;
      WHEN NO_DATA_FOUND THEN
          BEGIN
             -- Only In-Active clients...
             Select c.Client_code, client_name, active
               into v_Client_code, v_client_name, v_Active
               From client c, branch b, equity_system es, cost_centre cc
              Where c.post = 1
              and c.branch_code = b.branch_code
              and cc.branch_code = b.branch_code
              and cc.dept_code = es.equity_dept_code
                AND REPLACE(c.id_card_number,'-','') = V_CNIC
                AND rownum = 1;
          EXCEPTION
             WHEN OTHERS THEN
                  P_Errmsg := 'UIN Not Found.';
                  INSERT INTO TEMP_INVALID_UIN(LINE_NO, UIN, UIN_NAME)
                  VALUES(P_Line_No, V_CNIC, v_NIC_NAME);
                  Raise MyException;
          END;
    END;

    -- Check Active Clients...
    IF v_Active = 0 THEN
       P_Errmsg := 'Client ('||v_Client_code||') is Closed/Inactive.';
       RAISE MyException;
    END IF;
    INSERT INTO TEMP_CGT_FILE(LINE_NO, FILE_LINE, CLIENT_CODE, CLIENT_NAME, UIN, AMOUNT, LOAD_CLIENT)
    VALUES(P_Line_No, P_Line, v_client_code, v_client_name, V_CNIC, v_amount, 1);
    COMMIT;
  EXCEPTION
    WHEN MyException THEN
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (P_Line_no, P_ErrMsg);
      Commit;
    WHEN OTHERS THEN
        Rollback;
        P_Errmsg := 'Un-Handeled Exception: '||SqlErrm;
        Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
        VALUES (P_Line_no, P_ErrMsg);
        Commit;
  END CGT_FEE_READ_FILE;
--================================
  PROCEDURE CGT_FEE_LOAD_SINGLE_CGT(
                            P_VCHR_DATE        DATE,
                            P_CGT_BATCH        NUMBER,
                            P_DR_NARRATION     VARCHAR2,
                            P_CR_NARRATION     VARCHAR2,
                            P_Logid            NUMBER,
                            P_Errmsg           OUT VARCHAR2) IS

    V_Form_Type_Code   CGT_LOADER_CONFIGURATION.VOUCHER_TYPE%TYPE;
    V_CONTRA_BOOK_TYPE CGT_LOADER_CONFIGURATION.GL_BOOK_TYPE%TYPE;
    V_CONTRA_GL_HEAD   CGT_LOADER_CONFIGURATION.GL_GLMF_CODE%TYPE;
    V_CONTRA_SL_CODE   CGT_LOADER_CONFIGURATION.GL_SL_CODE%TYPE;
    V_CONTRA_SL_TYPE   CGT_LOADER_CONFIGURATION.GL_SL_TYPE%TYPE;
    V_CONTRA_COST_CENTER COST_CENTRE.COST_CENTRE %TYPE;
    V_DR_AMT           GL_BANK_PAYMENTS_DET.AMOUNT%TYPE := 0;
    V_CR_AMT           GL_BANK_PAYMENTS_DET.AMOUNT%TYPE := 0;
    c_sl_type          system.gl_sl_type_client %type;
    c_glmf_code        gl_glmf.Gl_Glmf_Code %type;
    v_cost_centre      cost_centre.cost_centre %type;
    v_Voucher_no       Gl_forms.Gl_Voucher_No%type;
    v_gl_trans_type    equity_system.gl_trans_type %type;
    v_Financial_id     Financial_Years.Financial_Id%type;
    v_Location_code    Locations.Location_Code%type;
    v_Form_no          Gl_forms.gl_form_no%type;
    v_Line_No          TEMP_CGT_FILE.LINE_NO%TYPE;
    v_Vchr_Line_No     gl_journal_det.gl_jv_line_no%TYPE := 1;
    MyException        EXCEPTION;
    MyVchrException    EXCEPTION;
  BEGIN
    -- Fetch CGT Configurations...
    BEGIN
        SELECT C.VOUCHER_TYPE, C.GL_BOOK_TYPE, C.CGT_FEE_GL_CODE, C.CGT_FEE_SL_TYPE,
               C.CGT_FEE_SL_CODE
          INTO V_FORM_TYPE_CODE, V_CONTRA_BOOK_TYPE, V_CONTRA_GL_HEAD, V_CONTRA_SL_TYPE,
               V_CONTRA_SL_CODE
          FROM CGT_LOADER_CONFIGURATION C
         WHERE ROWNUM = 1;
    EXCEPTION WHEN OTHERS THEN
    P_ErrMsg := 'Error while getting GL Head/Voucher Type from CGT Configuration';
    RAISE MyException;
    END;
    
    -- Check for Data Existance...
    IF V_Form_Type_Code IS NULL THEN
      P_Errmsg := 'Missing CGT Configuration. Please select Voucher Type.';
      RAISE MyException;
    ELSIF V_CONTRA_BOOK_TYPE IS NULL THEN
      P_Errmsg := 'Missing CGT Configuration. Please select Book Type.';
      RAISE MyException;
    ELSIF V_CONTRA_GL_HEAD IS NULL THEN
      P_Errmsg := 'Missing CGT FEE Configuration. Please select GL Head.'; 
      RAISE MyException;
    ELSIF V_CONTRA_SL_TYPE IS NOT NULL AND V_CONTRA_SL_CODE IS NULL THEN
      P_Errmsg := 'Missing CGT FEE Configuration. Please select SL Head.';   
      RAISE MyException;
    END IF;        
    
    -- CONTRA COST CENTER
    BEGIN
        SELECT CC.COST_CENTRE INTO V_CONTRA_COST_CENTER
        FROM
        LOCATIONS LOC,SYSTEM SYS,COST_CENTRE CC,EQUITY_SYSTEM EQ
        WHERE LOC.LOCATION_CODE = SYS.LOCATION_CODE
        AND   LOC.BRANCH_CODE   = CC.BRANCH_CODE
        AND   EQ.EQUITY_DEPT_CODE = CC.DEPT_CODE;
    EXCEPTION WHEN OTHERS THEN
    P_ErrMsg := 'Error while getting System Cost Center';
    RAISE MyException;
    END;

    --- CLIENT SL HEAD AND GLMF CODE
    Begin
      Select s.Gl_sl_type_client into c_Sl_type from System s;

      Select Gl_glmf_code
        into c_Glmf_code
        from gl_sl_type
       where gl_sl_type = c_sl_type;
    Exception
      When no_data_found then
        P_ErrMsg := 'Equity gl-code / client sl-type not defined. '||SqlErrm;
        RAISE MyException;
      When others then
        P_ErrMsg := 'Error while getting equity gl-code / client sl-type. '|| SqlErrm;
        RAISE MyException;
    End;

    -- GL TRANSACTION TYPE
    Begin
      select t.gl_trans_type into v_gl_trans_type from equity_system t;
    Exception
      When no_data_found then
        P_ErrMsg := 'GL Transaction Type is not defined in Equity System.';
        RAISE MyException;
    END;

    -- VOUCHER DETAILS ENTRY
    v_Financial_id  := Voucher_Util.Get_Financial_Id(P_VCHR_DATE);
    v_Location_code := Voucher_Util.Get_Location_Code;
    v_Form_no       := Voucher_Util.Generate_Voucher_No(
                       v_financial_id,
                       To_Number(To_Char(P_VCHR_DATE,'RRRR')),
                       To_Number(To_Char(P_VCHR_DATE,'MM')),
                       V_Form_Type_Code,
                       V_CONTRA_BOOK_TYPE);
    -- VOUCHER NUMBER
    Select Voucher_No_Seq.Nextval Into v_Voucher_no From dual;

    -- INSERT VOUCHER
    Begin
      Insert Into Gl_Forms
        (gl_voucher_no, financial_id, location_code, gl_form_type_code,
         gl_year, gl_month, gl_book_type, gl_form_no, gl_trans_type,
         gl_form_date, form_narration, post, log_id)
      Values
        (v_Voucher_no, v_Financial_id, v_Location_code, V_Form_Type_Code,
         To_Number(To_Char(P_VCHR_DATE, 'RRRR')), To_Number(To_Char(P_VCHR_DATE, 'MM')),
         V_CONTRA_BOOK_TYPE, v_Form_no, v_gl_Trans_type, P_VCHR_DATE,
         'CGT FEE DEDUCTION VOUCHER IMPORTED FROM FILE', 1, P_LogId);
      ---- Getting Credit Amount
      SELECT SUM(AMOUNT) INTO V_CR_AMT FROM TEMP_CGT_FILE WHERE LOAD_CLIENT = 1;
      -- Pick data from TEMP_CGT_FILE...
      FOR REC IN (SELECT * FROM TEMP_CGT_FILE WHERE load_client = 1 ORDER BY LINE_NO)
      LOOP
          v_Line_No := REC.LINE_NO;
          -- Check CREDIT ENTRY...
          IF REC.AMOUNT > 0 THEN
            V_DR_AMT := 0;
          ELSE
            V_DR_AMT := ABS(REC.AMOUNT);
          END IF;

         -- COST CENTER
          Begin
            Select cc.cost_centre
              into v_cost_centre
              from cost_centre cc, branch b, equity_system es, client c
             Where c.branch_code  = b.branch_code
               AND cc.branch_code = b.branch_code
               and cc.dept_code   = es.equity_dept_code
               and c.client_code  = REC.CLIENT_CODE;
          Exception
            When no_data_found then
              P_ErrMsg := 'Cost Centre not defined for client '||REC.CLIENT_CODE;
              RAISE MyException;
          End;
          -- Client Entry...
          If V_Form_Type_Code = 'GJV' then
            Insert Into Gl_Journal_Det
              (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
               Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, c_Glmf_code, c_Sl_type, REC.CLIENT_CODE, Null, v_Cost_centre,
               'D', ABS(REC.AMOUNT), P_DR_NARRATION);
          ElsIf V_Form_Type_Code = 'GBP' then
            Insert Into Gl_Bank_Payments_Det
              (Gl_voucher_no, Gl_bp_line_no, Gl_glmf_code, Gl_sl_type, Gl_sl_code,
               Clearing_no, Cost_centre, DC, Amount, Narration)
            Values
              (v_Voucher_no, v_Vchr_Line_No, c_Glmf_code, c_Sl_type, REC.CLIENT_CODE, Null, v_Cost_centre,
               'D', ABS(REC.AMOUNT), P_DR_NARRATION);
          end if;
          -- CGT Batch File Entry...
          Insert into cgt_loader_batch (GL_VOUCHER_NO, BATCH_NO, CNIC, CLIENT_CODE, AMOUNT, VOUCHER_DATE, log_id, is_rollback)
          VALUES (v_Voucher_no, P_CGT_BATCH, REC.UIN, REC.CLIENT_CODE, REC.AMOUNT, P_VCHR_DATE, P_Logid, 0);
          v_Vchr_Line_No := v_Vchr_Line_No + 1;
      END LOOP;
      ------------------------------
      -- CGT CREDIT ENTRY
      If V_Form_Type_Code = 'GJV' then
        Insert Into Gl_Journal_Det
          (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
           Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
        Values
          (v_Voucher_no, v_Vchr_Line_No, V_CONTRA_GL_HEAD,V_CONTRA_SL_TYPE ,V_CONTRA_SL_CODE, Null, V_CONTRA_COST_CENTER,
           'C', ABS(V_CR_AMT),P_CR_NARRATION);
           ---
           Insert into Gl_Journal_Mf (Gl_Voucher_No, Narration)
           VALUES (v_Voucher_no, P_CR_NARRATION);
      ElsIf V_Form_Type_Code = 'GBP' then
        Insert Into Gl_Bank_Payments_Det
          (Gl_voucher_no, Gl_bp_line_no, Gl_glmf_code, Gl_sl_type, Gl_sl_code,
           Clearing_no, Cost_centre, DC, Amount, Narration)
          Values
          (v_Voucher_no, v_Vchr_Line_No, V_CONTRA_GL_HEAD,V_CONTRA_SL_TYPE ,V_CONTRA_SL_CODE, Null, V_CONTRA_COST_CENTER,
           'C', ABS(V_CR_AMT), P_CR_NARRATION);
           ------
           Insert Into Gl_Bank_Payments_Mf(Gl_Voucher_No, Cheque_No, Gl_Received_By, Cheque_Date)
           VALUES(v_Voucher_no, v_Voucher_no, P_CR_NARRATION, P_VCHR_DATE);
      end if;
    Exception
      When Dup_val_on_index then
        P_ErrMsg := 'Duplicate values while inserting voucher detail. ' ||SqlErrm;
        RAISE MyVchrException;
      When Value_error then
        P_ErrMsg := 'Invalid values while inserting voucher.' ||SqlErrm;
        RAISE MyVchrException;
      When Others then
        P_ErrMsg := 'Error while inserting voucher detail. ' ||SqlErrm;
        RAISE MyVchrException;
    End;

    COMMIT;
  EXCEPTION
    WHEN MyException THEN
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (v_Line_No, P_ErrMsg);
      Commit;
    WHEN MyVchrException THEN
      Rollback;
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (v_Line_No, P_ErrMsg);
      Commit;
    WHEN OTHERS THEN
        Rollback;
        P_Errmsg := 'Un-Handeled Exception: '||SqlErrm;
        Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
        VALUES (v_Line_No, P_ErrMsg);
        Commit;
  END CGT_FEE_LOAD_SINGLE_CGT;
  --=======================
END PCKG_CGT_LOADER;
/
