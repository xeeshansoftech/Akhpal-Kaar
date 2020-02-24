create or replace function CALC_RMS_CLIENTS_TRADABLE_CASH(parm_loan_date     DATE,
                                                     parm_loan_id rms_clients_loan.rms_loan_id%TYPE,
                                                     parm_log_id  rms_clients_tradable_cash_log.log_id%Type)
  return varchar2 is
  v_status        VARCHAR2(500):= 'VALID';
  v_sqlerrm       varchar2(1000);
  v_exists        number := 0;
  v_client_code   rms_clients_loan.client_code%Type;
  v_loan_amnt     rms_clients_loan.loan_amount%Type;
  v_st_ex_code    rms_clients_tradable_cash.st_ex_code%Type;
  v_prev_TRADABLE_CASH rms_clients_tradable_cash.tradable_cash%Type;
  v_prev_LEDGER_CASH   rms_clients_tradable_cash.ledger_cash%Type;
  v_prev_PROJECTED_EX_WISE_CASH   rms_clients_tradable_cash.projected_ex_wise_cash%Type;
  v_prev_DEPOSITED_EX_WISE_CASH   rms_clients_tradable_cash.deposited_ex_wise_cash%Type;
begin
  Begin
    select rl.client_code, rl.loan_amount
      into v_client_code, v_loan_amnt
      from rms_clients_loan rl
     where rl.rms_loan_id = parm_loan_id
       and rl.loan_date = parm_loan_date;
  exception
    when others then
      null;
  end;
  Begin
    select rs.st_ex_code
      into v_st_ex_code
      from rms_day_stock_exchanges rs
     where rs.is_def_exchange = 1;
  exception
    when others then
      v_status := 'Default st_ex not found';
  end;
  Begin
    select count(*)
      into v_exists
      from rms_clients_tradable_cash rc
     where rc.client_code = v_client_code;
  exception
    when others then
      v_exists := 0;
  end;
  if v_exists > 0 then
    Begin
      select rc.tradable_cash,
             rc.ledger_cash,
             rc.projected_ex_wise_cash,
             rc.deposited_ex_wise_cash
        into v_prev_TRADABLE_CASH,
             v_prev_LEDGER_CASH,
             v_prev_PROJECTED_EX_WISE_CASH,
             v_prev_DEPOSITED_EX_WISE_CASH
        from rms_clients_tradable_cash rc
       where rc.client_code = v_client_code;
    exception
      when others then
        v_prev_TRADABLE_CASH          := 0;
        v_prev_LEDGER_CASH            := 0;
        v_prev_PROJECTED_EX_WISE_CASH := 0;
        v_prev_DEPOSITED_EX_WISE_CASH := 0;
    end;

    Begin
        update RMS_CLIENTS_TRADABLE_CASH set TRADABLE_CASH = TRADABLE_CASH + v_loan_amnt, LEDGER_CASH = LEDGER_CASH + v_loan_amnt, PROJECTED_EX_WISE_CASH = PROJECTED_EX_WISE_CASH + v_loan_amnt,
               DEPOSITED_EX_WISE_CASH = DEPOSITED_EX_WISE_CASH + v_loan_amnt
         Where Client_Code = v_client_code;
      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := trunc(Sqlerrm,1000);
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Update RMS_CLIENTS_TRADABLE_CASH, due to error :['||v_sqlerrm||']');
          End If;
      End;

      Begin
        Insert into RMS_CLIENTS_TRADABLE_CASH_LOG(RMS_CTC_LOG_ID,CTC_DATE,CLIENT_CODE, ST_EX_CODE,LOAN_AMOUNT,PREV_TRADABLE_CASH,PREV_LEDGER_CASH,PREV_PROJECTED_EX_WISE_CASH,PREV_DEPOSITED_EX_WISE_CASH,PREV_FUT_BLOCKED_CASH,PREV_READY_UNSETT_CASH,PREV_FPR_BASED_BLOCKED_CASH, TRADABLE_CASH, LEDGER_CASH, PROJECTED_EX_WISE_CASH,
                                              DEPOSITED_EX_WISE_CASH, FUT_BLOCKED_CASH, READY_UNSETT_CASH, FPR_BASED_BLOCKED_CASH,RMS_LOAN_ID,Log_Id)
                                              select SEQ_RMS_CTC_LOG.NEXTVAL,parm_loan_date,rc.client_code,rc.st_ex_code,v_loan_amnt,v_PREV_TRADABLE_CASH,v_PREV_LEDGER_CASH,v_PREV_PROJECTED_EX_WISE_CASH,v_PREV_DEPOSITED_EX_WISE_CASH,0,0,0, TRADABLE_CASH, LEDGER_CASH, PROJECTED_EX_WISE_CASH,
                                              DEPOSITED_EX_WISE_CASH, FUT_BLOCKED_CASH, READY_UNSETT_CASH, FPR_BASED_BLOCKED_CASH,parm_loan_id,parm_log_id from rms_clients_tradable_cash rc where rc.client_code = v_client_code;

      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := trunc(Sqlerrm,1000);
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Insert into RMS_CLIENTS_TRADABLE_CASH_LOG, due to error :['||v_sqlerrm||']');
          End If;
      End;
  else

    Begin
        Insert into RMS_CLIENTS_TRADABLE_CASH(CLIENT_CODE, ST_EX_CODE, TRADABLE_CASH, LEDGER_CASH, PROJECTED_EX_WISE_CASH,
                                              DEPOSITED_EX_WISE_CASH, FUT_BLOCKED_CASH, READY_UNSETT_CASH, FPR_BASED_BLOCKED_CASH)
                                              values(v_client_code,v_st_ex_code,v_loan_amnt,v_loan_amnt,v_loan_amnt,
                                              v_loan_amnt,0,0,0);

      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := trunc(Sqlerrm,1000);
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Insert into RMS_CLIENTS_TRADABLE_CASH, due to error :['||v_sqlerrm||']');
          End If;
      End;
      Begin
        Insert into RMS_CLIENTS_TRADABLE_CASH_LOG(RMS_CTC_LOG_ID,CTC_DATE,CLIENT_CODE, ST_EX_CODE,LOAN_AMOUNT,PREV_TRADABLE_CASH,PREV_LEDGER_CASH,PREV_PROJECTED_EX_WISE_CASH,PREV_DEPOSITED_EX_WISE_CASH,PREV_FUT_BLOCKED_CASH,PREV_READY_UNSETT_CASH,PREV_FPR_BASED_BLOCKED_CASH, TRADABLE_CASH, LEDGER_CASH, PROJECTED_EX_WISE_CASH,
                                              DEPOSITED_EX_WISE_CASH, FUT_BLOCKED_CASH, READY_UNSETT_CASH, FPR_BASED_BLOCKED_CASH,RMS_LOAN_ID,Log_Id)
                                              select SEQ_RMS_CTC_LOG.NEXTVAL,parm_loan_date,rc.client_code,rc.st_ex_code,v_loan_amnt,0,0,0,0,0,0,0, TRADABLE_CASH, LEDGER_CASH, PROJECTED_EX_WISE_CASH,
                                              DEPOSITED_EX_WISE_CASH, FUT_BLOCKED_CASH, READY_UNSETT_CASH, FPR_BASED_BLOCKED_CASH,parm_loan_id,parm_log_id from rms_clients_tradable_cash rc where rc.client_code = v_client_code;

      Exception
        When Others Then
          If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := trunc(Sqlerrm,1000);
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Insert into RMS_CLIENTS_TRADABLE_CASH_LOG, due to error :['||v_sqlerrm||']');
          End If;
      End;
   end if;
   IF v_status <> 'VALID' THEN
     Begin
       update rms_clients_loan rcl set rcl.executed = 1 where rcl.rms_loan_id = parm_loan_id;
     exception
       when others then
         If (Sqlcode Not Like '-0000') Then
            v_sqlerrm := trunc(Sqlerrm,1000);
            v_status := v_sqlerrm;
            Raise_Application_Error('-20001','System is unable to Update RMS_CLIENTS_LOAN, due to error :['||v_sqlerrm||']');
          End If;
     end;
   END IF;

  return(v_status);
exception
  When Others Then
    v_sqlerrm := trunc(Sqlerrm,1000);
    v_status := v_sqlerrm;
    return(v_status);
end CALC_RMS_CLIENTS_TRADABLE_CASH;
/
