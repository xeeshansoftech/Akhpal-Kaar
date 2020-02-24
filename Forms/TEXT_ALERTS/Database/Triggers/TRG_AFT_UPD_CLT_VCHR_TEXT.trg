CREATE OR REPLACE TRIGGER TRG_AFT_UPD_CLT_VCHR_TEXT
AFTER UPDATE OF POST ON GL_FORMS
FOR EACH ROW

when (NEW.POST = 1)
DECLARE
   -- local variables...
   v_TEXT_id      NUMBER(12);
   v_text         TEXT_ALERTS_TEMPLATE.ALERT_BODY%TYPE;
   v_sys_date     DATE;
   v_sms_service  NUMBER(1);
   v_phone        client.phone_mobile%TYPE;
   v_Form_Type    gl_forms.gl_form_type_code%TYPE;
   v_qry          VARCHAR2(1000);
   TYPE v_ref_cursor IS REF CURSOR;
   TYPE rec           IS RECORD
   (gl_sl_code     VARCHAR2(100),
    amount         NUMBER(12,2),
    dc             CHAR(1)
   );
   v_vchr_cursor  v_ref_cursor;
   v_vchr_rec      rec;
   v_log_id				NUMBER(12);
   v_Active				TEXT_ALERTS_TEMPLATE.ALERT_ACTIVE%TYPE;
BEGIN
  
  BEGIN
		SELECT ALERT_ACTIVE INTO v_Active	FROM TEXT_ALERTS_TEMPLATE WHERE ALERT_ID = :NEW.gl_form_type_code;
	EXCEPTION WHEN OTHERS THEN
		V_ACTIVE := 0;
	END;	
	
	IF :OLD.POST <> 0 OR V_ACTIVE = 0 THEN
    RETURN;
  END IF;
	
  IF :NEW.gl_form_type_code = 'GJV' THEN
    v_qry := 'SELECT * FROM gl_journal_det d WHERE d.gl_voucher_no = '||:NEW.GL_VOUCHER_NO||' AND d.gl_sl_type = (SELECT Gl_Sl_Type_Client FROM SYSTEM)';
  ELSIF :NEW.gl_form_type_code = 'GBP' THEN
    v_qry := 'SELECT * FROM gl_bank_payments_det d WHERE d.gl_voucher_no = '||:NEW.GL_VOUCHER_NO||' AND d.gl_sl_type = (SELECT Gl_Sl_Type_Client FROM SYSTEM)';
  ELSIF :NEW.gl_form_type_code = 'GBR' THEN
    v_qry := 'SELECT * FROM gl_bank_receipts_det d WHERE d.gl_voucher_no = '||:NEW.GL_VOUCHER_NO||' AND d.gl_sl_type = (SELECT Gl_Sl_Type_Client FROM SYSTEM)';
  ELSIF :NEW.gl_form_type_code = 'GCP' THEN
    v_qry := 'SELECT * FROM gl_cash_payments_det d WHERE d.gl_voucher_no = '||:NEW.GL_VOUCHER_NO||' AND d.gl_sl_type = (SELECT Gl_Sl_Type_Client FROM SYSTEM)';
  ELSIF :NEW.gl_form_type_code = 'GCR' THEN
    v_qry := 'SELECT * FROM gl_cash_receipts_det d WHERE d.gl_voucher_no = '||:NEW.GL_VOUCHER_NO||' AND d.gl_sl_type = (SELECT Gl_Sl_Type_Client FROM SYSTEM)';
  END IF;

  OPEN v_vchr_cursor FOR v_qry;
  LOOP
       FETCH v_vchr_cursor INTO v_vchr_rec;
       EXIT WHEN v_vchr_cursor%NOTFOUND;

       BEGIN
           SELECT c.sms_service, c.phone_mobile INTO v_sms_service, v_phone
             FROM client c WHERE c.client_code = v_vchr_rec.GL_SL_CODE AND c.active = 1 AND c.post = 1;
       EXCEPTION
           WHEN OTHERS THEN
                v_sms_service := 0;
       END;

       IF (v_sms_service <> 0 AND v_phone IS NOT NULL) THEN
         SELECT T.ALERT_BODY INTO v_text FROM TEXT_ALERTS_TEMPLATE T WHERE T.ALERT_ID = v_Form_Type;
         SELECT REPLACE(v_text, 'P1', v_vchr_rec.GL_SL_CODE) INTO v_text FROM dual;
     		 SELECT REPLACE(v_text, 'P2', DECODE(v_vchr_rec.DC, 'D', 'Debited', 'Credited')) INTO v_text FROM dual;
     		 SELECT REPLACE(v_text, 'P3', v_vchr_rec.AMOUNT) INTO v_text FROM dual;

         SELECT TEXT_ALERTS_SEQ.NEXTVAL, s.system_date
             INTO v_TEXT_id, v_sys_date
             FROM SYSTEM s;

         INSERT INTO TEXT_ALERTS_LOG(TEXT_ID, TEXT_SENDER, TEXT_RECIEVER, TEXT_BODY, ALERT_ID, CLIENT_CODE, TIME_INSERT, TEXT_STATUS, LOG_ID, POST)
         VALUES(v_TEXT_id, NULL, v_phone, v_text, :NEW.gl_form_type_code, v_vchr_rec.GL_SL_CODE, v_sys_date, 'P', :NEW.LOG_ID, 1);
       END IF;
     END LOOP;
END TRG_AFT_UPD_CLT_VCHR_TEXT;
/
