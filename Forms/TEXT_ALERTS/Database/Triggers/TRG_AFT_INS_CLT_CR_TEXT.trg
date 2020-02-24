CREATE OR REPLACE TRIGGER TRG_AFT_INS_CLT_CR_TEXT
AFTER INSERT ON GL_CASH_RECEIPTS_DET
FOR EACH ROW
DECLARE
   -- local variables...
   v_TEXT_id      NUMBER(12);
   v_text         TEXT_ALERTS_TEMPLATE.ALERT_BODY%TYPE;
   v_sys_date     DATE;
   v_sms_service  NUMBER(1);
   v_phone        client.phone_mobile%TYPE;
   v_post         NUMBER(1);
   v_log_id       NUMBER(12);
   v_Active				TEXT_ALERTS_TEMPLATE.ALERT_ACTIVE%TYPE;
BEGIN

  BEGIN
		SELECT ALERT_ACTIVE INTO V_ACTIVE FROM TEXT_ALERTS_TEMPLATE WHERE ALERT_ID = 'GCR';
	EXCEPTION WHEN OTHERS THEN
		V_ACTIVE := 0;
	END;	
	
	IF V_ACTIVE = 1 THEN

	  BEGIN
	    SELECT c.sms_service, c.phone_mobile INTO v_sms_service, v_phone
	      FROM client c WHERE c.client_code = :NEW.GL_SL_CODE;
	
	    SELECT post, log_id INTO v_post, v_log_id FROM gl_forms f WHERE f.gl_voucher_no = :NEW.GL_VOUCHER_NO;
	  EXCEPTION
	    WHEN OTHERS THEN
	         v_sms_service := 0;
	         v_post := 0;
	  END;
	
	  IF (v_post = 1 AND v_sms_service <> 0 AND v_phone IS NOT NULL) THEN
	     SELECT T.ALERT_BODY INTO v_text FROM TEXT_ALERTS_TEMPLATE T WHERE T.ALERT_ID = 'GCR';
	     SELECT REPLACE(v_text, 'P1', :NEW.GL_SL_CODE) INTO v_text FROM dual;
	     SELECT REPLACE(v_text, 'P2', DECODE(:NEW.DC, 'D', 'Debited', 'Credited')) INTO v_text FROM dual;
	     SELECT REPLACE(v_text, 'P3', :NEW.AMOUNT) INTO v_text FROM dual;
	
	     SELECT TEXT_ALERTS_SEQ.NEXTVAL, s.system_date
	         INTO v_TEXT_id, v_sys_date
	         FROM SYSTEM s;
	
	       INSERT INTO TEXT_ALERTS_LOG(TEXT_ID, TEXT_SENDER, TEXT_RECIEVER, TEXT_BODY, ALERT_ID, CLIENT_CODE, TIME_INSERT, TEXT_STATUS, LOG_ID, POST)
	       VALUES(v_TEXT_id, NULL, v_phone, v_text, 'GCR', :NEW.GL_SL_CODE, v_sys_date, 'P', V_LOG_ID, 1);
	  END IF;
  END IF;
END TRG_AFT_INS_CLT_CR_TEXT;
/