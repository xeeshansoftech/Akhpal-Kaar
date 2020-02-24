delete from cgt_opening
/
delete from cgt_buy_sell_reference
/
delete from cgt_sell_det
/
delete from cgt_buy_det
/
commit
/
DECLARE
       v_err_msg  varchar2(500);
BEGIN

    PCKG_CGT_UTILITY.CGT_OPENING(P_Client_code => 'ALL');
    dbms_output.put_line('Process Executed Successfully.');	
EXCEPTION
 WHEN OTHERS THEN 
      dbms_output.put_line('Process Failed: '||v_Err_Msg);
END;
/
