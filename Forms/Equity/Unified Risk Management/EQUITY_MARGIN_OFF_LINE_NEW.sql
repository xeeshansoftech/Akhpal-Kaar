CREATE OR REPLACE PROCEDURE EQUITY_MARGIN_OFF_LINE_NEW(PS_BRANCH VARCHAR2,
                                                       PS_USER_BRANCH VARCHAR2,
                                                       VCLIENT VARCHAR2,
                                                       VFROM_DATE DATE,
                                                       VTO_DATE DATE,
                                                       PS_FUTURE_NORMAL VARCHAR2,
                                                       COT_ACCOUNT_MERGE VARCHAR2,
                                                       P_MARGIN_APPLICABLE VARCHAR2,
                                                       PS_ON_OFF_CLIENT VARCHAR2,
                                                       V_MARGIN_PERC    VARCHAR2,
                                                       V_CUSTODY_PERC   VARCHAR2,
                                                       V_ALL_CLNT       NUMBER,
                                                       P_Market_Or_Cost VARCHAR2,
                                                       P_Client_nature  Number,
                                                       P_Client_Group   VARCHAR2,
                                                       P_TRADER         VARCHAR2) IS
       --=========================
       -- parameters with default values...
       --=========================
       -- PS_FUTURE_NORMAL VARCHAR2 := 'F',
       -- COT_ACCOUNT_MERGE VARCHAR2 := 'T',
       -- P_MARGIN_APPLICABLE VARCHAR2 := 1,
       -- P_Market_Or_Cost VARCHAR2 := 'M',
       -- P_TRADER         VARCHAR2 := '%'
       --=========================
       vshort_sale                number;
       vcash_balance              number;
       vgl_sl_type_client         number;
       v_cot_client_code          varchar2(5);
       sql_string                 varchar2(10000);
       v_MTS_Adjustment_Status    VARCHAR2(1000);
       -- EQUITY SYSTEM values...
       V_BLK_PROFIT_CODE          EQUITY_SYSTEM.BLOCK_PROFIT_GLMF_CODE%TYPE;
       v_forward_clr_type         EQUITY_SYSTEM.forward_clr_type%TYPE;
       v_Release_cot_trade        EQUITY_SYSTEM.Release_cot_trade%TYPE;
       v_badla_days               EQUITY_SYSTEM.badla_days%TYPE;
       v_cot_trade                EQUITY_SYSTEM.cot_trade%TYPE;
       v_Eqt_Area_Code            EQUITY_SYSTEM.EQUITY_AREA_CODE%TYPE;
       --
       v_sys_location             system.location_code%TYPE;
       v_Borrow_KSE_Activity      custody_activity.activity_code%type;
       v_Ret_Borr_KSE_Activity    custody_activity.activity_code%type;

       -- Changed by irfan @12-JUN-2015, adjustments in Future Weekly checking (Back-Date Checking)
       -- change by Irfan @12-JUL-2016, adjustment of MTS Cash Back amount.
begin
    -- Initialize Equity system variables...
    SELECT BLOCK_PROFIT_GLMF_CODE, forward_clr_type, Release_cot_trade, badla_days, cot_trade, EQUITY_AREA_CODE
      INTO V_BLK_PROFIT_CODE, v_forward_clr_type, v_Release_cot_trade, v_badla_days, v_cot_trade, v_Eqt_Area_Code
      FROM EQUITY_SYSTEM;
    -- Initialize System variables...
    SELECT location_code, gl_sl_type_client
      INTO v_sys_location, vgl_sl_type_client
      FROM system;
    -- Custody Activity...
    select borrow_kse_delv_actv into v_Borrow_KSE_Activity from custody_system;
    select ca.return_activity_code into v_Ret_Borr_KSE_Activity
      from custody_activity ca where ca.activity_code = v_Borrow_KSE_Activity;

    commit; -- this will refresh temporary tables...

-- Change by Irfan @ 09-JAN-2017 for minimizing confusing CLIENT Selection criterias...
--====================================================================================
-- IT IS MANDATORY FOR A CLIENT TO HAVE TRADES IN ORDER TO APPEAR IN THE RISK REPORT
--====================================================================================
if (V_ALL_CLNT = 1) Then
       -- select ALL clients with OPEN POSITIONS
       insert    into equity_temp_capital_g_l_sum (client_code)
       select    distinct c.client_code
       from      client c ,client_info ci,equity_trade et, branch_client bc
       where c.Client_code = ci.client_code(+)
         and c.Post = 1
         and c.Client_code=et.client_code
         AND c.client_code = bc.client_code
         AND bc.area_code = v_Eqt_Area_Code
         AND bc.trader_code = DECODE(P_TRADER, '%', bc.trader_code, P_TRADER)
         and c.CLIENT_CODE=DECODE(VCLIENT,'ALL',C.CLIENT_CODE,VCLIENT)
         and et.Trade_date <= vto_date
         and c.margin_applicable = Decode(P_MARGIN_APPLICABLE, 2, c.margin_applicable, P_MARGIN_APPLICABLE)
         and c.branch_code = decode(PS_BRANCH,'%',decode(PS_USER_BRANCH,(select branch_code from locations where location_code = v_sys_location),c.branch_code,PS_USER_BRANCH),PS_BRANCH)
         and c.client_nature = Decode(P_Client_nature, 0, c.client_nature, 1, 'T', 2, 'I', 3, 'J', P_Client_nature)
         and c.client_group = Decode(P_Client_Group, 'ALL', c.client_group, P_Client_Group)
         and decode(PS_ON_OFF_CLIENT,'ALL',1,decode(ci.online_client,null,0,ci.online_client)) = decode(PS_ON_OFF_CLIENT,'ALL',1,'ON',1,'OFF',0);

ELSIF (V_ALL_CLNT = 2 OR P_MARGIN_APPLICABLE = 2) Then
       -- Build ALL client list
       insert    into equity_temp_capital_g_l_sum (client_code)
       select    distinct c.client_code
       from      client c ,client_info ci, branch_client bc
       where c.Client_code = ci.client_code(+)
         and Decode(PS_ON_OFF_CLIENT,'ALL',1,decode(ci.online_client,null,0,ci.online_client)) = decode(PS_ON_OFF_CLIENT,'ALL',1,'ON',1,'OFF',0)
         and c.Client_nature = Decode(P_Client_nature, 0, c.client_nature, 1, 'T', 2, 'I', 3, 'J', P_Client_nature)
         and c.post = 1
         AND c.client_code = bc.client_code
         AND bc.area_code = v_Eqt_Area_Code
         AND bc.trader_code = DECODE(P_TRADER, '%', bc.trader_code, P_TRADER)
         and c.CLIENT_CODE=DECODE(VCLIENT,'ALL',C.CLIENT_CODE,VCLIENT)
         and c.margin_applicable = Decode(P_MARGIN_APPLICABLE, 2, c.margin_applicable, P_MARGIN_APPLICABLE)
         and c.client_group = Decode(P_Client_Group, 'ALL', c.client_group, P_Client_Group)
         and c.branch_code = decode(PS_BRANCH,'%',decode(PS_USER_BRANCH,(select branch_code from locations where location_code = v_sys_location),c.branch_code,PS_USER_BRANCH),PS_BRANCH);

else
       -- Build Single client list which trade during the period.
       insert   into equity_temp_capital_g_l_sum (client_code)
       select   distinct c.client_code
       from     Client c , Client_info ci, Equity_trade et, branch_client bc
       where c.client_code = ci.client_code(+)
         and c.post = 1
         and c.client_code=et.client_code
         and c.CLIENT_CODE=DECODE(VCLIENT,'ALL',C.CLIENT_CODE,VCLIENT)
         AND c.client_code = bc.client_code
         AND bc.area_code = v_Eqt_Area_Code
         AND bc.trader_code = DECODE(P_TRADER, '%', bc.trader_code, P_TRADER)
         and c.margin_applicable = Decode(P_MARGIN_APPLICABLE, 2, c.margin_applicable, P_MARGIN_APPLICABLE)
         and c.branch_code = decode(PS_BRANCH,'%',decode(PS_USER_BRANCH,(select branch_code from locations where location_code = v_sys_location),c.branch_code,PS_USER_BRANCH),PS_BRANCH)
         and c.client_nature = Decode(P_Client_nature, 0, c.client_nature, 1, 'T', 2, 'I', 3, 'J', P_Client_nature)
         and c.client_group = Decode(P_Client_Group, 'ALL', c.client_group, P_Client_Group)
         and decode(PS_ON_OFF_CLIENT,'ALL',1,decode(ci.online_client,null,0,ci.online_client)) = decode(PS_ON_OFF_CLIENT,'ALL',1,'ON',1,'OFF',0)
         and et.trade_date between vfrom_date and vto_date;
end if;

  -- Insert client custody holdings in the temp table
  sql_string := ' insert     into   temp_Equity_margin ';
  sql_string := sql_string|| '             (CLIENT_CODE,ISIN,CASH_BALANCE,CUST_BALANCE,MARKET_DATE,MARKET_RATE,OUTSTND_AMOUNT, ';
  sql_string := sql_string|| '             CASH_MARGIN,CUST_MARGIN,CASH_BUYING_POWER,CUST_BUYING_POWER,SHORT_SALE_VALUE, ';
  sql_string := sql_string|| '             FUTURE_PERIOD_DESC,EQUITY_CURRENT_POSITION,PROV_TRADE, Cost_Rate) ';
  sql_string := sql_string|| ' select  /*+ RULE*/ dq.client_code,dq.isin,0,SUM(dq.quantity) custody_balance,NULL,0,0,0,0,0,0,0,fpd,0,prov, AVG(Cost_rate) ';
  sql_string := sql_string|| ' FROM ';
  sql_string := sql_string|| ' ( ';

  sql_string := sql_string|| ' SELECT * FROM ( ';
  sql_string := sql_string|| ' SELECT      cm.client_code,cm.isin,NULL fpd,NULL prov, ';
  sql_string := sql_string|| ' Nvl(Sum(decode(cm.activity_code, '''||v_Borrow_KSE_Activity||'''/*cs.borrow_kse_delv_actv*/, Decode(cm.in_or_out,''I'',- (nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)),(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0))),'''||v_Ret_Borr_KSE_Activity||'''/*Get_return_Activity(cs.borrow_kse_delv_actv)*/,Decode(cm.in_or_out,''I'',- (nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)),(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0))))), 0) + Sum(Decode(cm.in_or_out,''I'',(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)),-(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)))) Quantity, 0 Cost_Rate ';
  sql_string := sql_string|| ' FROM Custody_master cm, Equity_temp_capital_g_l_sum etc/*, custody_system cs*/';
  sql_string := sql_string|| ' WHERE  cm.client_code = etc.client_code and Exists (select 1 from custody_master cm2 where cm.transaction_id = cm2.transaction_id and cm2.transaction_Date<='''|| vto_Date ||''') ';
  sql_string := sql_string|| ' AND cm.post = 1 ';
  sql_string := sql_string|| ' Group by cm.client_code,cm.isin ';
  sql_string := sql_string|| ' ) where quantity <> 0 ';

  sql_string := sql_string|| ' UNION ALL ';

  sql_string := sql_string|| ' select      scm.client_code,scm.isin,scm.fpd,NULL prov,sum(scm.quantity), 0 Cost_Rate ';
  sql_string := sql_string|| ' from ( ';
  sql_string := sql_string|| '      SELECT        cm.clearing_no,cm.client_code,cm.isin,NULL fpd,';
  sql_string := sql_string|| ' Nvl(Sum(decode(cm.activity_code, '''||v_Borrow_KSE_Activity||'''/*cs.borrow_kse_delv_actv*/, Decode(cm.in_or_out,''I'',- (nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)),(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0))), '''||v_Ret_Borr_KSE_Activity||''' /*Get_return_Activity(cs.borrow_kse_delv_actv)*/,Decode(cm.in_or_out,''I'',- (nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)),(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0))))), 0) + Sum(Decode(cm.in_or_out,''I'',(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)),-(nvl(cm.un_reg_quantity, 0)+nvl(cm.reg_quantity, 0)))) Quantity ';
  sql_string := sql_string|| '      FROM   custody_master cm, Equity_temp_capital_g_l_sum etc/*, Custody_system cs*/';
  sql_string := sql_string|| ' WHERE cm.client_Code = etc.client_code and cm.transaction_Date > '''|| vto_Date ||''' ';
  sql_string := sql_string|| ' and cm.clearing_no is not null ';
  sql_string := sql_string|| ' AND cm.post = 1 ';
  sql_string := sql_string|| ' group by cm.clearing_no,cm.client_code,cm.isin,NULL ';
  sql_string := sql_string|| ' having (sum(decode(cm.in_or_out,''I'',(nvl(cm.un_reg_quantity,0)+nvl(cm.reg_quantity,0)),-(nvl(cm.un_reg_quantity,0)+nvl(cm.reg_quantity,0))))<>0) ';
  sql_string := sql_string|| '      ) scm,clearing_calendar cc ';
  sql_string := sql_string|| ' where       scm.clearing_no=cc.clearing_no ';
  sql_string := sql_string|| ' and cc.clearing_end_date<='''||vto_date||''' ';
  sql_string := sql_string|| ' group by scm.client_code,scm.isin,scm.fpd ';

  sql_string := sql_string|| ' UNION ALL ';

  sql_string := sql_string|| ' SELECT cob.client_code,cob.isin,NULL fpd,NULL prov,decode(ca.in_or_out,''I'',(nvl(cob.un_reg_quantity,0)+nvl(cob.reg_quantity,0)),-(nvl(cob.un_reg_quantity,0)+nvl(cob.reg_quantity,0))) quantity, 0 Cost_Rate ';
  sql_string := sql_string|| '   FROM custody_opening_balances cob, custody_activity ca, Equity_temp_capital_g_l_sum etc ';
  sql_string := sql_string|| '  WHERE cob.client_code = etc.client_code and cob.activity_code=ca.activity_code ';
  sql_string := sql_string|| '    AND cob.post = 1 ';

  sql_string := sql_string|| ' UNION ALL ';

  sql_string := sql_string|| ' Select et.client_code,et.isin,cc.future_period_desc fpd,decode(instr(sc.symbol,''-PRO''),0,null,''-PRO'') prov,sum(decode(et.buy_or_sell,''B'',et.volume,-et.volume)) quantity, AVG(et.rate) Cost_Rate ';
  sql_string := sql_string|| ' From Equity_trade et, Clearing_calendar cc, Security sc, Equity_temp_capital_g_l_sum etc ';
  sql_string := sql_string|| ' WHERE et.Client_code = etc.Client_code and et.trade_date <='''||vto_date||''' ';
  sql_string := sql_string|| ' and Nvl(et.bill_number,0) = 0 ';
  sql_string := sql_string|| ' and et.clearing_no=cc.clearing_no ';
  sql_string := sql_string|| ' and et.isin=sc.isin ';
  sql_string := sql_string|| ' and et.post=1 ';
  sql_string := sql_string|| ' group by et.client_code,et.isin,cc.future_period_desc,sc.symbol ';

  sql_string := sql_string|| ' UNION ALL ';

  -- Provisional Weekly checking (Back-Date Checking)
  sql_string := sql_string|| ' select et.client_code,et.isin,null fpd,''-PROW'' prov,sum(decode(et.buy_or_sell,''B'',et.volume,-et.volume)) quantity, AVG(et.rate) Cost_Rate ';
  sql_string := sql_string|| ' from   equity_trade et,clearing_calendar cc,security sc, Equity_temp_capital_g_l_sum etc ';

  sql_string := sql_string|| ' WHERE et.client_code = etc.client_code and et.bill_number is null ';
  sql_string := sql_string|| ' and et.trade_date > '''||vto_date||''' ';
  sql_string := sql_string|| ' and  et.trade_type = '''||v_release_cot_trade||''' ';
  sql_string := sql_string|| ' and sc.symbol like ''%-PRO'' ';
  sql_string := sql_string|| ' and et.bill_number is null ';
  sql_string := sql_string|| ' and et.clearing_no=cc.clearing_no ';
  sql_string := sql_string|| ' and et.isin=sc.isin ';
  sql_string := sql_string|| ' and et.post=1 ';
  sql_string := sql_string|| ' group by et.client_code,et.isin,cc.future_period_desc,sc.symbol ';

  sql_string := sql_string|| ' UNION ALL ';

  -- Future Weekly checking (Back-Date Checking)
  sql_string := sql_string|| ' select et.client_code,et.isin,cc.future_period_desc fpd,''-FUTW'' prov,sum(decode(et.buy_or_sell,''B'',et.volume,-et.volume)) quantity, Avg(et.rate) Cost_Rate ';
  sql_string := sql_string|| ' from   equity_trade et,clearing_calendar cc,security sc, Equity_temp_capital_g_l_sum etc ';
  sql_string := sql_string|| ' WHERE  et.client_code = etc.client_code ';
  sql_string := sql_string|| ' and et.trade_date > '''||vto_date||''' ';
  sql_string := sql_string|| ' and  et.trade_type = '''||v_release_cot_trade||''' ';
  sql_string := sql_string|| ' and sc.symbol not like ''%-PRO'' ';
  sql_string := sql_string|| ' and cc.future_period_desc is not null ';
  sql_string := sql_string|| ' and et.clearing_no=cc.clearing_no ';
  sql_string := sql_string|| ' and et.isin=sc.isin ';
  sql_string := sql_string|| ' and et.post=1 ';
  -- (Change by Irfan @ 27-MAR-2015) Restrict open position checking to immediate next future clearing
  -- Still in TESTING Phase...
  sql_string := sql_string|| ' and et.bill_number is NOT null ';
  sql_string := sql_string|| ' and cc.clearing_start_date = (select MAX(cct.clearing_start_date) from clearing_calendar cct where cct.clearing_start_date <= '''||vto_date||''' ';
  sql_string := sql_string|| '    and cct.future_period_desc = cc.future_period_desc and cct.final_settlement_date = cc.final_settlement_date ) ';

  -- Test Script Ends Here...
  sql_string := sql_string|| ' group by et.client_code,et.isin,cc.future_period_desc,sc.symbol ';
  sql_string := sql_string|| ' ) dq ';
  sql_string := sql_string|| ' group by dq.client_code,dq.isin,fpd,prov ';
  sql_string := sql_string|| ' having (SUM(dq.quantity)<>0) ';

  Execute immediate sql_string;

-- INSERTING ONE ROW IF NO RECORD FOR A CLIENT EXISTS
Insert into temp_Equity_margin
    (CLIENT_CODE,ISIN,CASH_BALANCE,CUST_BALANCE,MARKET_DATE,MARKET_RATE,OUTSTND_AMOUNT,
    CASH_MARGIN,CUST_MARGIN,CASH_BUYING_POWER,CUST_BUYING_POWER,SHORT_SALE_VALUE,
    FUTURE_PERIOD_DESC,EQUITY_CURRENT_POSITION, FUTURE_BLOCKED_PROFIT)
    Select Client_code, '', 0, 0, NULL, 0, 0, 0, 0, 0, 0, 0, '', 0, 0
      From Equity_temp_capital_g_l_sum etc
      Where Not Exists (Select null from temp_Equity_margin tem
                          Where tem.client_code = etc.client_code);
/* deleting clients who have no balance in custody. clients who have worked during period
  but have no custody balance will remain b/c they may have cash balance.*/

       Delete From Temp_equity_margin otem
        where otem.isin is null
          and 1< (Select count(*) from Temp_equity_margin item
                   where item.client_code=otem.client_code);

--=============================
    -- Closing Rates pool...
    --=============================
    delete from TMP_EQUITY_MARKET_CUSTODY;
    -- Regular Market...
    INSERT INTO TMP_EQUITY_MARKET_CUSTODY(PRICE_DATE,ISIN, SYMBOL, CLOSE_RATE)
        SELECT /*em.price_date*/VTO_DATE, s.isin, s.symbol, em.close_rate
          FROM equity_market em, security s
         WHERE s.isin = em.isin
           AND s.post = 1
           AND em.price_date = (SELECT MAX(price_date)
                                  FROM equity_market t
                                 WHERE t.price_date <= VTO_DATE
                                   AND t.isin = s.isin);
    -- Future Market ...
    INSERT INTO TMP_EQUITY_MARKET_CUSTODY(PRICE_DATE,ISIN, SYMBOL, CLOSE_RATE)
    select /*fm.price_date*/VTO_DATE, s.isin, fm.symbol, fm.close_rate
      from security s, forward_market fm,
           (SELECT UNIQUE t.isin, t.future_period_desc
              FROM temp_equity_margin t
             WHERE t.future_period_desc IS NOT NULL ) tem
     where fm.symbol = s.symbol||tem.future_period_desc
       and tem.isin = s.isin
       and fm.price_date = (select max(price_date)
                              from (SELECT UNIQUE t.isin, t.future_period_desc
                                      FROM temp_equity_margin t
                                     WHERE t.future_period_desc IS NOT NULL ) t,
                                   security s,
                                   forward_market fem
                             where fem.symbol = s.symbol||t.future_period_desc
                               and t.isin = s.isin
                               and fem.price_date <=vto_date);

    -- update market price for normal (excluding future)
    update /*+ RULE*/ temp_equity_margin tem
    set (tem.market_date,tem.market_rate)=   (select em.price_date,em.close_rate
                                                from TMP_EQUITY_MARKET_CUSTODY em
                                               where em.isin=tem.isin
                                                 AND em.symbol NOT LIKE '%-%'
                                              )
    WHERE tem.future_period_desc is NULL;
    -- update market price for future
    update /*+ RULE*/ temp_equity_margin tem
    set (tem.market_date,tem.market_rate) = (select em.price_date,em.close_rate
                                               from TMP_EQUITY_MARKET_CUSTODY em, security s
                                              where em.isin=tem.isin
                                                AND em.isin = s.isin
                                                and em.Symbol = s.symbol||tem.future_period_desc
                                                )
    WHERE tem.future_period_desc IS NOT NULL;

-- update custody holding percentage for ONLINE/OFFLINE CLIENTS
---------------------------------------
-- CHANGE FOR COSTODY PERCENTAGE
---------------------------------------
update /*+ RULE*/ temp_equity_margin tem
set tem.cust_margin=NVL(V_CUSTODY_PERC,(select  nvl(decode(tem.future_period_desc,null,
                            decode(nvl(ci.online_client,0),0,order_validation.get_margin_holding_percentage(tem.client_code,tem.isin),ONLINE_CLIENT_margin.GET_OL_MARGIN_HOLD_PERCENTAGE(tem.client_code,tem.isin)),
                            decode(nvl(ci.online_client,0),0,order_validation.GET_MARGIN_HOLDING_FWD_PRCT(tem.client_code,tem.isin),ONLINE_CLIENT_margin.GET_OL_MARGIN_HOLD_FWD_PRCT(tem.client_code,tem.isin))
                            ),0)
                        from   client c,
                              client_info ci
                        where  c.client_code = ci.client_code(+)
                        and  c.client_code = tem.client_code));

---------------------------------------
-- update custody short sale
update /*+ RULE*/ temp_equity_margin tem
set tem.short_sale_value=decode(tem.cust_balance/decode(tem.cust_balance,0,1,abs(tem.cust_balance)),1,0,nvl(tem.cust_balance,0)*nvl(tem.market_rate,0));

update /*+ RULE*/  temp_equity_margin tem set tem.short_sale_value=0
where tem.future_period_desc is not null
or isin in (select isin from security where isin=tem.isin and symbol like '%-PRO');

-- update custody buying power detail
update /*+ RULE*/  temp_equity_margin tem
set tem.cust_buying_power=(tem.cust_balance*tem.market_rate)*decode(tem.cust_balance,0,1,decode(tem.cust_balance/abs(tem.cust_balance),1,tem.cust_margin/100,1))
where nvl(tem.cust_balance,0)<>0;

-- For Determing Cash Balance Including COT Effect OR Excluding COT Effect
/* For Normal Client Cash Balance  */

  Insert into temp_tbl
    (Client_code, Cl_amt)
    Select /*+ RULE*/ client_Code, Sum(Amt)
      from (  SELECT GL_SL_CODE CLIENT_CODE, GL_SL_OPEN_BAL AMT
                FROM GL_SL_MF_OPEN_BAL
               WHERE GL_SL_TYPE = vgl_sl_type_client
               UNION ALL
              SELECT D.GL_SL_CODE CLIENT_CODE, DECODE(D.DC, 'D', D.AMOUNT, -D.AMOUNT) AMT
                FROM GL_FORMS F, GL_JOURNAL_DET D,
                     EQUITY_TEMP_CAPITAL_G_L_SUM ETC
               WHERE F.GL_VOUCHER_NO = D.GL_VOUCHER_NO
                 AND D.GL_SL_TYPE = vgl_sl_type_client
                 AND D.GL_SL_CODE = ETC.CLIENT_CODE
                 AND F.GL_FORM_DATE <= VTO_DATE
                 and F.GL_FORM_TYPE_CODE != 'ETB'
              union all
              SELECT D.GL_SL_CODE CLIENT_CODE, DECODE(D.DC, 'D', D.AMOUNT, -D.AMOUNT) AMT
                FROM GL_FORMS F, GL_BANK_PAYMENTS_DET D,
                     EQUITY_TEMP_CAPITAL_G_L_SUM ETC
               WHERE F.GL_VOUCHER_NO = D.GL_VOUCHER_NO
                 AND D.GL_SL_TYPE = vgl_sl_type_client
                 AND D.GL_SL_CODE = ETC.CLIENT_CODE
                 AND F.GL_FORM_DATE <= VTO_DATE
              union all
              SELECT D.GL_SL_CODE CLIENT_CODE, DECODE(D.DC, 'D', D.AMOUNT, -D.AMOUNT) AMT
                FROM GL_FORMS F, GL_BANK_RECEIPTS_DET D,
                     EQUITY_TEMP_CAPITAL_G_L_SUM ETC
               WHERE F.GL_VOUCHER_NO = D.GL_VOUCHER_NO
                 AND D.GL_SL_TYPE = vgl_sl_type_client
                 AND D.GL_SL_CODE = ETC.CLIENT_CODE
                 AND F.GL_FORM_DATE <= VTO_DATE
              union all
              SELECT D.GL_SL_CODE CLIENT_CODE, DECODE(D.DC, 'D', D.AMOUNT, -D.AMOUNT) AMT
                FROM GL_FORMS F, GL_CASH_PAYMENTS_DET D,
                     EQUITY_TEMP_CAPITAL_G_L_SUM ETC
               WHERE F.GL_VOUCHER_NO = D.GL_VOUCHER_NO
                 AND D.GL_SL_TYPE = vgl_sl_type_client
                 AND D.GL_SL_CODE = ETC.CLIENT_CODE
                 AND F.GL_FORM_DATE <= VTO_DATE
              UNION ALL
              SELECT D.GL_SL_CODE CLIENT_CODE, DECODE(D.DC, 'D', D.AMOUNT, -D.AMOUNT) AMT
                FROM GL_FORMS F, GL_CASH_RECEIPTS_DET D,
                     EQUITY_TEMP_CAPITAL_G_L_SUM ETC
               WHERE F.GL_VOUCHER_NO = D.GL_VOUCHER_NO
                 AND D.GL_SL_TYPE = vgl_sl_type_client
                 AND D.GL_SL_CODE = ETC.CLIENT_CODE
                 AND F.GL_FORM_DATE <= VTO_DATE
              UNION ALL
              SELECT D.GL_SL_CODE CLIENT_CODE, DECODE(D.DC, 'D', D.AMOUNT, -D.AMOUNT) AMT
                FROM GL_FORMS F, GL_CUSTODY_ACCOUNTS D,
                     EQUITY_TEMP_CAPITAL_G_L_SUM ETC
               WHERE F.GL_VOUCHER_NO = D.GL_VOUCHER_NO
                 AND D.GL_SL_TYPE = vgl_sl_type_client
                 AND D.GL_SL_CODE = ETC.CLIENT_CODE
                 AND F.GL_FORM_DATE <= VTO_DATE
            Union all
            Select et.client_code, Decode(et.buy_or_sell,
                'B',
                ((et.volume * et.rate) + (et.brk_amount + nvl(eti.cvt, 0) + nvl(eti.wht, 0) +
                nvl(eti.wht_cot, 0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))),
                ((et.volume * et.rate) - (et.brk_amount + nvl(eti.cvt, 0) + nvl(eti.wht, 0) +
                nvl(eti.wht_cot, 0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))) * -1) amt
    From Equity_trade et,
         clearing_calendar cc,
         equity_trade_info eti,
         security,
         Equity_temp_capital_g_l_sum etc, Equity_Trade_Fed_Tax etf,
         (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                FROM equity_trade_external_charges ex
               GROUP BY ex.trade_number) etx
   Where et.trade_number = eti.trade_number(+)
     AND et.trade_number = etf.trade_number(+)
     AND et.trade_number = etx.trade_number(+)
     and et.isin = security.isin
     and et.clearing_no = cc.clearing_no
     and et.client_code = etc.client_code
     and et.trade_date <= VTO_DATE
     and decode('F' || nvl(et.bill_number, -1),
                'F-1',
                cc.clearing_type,
                0) <> decode('F' || nvl(et.bill_number, -1),
                             'F-1',
                             v_forward_clr_type,
                             1)
     and decode(Substr(Upper(Security.Symbol),
                       Length(Upper(Security.Symbol)) - 2),
                'PRO',
                decode(et.bill_number, null, 0, 1),
                1) = 1)
     Group by client_Code;

update /*+ RULE*/  Equity_temp_capital_g_l_sum etc Set Op_amt = (Select cl_amt from temp_tbl tt
                                                      where etc.client_code = tt.client_code);
 Delete from temp_tbl;

Insert into Temp_Tbl (Client_code, Cl_Amt)
select /*+ RULE*/  Client_code, sum(amount)
      from
                (
                -- SQUARED POSITION (Future and Provisional)
                Select  et.client_code client_code,
                        et.isin isin,cc.future_period_desc,
                        sum(decode(et.buy_or_sell,'B',et.volume,-et.volume)) quantity,
                        sum(decode(et.buy_or_sell,'B',
                                   ((et.volume*et.rate)+(et.brk_amount + nvl(eti.cvt,0) +
                                   nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))),
                                   -((et.volume*et.rate)-(et.brk_amount + nvl(eti.cvt,0) +
                                   nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))))) amount
                from     equity_trade et,clearing_calendar cc,security sc,equity_trade_info eti, equity_temp_capital_g_l_sum etc, Equity_Trade_Fed_Tax etf,
                        (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                          FROM equity_trade_external_charges ex
                         GROUP BY ex.trade_number) etx
                WHERE   et.trade_date <=VTO_DATE
                and     nvl(et.bill_number,0) = 0
                AND     et.CLIENT_CODE= etc.client_code
                and     et.clearing_no=cc.clearing_no
                and     et.isin=sc.isin
                and     (nvl(cc.future_period_desc,'N') <> 'N'
                        or sc.symbol like '%PRO')
                and     et.post=1
                and      et.trade_number = eti.trade_number(+)
                and    et.trade_number = etf.trade_number(+)
                AND et.trade_number = etx.trade_number(+)
                group by et.client_code,et.isin,cc.future_period_desc,sc.symbol
                having   sum(decode(et.buy_or_sell,'B',et.volume,-et.volume)) = 0

                UNION ALL

                -- SQUARED BACK-DATE FUTURE POSITION
                Select  et.client_code client_code,
                        et.isin isin,cc.future_period_desc,
                        sum(decode(et.buy_or_sell,'B',et.volume,-et.volume)) quantity,
                        sum(decode(et.buy_or_sell,'B',
                                  ((et.volume*et.rate)+(et.brk_amount + nvl(eti.cvt,0) +
                                  nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))),
                                  -((et.volume*et.rate)-(et.brk_amount + nvl(eti.cvt,0) +
                                  nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))) )) amount
                from     equity_trade et,clearing_calendar cc,equity_trade_info eti, equity_temp_capital_g_l_sum etc, Equity_Trade_Fed_Tax etf,
                        (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                          FROM equity_trade_external_charges ex
                         GROUP BY ex.trade_number) etx
                WHERE   et.trade_date > VTO_DATE
                and     nvl(et.bill_number,0) = 0
                AND     et.CLIENT_CODE= etc.CLIENT_CODE
                and     et.clearing_no=cc.clearing_no
                and     cc.future_period_desc is not null
                AND      et.ticket_number like 'FTR%'
                and     et.post=1
                and      et.trade_number = eti.trade_number(+)
                and    et.trade_number = etf.trade_number(+)
                AND et.trade_number = etx.trade_number(+)
                group by et.client_code,et.isin,cc.future_period_desc
                having   sum(decode(et.buy_or_sell,'B',et.volume,-et.volume)) = 0

                UNION ALL

                -- SQUARED BACK-DATE PROVISIONAL POSITION
                Select  et.client_code client_code,
                        et.isin isin,null future_period_desc,
                        sum(decode(et.buy_or_sell,'B',et.volume,-et.volume)) quantity,
                        sum(decode(et.buy_or_sell,'B',
                                  ((et.volume*et.rate)+(et.brk_amount + nvl(eti.cvt,0) +
                                  nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))),
                                  -((et.volume*et.rate)-(et.brk_amount + nvl(eti.cvt,0) +
                                  nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))))) amount
                from     equity_trade et,security sc,equity_trade_info eti, equity_temp_capital_g_l_sum etc, Equity_Trade_Fed_Tax etf,
                        (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                          FROM equity_trade_external_charges ex
                         GROUP BY ex.trade_number) etx
                WHERE   et.trade_date > VTO_DATE
                and     nvl(et.bill_number,0) = 0
                AND     et.CLIENT_CODE= etc.CLIENT_CODE
                AND      et.ticket_number like 'FTR%'
                and     et.isin = sc.isin
                and     sc.symbol like '%PRO'
                and     et.post=1
                and      et.trade_number = eti.trade_number(+)
                and    et.trade_number = etf.trade_number(+)
                AND et.trade_number = etx.trade_number(+)
                group by et.client_code,et.isin
                having   sum(decode(et.buy_or_sell,'B',et.volume,-et.volume)) = 0
                )
Group by Client_code;

update /*+ RULE*/ Equity_temp_capital_g_l_sum etc Set PL_Square_Pos = (Select cl_amt from temp_tbl tt
                                                      where etc.client_code = tt.client_code);

Delete from temp_tbl;

/* For Future Client Cash Balance  */
-- new approach...
insert into temp_tbl(client_code, cl_amt)
select /*+ RULE*/ client_code, sum(fcb) from (
       SELECT ET.CLIENT_CODE,
              NVL(SUM(
              DECODE(ET.BUY_OR_SELL,'B',
              ((ET.VOLUME*ET.RATE)+
              (ET.BRK_AMOUNT + NVL(ETI.CVT,0) + NVL(ETI.WHT,0) + NVL(ETI.WHT_COT,0) + NVL(ETF.FED_AMOUNT, 0) + NVL(ETX.AMOUNT,0))),
              (((ET.VOLUME*ET.RATE)-
              (ET.BRK_AMOUNT + NVL(ETI.CVT,0) + NVL(ETI.WHT,0) + NVL(ETI.WHT_COT,0) + NVL(ETF.FED_AMOUNT, 0) + NVL(ETX.AMOUNT,0)))
              *-1))),0) fcb
        FROM EQUITY_TRADE ET,EQUITY_ORDER EO, CLEARING_CALENDAR CC,EQUITY_TRADE_INFO ETI, EQUITY_TRADE_FED_TAX ETF,
             (SELECT EX.TRADE_NUMBER, NVL(SUM(EX.AMOUNT),0) AMOUNT FROM EQUITY_TRADE_EXTERNAL_CHARGES EX
              GROUP BY EX.TRADE_NUMBER) ETX, temp_equity_margin tem2
       where et.order_number=eo.order_number
        and et.trade_number = eti.trade_number(+)
        and et.trade_number = etf.trade_number(+)
        AND et.trade_number = etx.trade_number(+)
        and et.client_code=tem2.client_code
        and et.isin = tem2.isin
        and cc.future_period_desc = tem2.future_period_desc
        and cc.future_period_desc is not null
        and et.trade_date <= vto_date
        and cc.clearing_type = v_FORWARD_CLR_TYPE
        and et.clearing_no = cc.clearing_no
        and et.bill_number is null GROUP BY ET.CLIENT_CODE
         union all
         SELECT ET.CLIENT_CODE,
                NVL(SUM(
                DECODE(ET.BUY_OR_SELL,'B',
                ((ET.VOLUME*ET.RATE)+
                (ET.BRK_AMOUNT + NVL(ETI.CVT,0) + NVL(ETI.WHT,0) + NVL(ETI.WHT_COT,0) + NVL(ETF.FED_AMOUNT, 0) + NVL(ETX.AMOUNT,0))),
                (((ET.VOLUME*ET.RATE)-
                (ET.BRK_AMOUNT + NVL(ETI.CVT,0) + NVL(ETI.WHT,0) + NVL(ETI.WHT_COT,0) + NVL(ETF.FED_AMOUNT, 0) + NVL(ETX.AMOUNT,0)))
                *-1))),0) fcb
           FROM EQUITY_TRADE ET, EQUITY_ORDER EO, CLEARING_CALENDAR CC,EQUITY_TRADE_INFO ETI, EQUITY_TRADE_FED_TAX ETF,
                (SELECT EX.TRADE_NUMBER, NVL(SUM(EX.AMOUNT),0) AMOUNT FROM EQUITY_TRADE_EXTERNAL_CHARGES EX
                  GROUP BY EX.TRADE_NUMBER) ETX, temp_equity_margin tem2
          where et.order_number=eo.order_number
            and et.trade_number = eti.trade_number(+)
            and et.trade_number = etf.trade_number(+)
            AND et.trade_number = etx.trade_number(+)
            and et.client_code=tem2.client_code
            and et.isin = tem2.isin
            and cc.future_period_desc = tem2.future_period_desc
            and cc.future_period_desc is not null
            and et.trade_date > vto_date
            and cc.clearing_type = v_FORWARD_CLR_TYPE
            and et.trade_type = v_release_cot_trade
            and et.clearing_no = cc.clearing_no
            and et.bill_number is null
          GROUP BY ET.CLIENT_CODE
)
group by client_code
having sum(fcb) <> 0;

UPDATE /*+ RULE*/TEMP_EQUITY_MARGIN TEM
   SET TEM.FUTURE_CASH_BALANCE = (SELECT T.CL_AMT FROM TEMP_TBL T WHERE T.CLIENT_CODE = TEM.CLIENT_CODE);

delete from temp_tbl;

-- COT Client Cash Merge functionality
if COT_ACCOUNT_MERGE = 'Y' THEN

/* Selection of COT client Code */
   update /*+ RULE*/  equity_temp_capital_g_l_sum set op_amt=GET_RISK_CLIENT_BALANCE(vgl_sl_type_client,client_code,vto_date,1,'C',PS_FUTURE_NORMAL);
/* Selection of COT client Code */
   begin
      SELECT COT_CLIENT_CODE INTO V_COT_CLIENT_CODE
      FROM CLIENT C
      WHERE C.CLIENT_CODE = (select ETC.CLIENT_CODE from equity_temp_capital_g_l_sum ETC WHERE ROWNUM = 1);
   exception
      when no_data_found then
      V_COT_CLIENT_CODE := '00000';
      when TOO_MANY_ROWS then
      V_COT_CLIENT_CODE := '%';
   end;

/* COT client Cash Balance */
   update /*+ RULE*/  TEMP_EQUITY_MARGIN ETC SET COT_CASH_BALANCE = GET_RM_CLIENT_BALANCE(vgl_sl_type_client,client_code,vto_date,'ALL',1,'C');

/* COT client Cash Balance Merging in Normal Cash Balance*/
   update /*+ RULE*/  equity_temp_capital_g_l_sum ETC SET op_amt = nvl(op_amt,0)+GET_RM_CLIENT_BALANCE(vgl_sl_type_client,client_code,vto_date,'ALL',1,'C');
end if;

-- Reverse effect treat trades as Release(COT EFFECT)
Insert into temp_tbl
  (Client_Code, cl_amt, badla_mtm)
  (Select /*+ RULE*/  et.client_code,
          Sum((et.volume - Nvl(etr.volume, 0)) * DECODE(P_Market_Or_Cost,'M',em.close_rate,et.rate)) cl_amt,
          Sum(Decode((et.volume - Nvl(etr.Volume, 0)), 0, 0, decode(et.buy_or_sell,
                     'S',
                     ((((et.Actual_trade_value/et.volume)/*et.rate*/ - em.close_rate) *
                     (et.volume - Nvl(etr.Volume, 0)))
                     +(((et.brk_amount/et.volume)*(et.volume - Nvl(etr.volume, 0))) + nvl(et.cvt, 0) + nvl(et.wht, 0) +
                     nvl(et.wht_cot, 0) + ((nvl(et.fed_amount,0)/et.volume)*(et.volume - Nvl(etr.volume, 0))) + et.ex_amount)),
                     ((em.close_rate - /*et.rate*/(et.Actual_trade_value/et.volume) *
                     (et.volume - Nvl(etr.Volume, 0))))
                     +(((et.brk_amount/et.volume)*(et.volume - Nvl(etr.volume, 0))) + nvl(et.cvt, 0) + nvl(et.wht, 0) +
                     nvl(et.wht_cot, 0) + ((nvl(et.fed_amount,0)/et.volume)*(et.volume - Nvl(etr.volume, 0))) + et.ex_amount)
                     ))) badla_mtm
     From (Select et.Client_code,
                  et.isin,
                  et.buy_or_sell,
                  et.Ticket_number,
                  et.clearing_no,
                  Sum(et.volume) Volume,
                  Sum(et.brk_Amount) brk_Amount,
                  Avg(et.rate) rate,
                  Sum(eti.cvt) cvt,
                  Sum(eti.wht) wht,
                  Sum(eti.wht_Cot) wht_Cot,
                  Sum(nvl(etf.fed_amount, 0)) Fed_amount,
                  SUM(nvl(etx.amount,0)) ex_amount,
                  Sum(etfd.actual_trade_rate * et.volume) Actual_trade_value
             From Equity_trade et, Equity_Trade_Info eti,
                  Equity_temp_capital_g_l_sum etc, Equity_Trade_Fed_Tax etf, Equity_Trade_Fpr_Det ETFD,
                  (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                    FROM equity_trade_external_charges ex
                   GROUP BY ex.trade_number) etx
            Where et.trade_number = eti.trade_number
              and et.trade_number = etf.trade_number(+)
              and et.trade_number = ETFD.Trade_Number(+)
              AND et.trade_number = etx.trade_number(+)
              and et.trade_type = v_cot_trade
              and et.client_code = etc.client_code
              and et.buy_or_sell = 'S'
              and et.trade_date between To_date(vto_date) - v_badla_days and
                  To_date(vto_date)
            Group by et.Client_code,
                     et.isin,
                     et.buy_or_sell,
                     et.Ticket_number,
                     et.clearing_no) et,
          clearing_calendar cc,
          security s,
          clearing_type ct,
          (SELECT * FROM TMP_EQUITY_MARKET_CUSTODY WHERE Symbol NOT LIKE '%-%') em,
          (Select et.Client_code, Ticket_number, Sum(Volume) Volume
             from equity_trade et, Equity_temp_capital_g_l_sum etc
            Where Trade_type = v_Release_cot_trade
              and et.buy_or_sell = 'B'
              and et.client_code = etc.client_code
              and trade_date <= VTo_date
            Group by et.Client_code, Ticket_number) etr
    where et.clearing_no = cc.clearing_no
      and et.isin = em.isin
      and et.Ticket_number = etr.Ticket_number(+)
      and et.client_code = etr.client_code(+)
      and em.price_date = VTO_DATE
      and et.isin = s.isin
      and cc.clearing_type = ct.clearing_type
      and ct.forwardable = 0
      and s.symbol not like '%-PRO'
      and cc.future_period_desc is null
    Group by et.client_code
    Having Nvl(Sum(et.Volume), 0) - Nvl(Sum(etr.Volume), 0) <> 0);

update /*+ RULE*/  Equity_temp_capital_g_l_sum et
   Set et.Cl_amt = (Select cl_amt from Temp_tbl tt
                      Where tt.client_code = et.client_code),
       et.Badla_mtm = (Select Badla_mtm from Temp_tbl tt
                      Where tt.client_code = et.client_code);

-------------------------
for rec in (select ctem.client_code, op_amt bal, cl_amt cot_amt
                          from equity_temp_capital_g_l_sum ctem) LOOP
    -- Update Cash Balance,Cash Margin Percentage in TEMP_EQUITY_MARGIN
    update /*+ RULE*/  temp_equity_margin tem
    set
    tem.cash_balance= rec.bal,
    tem.cash_margin=NVL(V_MARGIN_PERC,nvl(order_validation.get_margin_percentage(tem.client_code,tem.isin),0))
    where tem.client_code=rec.client_code;
-----------------------------------------------
    -- Update Online Cash Withdrawl in TEMP_EQUITY_MARGIN
    update /*+ RULE*/   temp_equity_margin
    set      ol_cash_withdrawl =
                              nvl((select   sum(nvl(amount,0)) cash_withdrawl_amount
                              from     online_client_pay_req
                              where   status in ('IN PROCESS','ACCEPTED')
                              and      client_code = rec.client_code
                              and      trunc(request_time) <= VTO_DATE
                              ),0)
    where    client_code = rec.client_code;

    -- Update Online Cash Withdrawl impact on Cash Balance in TEMP_EQUITY_MARGIN
    update /*+ RULE*/   temp_equity_margin
    set      cash_balance = cash_balance + ol_cash_withdrawl
    where    client_code = rec.client_code;

    begin
         select sum(tem.short_sale_value),max(tem.cash_balance) into vshort_Sale,vcash_balance from temp_equity_margin tem
         where tem.client_code= rec.client_code;
    exception
         when no_data_found then
         vshort_sale:=0;
         vcash_balance:=0;
         null;
    end;

    if vcash_balance>0 then
       update /*+ RULE*/  temp_equity_margin tem
       set
       tem.cash_buying_power=tem.cash_balance
       where tem.client_code=rec.client_code;
    else
        vcash_balance:= rec.bal + abs(vshort_Sale);
        IF vcash_balance>0 THEN
           update /*+ RULE*/  temp_equity_margin tem
           set
           tem.cash_buying_power=tem.cash_balance
           where tem.client_code= rec.client_code;
        else
           update /*+ RULE*/  temp_equity_margin tem
           set
           tem.cash_buying_power=vcash_balance*tem.cash_margin/100
           where tem.client_code= rec.client_code;
        end IF;
    end if;

    update /*+ RULE*/  temp_equity_margin tem
       SET tem.outstnd_amount = rec.cot_amt
     where tem.client_code = rec.client_code;

    update /*+ RULE*/     temp_equity_margin
    set       future_mm=(
                         select    sum(decode(et.buy_or_sell,'B',
                                             ((et.rate - em.market_rate)*et.volume)+(et.brk_amount + nvl(eti.cvt,0) +
                                             nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0)),
                                             ((em.market_rate - et.rate)*et.volume)+(et.brk_amount + nvl(eti.cvt,0) +
                                             nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0)))) amount
                         from     equity_trade et,temp_equity_margin em,clearing_calendar cc,equity_trade_info eti, Equity_Trade_Fed_Tax etf,
                                  (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                                    FROM equity_trade_external_charges ex
                                   GROUP BY ex.trade_number) etx
                         where    em.client_code = rec.client_code
                         and      et.client_code = em.client_code
                         and      et.trade_number = eti.trade_number(+)
                         and    et.trade_number = etf.trade_number(+)
                         AND et.trade_number = etx.trade_number(+)
                         and     et.isin = em.isin
                         and     et.isin||cc.future_period_desc=em.isin||em.future_period_desc
                         and     et.clearing_no = cc.clearing_no
                         and     et.trade_date <= vto_date
                         and     et.bill_number is null
                         and     cc.future_period_desc is not null
                         )
              where         temp_equity_margin.future_period_desc is not null
    and       temp_equity_margin.client_code= rec.client_code;

    update /*+ RULE*/     temp_equity_margin
    set       prov_mm=(
                       select sum(decode(et.buy_or_sell,'B',
                                 (((et.rate - em.market_rate)*et.volume)+(et.brk_amount + nvl(eti.cvt,0) + nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))),
                                 (((em.market_rate - et.rate)*et.volume)+(et.brk_amount + nvl(eti.cvt,0) + nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))))) amount
                       from   equity_trade et,temp_equity_margin em,security s,equity_trade_info eti, Equity_Trade_Fed_Tax etf,
                              (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                                FROM equity_trade_external_charges ex
                               GROUP BY ex.trade_number) etx
                       where   et.client_code = rec.client_code
                       and    et.client_code = em.client_code(+)
                       and  et.trade_number = eti.trade_number(+)
                       and    et.trade_number = etf.trade_number(+)
                       AND et.trade_number = etx.trade_number(+)
                       and    et.isin = em.isin(+)
                       and    et.isin = s.isin
                       and     s.symbol like '%-PRO'
                       and     et.trade_date <= vto_date
                       and     et.bill_number is null
                      )
    where temp_equity_margin.client_code= rec.client_code;

    /** PROVISIONAL CASH BALANCE in EQUITY_CURRENT_POSITION field **/
    update /*+ RULE*/   temp_equity_margin tem set tem.EQUITY_CURRENT_POSITION=
    (
           select   sum(Decode(et.buy_or_sell,'B',
                       ((et.volume*et.rate)+(et.brk_amount + nvl(eti.cvt,0) + nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))),
                       -((et.volume*et.rate)-(et.brk_amount + nvl(eti.cvt,0) + nvl(eti.wht,0) + nvl(eti.wht_cot,0) + nvl(etf.fed_amount, 0) + nvl(etx.amount,0))))) cash_balance
           from   equity_trade et,security s,equity_trade_info eti, Equity_Trade_Fed_Tax etf,
                  (SELECT ex.trade_number, NVL(SUM(ex.amount),0) amount
                    FROM equity_trade_external_charges ex
                   GROUP BY ex.trade_number) etx
           where    et.isin=s.isin
           and    et.client_code = rec.client_code
           and    et.trade_number = eti.trade_number(+)
           and    et.trade_number = etf.trade_number(+)
           AND et.trade_number = etx.trade_number(+)
           and      et.trade_date<=vto_date
           and      s.symbol like '%-PRO'
           and      et.bill_number is null
           group    by et.client_code
    )
    where   tem.client_code= rec.client_code;

    -- update Provisional Market Value in the table temp_equity_margin
    update /*+ RULE*/   temp_equity_margin tem set tem.NORMAL_CASH_BALANCE=
          (
          select sum(abs(tem.cust_balance) * DECODE(P_Market_Or_Cost,'M',tem.market_rate,tem.Cost_rate)) market_value
           from temp_equity_margin tem,security s
           where tem.isin=s.isin
           and   tem.client_code= rec.client_code
           and   tem.prov_trade is not null
           and   s.symbol like '%-PRO'
          )
    where tem.client_code= rec.client_code;
    -- Future Cash Blockage ...
    update /*+ RULE*/  temp_equity_margin t
       SET t.future_blocked_cash = GET_CLIENT_FUT_BLOCK_CASH(rec.client_code, VTO_DATE)
     WHERE t.client_code = rec.client_code;
    --
    --Future Profit Blockage...
    update /*+ RULE*/  TEMP_EQUITY_MARGIN T
       SET T.FUTURE_BLOCKED_PROFIT = ONLINE_CLIENT_MARGIN.GET_FUTURE_BLOCK_PROFIT(rec.client_code, '')
     WHERE T.CLIENT_CODE = REC.CLIENT_CODE;

  ---------------------------
  END LOOP;
  ---------------------------
  -- Change By Irfan @12-JUL-2016, Adjustable MTS Amount (Cashback)
    v_MTS_Adjustment_Status := Adjust_MTS_Impact_In_RISK(VTO_DATE, '%');
    IF v_MTS_Adjustment_Status <> 'VALID' THEN
      RAISE_APPLICATION_ERROR(-20001, 'Error in MTS Adustment Proc: '|| v_MTS_Adjustment_Status);
    END IF;
    update /*+ RULE*/  TEMP_EQUITY_MARGIN T
       SET T.MTS_AMOUNT = (SELECT AMOUNT FROM TEMP_MTS_ADJUSTMENTS A WHERE A.CLIENT_CODE = T.CLIENT_CODE);

END EQUITY_MARGIN_OFF_LINE_NEW;
/
