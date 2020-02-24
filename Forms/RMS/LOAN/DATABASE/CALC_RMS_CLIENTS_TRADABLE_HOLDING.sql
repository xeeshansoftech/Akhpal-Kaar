create or replace function CALC_RMS_CLIENTS_TR_HOLDING(parm_loan_date     DATE,
                                                     parm_loan_id rms_cust_clients_loan.rms_cust_loan_id%TYPE,
                                                     parm_log_id  rms_clients_tr_holding_log.log_id%Type)
  return varchar2 is
  v_status        VARCHAR2(500):= 'VALID';
  v_sqlerrm       varchar2(1000);
  v_exists        number := 0;
  v_client_code   rms_cust_clients_loan.client_code%Type;
  v_loan_volume   rms_cust_clients_loan.loan_volume%Type;
  v_loan_isin     rms_cust_clients_loan.isin%Type;
  v_settlement_date    rms_client_tradable_holding.settlement_date%Type;
  v_security_name      rms_client_tradable_holding.security_name%Type;
  v_symbol             rms_client_tradable_holding.symbol%Type;
  v_prev_loan_volume   rms_cust_clients_loan.loan_volume%Type;
  v_prev_settlement_date   rms_cust_clients_loan.settlement_date%Type;  
begin
  Begin
    select rl.client_code, rl.isin,rl.loan_volume,rl.settlement_date
      into v_client_code, v_loan_isin, v_loan_volume, v_settlement_date
      from rms_cust_clients_loan rl
     where rl.rms_cust_loan_id = parm_loan_id
       and rl.loan_date = parm_loan_date;
  exception
    when others then
      null;
  end;
  Begin
    select rs.security_name, rs.symbol
      into v_security_name, v_symbol
      from security rs
     where rs.isin = v_loan_isin;
  exception
    when others then
      v_status := 'Symbol agianst ISIN not found';
  end;
  Begin
    select count(*)
      into v_exists
      from rms_client_tradable_holding rc
     where rc.client_code = v_client_code
     and rc.security_code = v_loan_isin;
  exception
    when others then
      v_exists := 0;
  end;
  if v_exists > 0 then
    Begin
      select rc.holding, rc.settlement_date
        into v_prev_loan_volume, v_prev_settlement_date
        from rms_client_tradable_holding rc
       where rc.client_code = v_client_code
       and rc.security_code = v_loan_isin;
    exception
      when others then
        v_prev_loan_volume          := 0;
    end;

    Begin
        update Rms_Client_Tradable_Holding set HOLDING = HOLDING + v_loan_volume
         Where Client_Code = v_client_code
         and SECURITY_CODE = v_loan_isin;
      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := Sqlerrm;
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Update Rms_Client_Tradable_Holding, due to error :['||v_sqlerrm||']');
          End If;
      End;

      Begin
        Insert into RMS_CLIENTS_TR_HOLDING_LOG
          (RMS_CTH_LOG_ID,
           CTH_DATE,
           CLIENT_CODE,
           ISIN,
           LOAN_VOLUME,
           PREV_TRADABLE_HOLDING,
           SETTLEMENT_DATE,
           RMS_CUST_LOAN_ID,
           Log_Id)
          select SEQ_RMS_CTH_LOG.NEXTVAL,
                 parm_loan_date,
                 rc.client_code,
                 rc.security_code,
                 v_loan_volume,
                 v_prev_loan_volume,
                 v_prev_settlement_date,
                 parm_loan_id,
                 parm_log_id
            from rms_client_tradable_holding rc
           where rc.client_code = v_client_code
             and rc.security_code = v_loan_isin;

      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := Sqlerrm;
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Insert into RMS_CLIENTS_TR_HOLDING_LOG, due to error :['||v_sqlerrm||']');
          End If;
      End;
  else

    Begin
        Insert into Rms_Client_Tradable_Holding
          (CLIENT_CODE,
           SECURITY_CODE,
           SECURITY_NAME,
           SYMBOL,
           SETTLEMENT_DATE,
           PENDING_ORDER,
           HOLDING,
           VAL_PERC)
        values
          (v_client_code,
           v_loan_isin,
           v_security_name,
           v_symbol,
           v_settlement_date,
           0,
           v_loan_volume,
           0);

      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := Sqlerrm;
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Insert into Rms_Client_Tradable_Holding, due to error :['||v_sqlerrm||']');
          End If;
      End;
      Begin
        Insert into RMS_CLIENTS_TR_HOLDING_LOG
          (RMS_CTH_LOG_ID,
           CTH_DATE,
           CLIENT_CODE,
           ISIN,
           LOAN_VOLUME,
           PREV_TRADABLE_HOLDING,
           SETTLEMENT_DATE,
           RMS_CUST_LOAN_ID,
           Log_Id)
        values
          (SEQ_RMS_CTH_LOG.NEXTVAL,
           parm_loan_date,
           v_client_code,
           v_loan_isin,
           v_loan_volume,
           0,
           v_settlement_date,
           parm_loan_id,
           parm_log_id);

      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := Sqlerrm;
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Insert into RMS_CLIENTS_TR_HOLDING_LOG, due to error :['||v_sqlerrm||']');
          End If;
      End;
   end if;
   IF v_status <> 'VALID' THEN
     Begin
       update rms_cust_clients_loan rcl set rcl.executed = 1 where rcl.rms_cust_loan_id = parm_loan_id;
     exception
       when others then
         If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := Sqlerrm;
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Update RMS_CUST_CLIENTS_LOAN, due to error :['||v_sqlerrm||']');
          End If;
     end;
   END IF;

  return(v_status);
exception
  When Others Then
    v_sqlerrm := Sqlerrm;
    v_status := v_sqlerrm;
    return(v_status);
end CALC_RMS_CLIENTS_TR_HOLDING;
/
