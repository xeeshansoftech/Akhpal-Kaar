CREATE OR REPLACE PACKAGE PCKG_CDC_UIN_LOADER IS

  PROCEDURE READ_FILE(P_Line             VARCHAR2,
                      P_Line_No          NUMBER,
                      P_File_Type        CHAR DEFAULT 'CDC', -- 'CDC' or 'UIN'
                      P_Errmsg           OUT VARCHAR2);

  PROCEDURE LOAD_SINGLE_CGT(P_VCHR_DATE            DATE,
                            P_BATCH                NUMBER,
                            P_CONTRA_BOOK_TYPE     VARCHAR2,
                            P_CONTRA_GL_HEAD       VARCHAR2,
                            P_CONTRA_SL_CODE       VARCHAR2,
                            P_CONTRA_SL_TYPE       VARCHAR2,
                            P_VCHR_NARRATION       VARCHAR2,
                            P_CONTRA_NARRATION     VARCHAR2,
                            P_Logid                NUMBER,
                            P_Errmsg               OUT VARCHAR2);

  PROCEDURE ROLLBACK_CGT(P_BATCH_NO         NUMBER,
                         P_REVERSE_DELETE   CHAR,
                         P_VCHR_DATE_TYPE   CHAR,
                         P_VOUCHER_DATE     IN OUT DATE,
                         P_LOG_ID           NUMBER,
                         P_ErrMsg           OUT VARCHAR2);

  FUNCTION VOUCHER_REVERSAL(P_VOUCHER_ID       Gl_Forms.Gl_Voucher_No%Type,
                            P_REVERSE_DELETE   CHAR,
                            P_VCHR_DATE_TYPE   CHAR,
                            P_VOUCHER_DATE     IN OUT DATE ,
                            P_LOG_ID           NUMBER)
                            RETURN VARCHAR2;
END PCKG_CDC_UIN_LOADER;
/
CREATE OR REPLACE PACKAGE BODY PCKG_CDC_UIN_LOADER IS

  PROCEDURE READ_FILE(P_Line             VARCHAR2,
                      P_Line_No          NUMBER,
                      P_File_Type        CHAR DEFAULT 'CDC', -- 'CDC' or 'UIN'
                      P_Errmsg           OUT VARCHAR2) IS

    TYPE FIELDARRAY IS VARRAY(20) OF VARCHAR2(100);
    LineRead    VARCHAR2(2000);
    v_Str       Varchar2(200);
    FieldNumber NUMBER(8);
    DataArray   FIELDARRAY;
    len         number;

    v_Account_Code     Client.Client_code%type;
    v_client_code      Client.Client_code%type;
    v_Client_Name      Client.Client_name%type;
    --V_CNIC             client.comp_id_card_number%type;
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
      If FieldNumber > 3 Then
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

    If FieldNumber <> 3 Then
      P_Errmsg := 'Invalid File Format. Check Total No Of Fields.';
      Raise MyException;
    End if;

    v_Account_Code := Trim(DataArray(1));
    v_Amount       := ROUND(To_Number(DataArray(3)),2);

    -- Check Amount...
    IF nvl(v_amount,0) = 0 THEN
       P_Errmsg := 'Ignored client with 0 UIN/CDC charges.';
       RAISE MyException;
    END IF;
    
    IF upper(P_File_Type) = 'CDC' THEN
       -- check client...
        Begin
          Select c.Client_code, client_name, active
            into v_Client_code, v_client_name, v_Active
            From client c
           Where c.post = 1
             AND c.active = 1
             AND NVL(c.cdc_group_code, c.cdc_investor_code) = v_Account_Code
             AND rownum = 1;
        EXCEPTION
           WHEN no_data_found THEN
               BEGIN
                 -- Only In-Active clients...
                 Select c.Client_code, client_name, active
                   into v_Client_code, v_client_name, v_Active
                   From client c
                  Where c.post = 1
                    AND NVL(c.cdc_group_code, c.cdc_investor_code) = v_Account_Code
                    AND rownum = 1;
               EXCEPTION
                 WHEN no_data_found THEN
                    P_Errmsg := 'CDC Code ('||v_Account_Code||') Not Found.';
                    Raise MyException;
               END;
        END;
    ELSIF upper(P_File_Type) = 'UIN' THEN
        -- check client...
        Begin
          Select c.Client_code, client_name, active
            into v_Client_code, v_client_name, v_Active
            From client c
           Where c.post = 1
             AND c.active = 1
             AND c.client_code = v_Account_Code
             AND rownum = 1;
        EXCEPTION
           WHEN no_data_found THEN
               BEGIN
                 -- Only In-Active clients...
                 Select c.Client_code, client_name, active
                   into v_Client_code, v_client_name, v_Active
                   From client c
                  Where c.post = 1
                    AND c.client_code = v_Account_Code
                    AND rownum = 1;
               EXCEPTION
                 WHEN no_data_found THEN
                    P_Errmsg := 'Client Code ('||v_Account_Code||') Not Found.';
                    Raise MyException;
               END;
        END;
    END IF;

    -- Check Active Clients...
    IF v_Active = 0 THEN
       P_Errmsg := 'Client ('||v_Client_code||') is Closed/Inactive.';
       RAISE MyException;
    END IF;
    INSERT INTO TEMP_CGT_FILE(LINE_NO, FILE_LINE, CLIENT_CODE, CLIENT_NAME, UIN, AMOUNT, LOAD_CLIENT)
    VALUES(P_Line_No, P_Line, v_client_code, v_client_name, NULL, v_amount, 1);

    COMMIT;
  EXCEPTION
    WHEN MyException THEN
      Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
      VALUES (P_Line_no, SUBSTR(P_ErrMsg, 1, 500));
      Commit;
    WHEN OTHERS THEN
        Rollback;
        P_Errmsg := 'Un-Handeled Exception: '||SqlErrm;
        Insert into TEMP_INVALID_CGT_LOADER (LINE_NO, REMARKS)
        VALUES (P_Line_no, SUBSTR(P_ErrMsg, 1, 500));
        Commit;
  END READ_FILE;
  --================================
  PROCEDURE LOAD_SINGLE_CGT(P_VCHR_DATE            DATE,
                            P_BATCH                NUMBER,
                            P_CONTRA_BOOK_TYPE     VARCHAR2,
                            P_CONTRA_GL_HEAD       VARCHAR2,
                            P_CONTRA_SL_CODE       VARCHAR2,
                            P_CONTRA_SL_TYPE       VARCHAR2,
                            P_VCHR_NARRATION       VARCHAR2,
                            P_CONTRA_NARRATION     VARCHAR2,
                            P_Logid                NUMBER,
                            P_Errmsg               OUT VARCHAR2) IS

    v_Net_Amount       gl_bank_payments_det.amount%TYPE := 0;
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
    v_batch_type       cgt_batch.batch_type%TYPE;
    MyException        EXCEPTION;
    MyVchrException    EXCEPTION;
  BEGIN

    -- Batch Type....
    SELECT UNIQUE t.batch_type INTO v_batch_type FROM cgt_batch t WHERE t.batch_no = P_BATCH;

    -- CLIENT SL HEAD AND GLMF CODE
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
                       'GJV',
                       P_CONTRA_BOOK_TYPE);
    -- VOUCHER NUMBER
    Select Voucher_No_Seq.Nextval Into v_Voucher_no From dual;

    -- INSERT VOUCHER
    Begin
      Insert Into Gl_Forms
        (gl_voucher_no, financial_id, location_code, gl_form_type_code,
         gl_year, gl_month, gl_book_type, gl_form_no, gl_trans_type,
         gl_form_date, form_narration, post, log_id)
      Values
        (v_Voucher_no, v_Financial_id, v_Location_code, 'GJV',
         To_Number(To_Char(P_VCHR_DATE, 'RRRR')), To_Number(To_Char(P_VCHR_DATE, 'MM')),
         P_CONTRA_BOOK_TYPE, v_Form_no, v_gl_Trans_type, P_VCHR_DATE,
         v_batch_type||' DEDUCTION VOUCHER IMPORTED FROM FILE', 1, P_LogId);
      ------------------------------
      -- Pick data from TEMP_CGT_FILE...
      FOR REC IN (SELECT MAX(TF.LINE_NO) LINE_NO, TF.CLIENT_CODE, TF.CLIENT_NAME, TF.UIN, SUM(TF.AMOUNT) AMOUNT
                    FROM TEMP_CGT_FILE TF
                   WHERE TF.LOAD_CLIENT = 1
                   GROUP BY TF.CLIENT_CODE, TF.CLIENT_NAME, TF.UIN
                   ORDER BY LINE_NO)
      LOOP
          v_Line_No := REC.LINE_NO;

          -- Net Amount for Contra Head Entry...
          v_Net_Amount := v_Net_Amount + REC.AMOUNT;

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
          Insert Into Gl_Journal_Det
            (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
             Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
          Values
            (v_Voucher_no, v_Vchr_Line_No, c_Glmf_code, c_Sl_type, REC.CLIENT_CODE, Null, v_Cost_centre,
             'D', ABS(REC.AMOUNT), P_VCHR_NARRATION);
          -- CDC/UIN Batch File Entry...
          Insert into cgt_loader_batch (GL_VOUCHER_NO, BATCH_NO, CNIC, CLIENT_CODE, AMOUNT, VOUCHER_DATE, log_id, is_rollback)
          VALUES (v_Voucher_no, P_BATCH, NVL(REC.UIN, REC.CLIENT_CODE), REC.CLIENT_CODE, REC.AMOUNT, P_VCHR_DATE, P_Logid, 0);
          v_Vchr_Line_No := v_Vchr_Line_No + 1;

      END LOOP;

      --------------------------
      -- Contra Head Entry...
      --------------------------
      Insert Into Gl_Journal_Det
        (Gl_voucher_no, gl_jv_line_no, Gl_glmf_code, Gl_sl_type,
         Gl_sl_code, Clearing_no, Cost_centre, DC, Amount, Narration)
      Values
        (v_Voucher_no, v_Vchr_Line_No, P_CONTRA_GL_HEAD, P_CONTRA_SL_TYPE, P_CONTRA_SL_CODE, Null, v_Cost_centre,
         'C', ABS(v_Net_Amount), P_CONTRA_NARRATION);

      Insert into Gl_Journal_Mf (Gl_Voucher_No, Narration)
      VALUES (v_Voucher_no, P_CONTRA_NARRATION);

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
                         P_REVERSE_DELETE   CHAR, -- 'R' - Reversal, 'D' - Delete
                         P_VCHR_DATE_TYPE   CHAR, -- 'S' - For System Date, 'V' - For Voucher Date, 'O' - Other given in Voucher Date Parameter
                         P_VOUCHER_DATE     IN OUT DATE,
                         P_LOG_ID           NUMBER,
                         P_ErrMsg           OUT VARCHAR2) IS

    v_Status             VARCHAR2(1000);
    MyException          EXCEPTION;
  BEGIN
    FOR rec IN (SELECT unique clb.gl_voucher_no, clb.voucher_date
                  FROM cgt_loader_batch clb
                 WHERE clb.batch_no = P_BATCH_NO ORDER BY clb.gl_voucher_no ASC)
    LOOP
      v_status := VOUCHER_REVERSAL(rec.gl_voucher_no,
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
      P_ErrMsg := 'Error In UIN/CDC Rollback Process: '||SQLERRM;
  END ROLLBACK_CGT;
  --================================
  FUNCTION VOUCHER_REVERSAL(P_VOUCHER_ID       Gl_Forms.Gl_Voucher_No%Type,
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
    -- Returning Status
    RETURN(v_status);
  EXCEPTION
    WHEN OTHERS THEN
      v_status:= 'Exception faced while voucher reversal, obtained exception is: '||Sqlerrm;
      RETURN(v_status);
  END VOUCHER_REVERSAL;

END PCKG_CDC_UIN_LOADER;
/
