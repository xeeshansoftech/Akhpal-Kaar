create or replace package PCKG_CGT_UTILITY is

  -- Author  : IRFAN KHAN
  -- Created : 7/7/2010 12:55:53 PM
  -- Purpose : For CGT process

  PROCEDURE CGT_HOUSE_OPENING(P_Client_code   VARCHAR2,
                        P_Rem_Pos_Rep   Number default 0,
                        P_ISIN          varchar2);

  PROCEDURE CGT_OPENING(P_Client_code      VARCHAR2,
                        P_Rem_Pos_Rep   Number default 0);

  PROCEDURE DELETE_CGT_DATA(P_Client_Code VARCHAR2,
                            P_USER        VARCHAR2,
                            P_Commit      NUMBER DEFAULT 0,
                            P_HOUSE_ACC   NUMBER DEFAULT 0,
                            P_LATEST_CGT  NUMBER,
                            P_LOG_ID      NUMBER,
                            P_Err_Msg     OUT VARCHAR2);

  PROCEDURE Calculate_House_Temp_CGT_Pos(P_To_Date     Date,
                          P_Client_code        Varchar2,
                          P_Isin               Varchar2,
                          v_RetVal             Out Number,
                          v_ErrMsg             Out Varchar2);

  PROCEDURE Calculate_Temp_CGT_Pos(P_To_Date     Date,
                                   P_Client_Code Varchar2,
                                   P_Isin        Varchar2,
                                   v_RetVal      Out Number,
                                   v_ErrMsg      Out Varchar2);

  PROCEDURE Calculate_House_CGT(P_From_Date   Date,
                          P_To_Date     Date,
                          P_Client_code Varchar2,
                          P_Main_Client Varchar2,
                          P_Year        Number,
                          P_Quarter     Number,
                          P_LOG_ID      NUMBER,
                          P_Remarks     VARCHAR2,
                          P_Commit      NUMBER DEFAULT 0,
                          v_RetVal      Out Number,
                          v_ErrMsg      Out Varchar2);

  PROCEDURE Calculate_CGT(P_From_Date   Date,
                          P_To_Date     Date,
                          P_Client_code Varchar2,
                          P_Year        Number,
                          P_Quarter     Number,
                          P_LOG_ID      NUMBER,
                          P_Remarks     VARCHAR2,
                          P_Commit      NUMBER DEFAULT 0,
                          v_RetVal      Out Number,
                          v_ErrMsg      Out Varchar2);

  PROCEDURE Calculate_CGT_FUT_WISE(P_From_Date   Date,
                                   P_To_Date     Date,
                                   P_Client_code Varchar2,
                                   P_Year        Number,
                                   P_Quarter     Number,
                                   P_LOG_ID      NUMBER,
                                   P_Remarks     VARCHAR2,
                                   P_Commit      NUMBER DEFAULT 0,
                                   v_RetVal      Out Number,
                                   v_ErrMsg      Out Varchar2);

  PROCEDURE CGT_REPORT_WORK(P_Clause            VARCHAR2,
                            P_Duration_Clause   VARCHAR2,
                            P_REPORT_TYPE_DS    CHAR DEFAULT 'D',
                            P_DURATION_WISE     NUMBER DEFAULT 0,
                            P_DURATION          NUMBER);

  PROCEDURE CGT_WHT_FREE_REPORT_WORK(P_Clause            VARCHAR2,
                                     P_Duration_Clause   VARCHAR2,
                                     P_REPORT_TYPE_DS    CHAR DEFAULT 'D',
                                     P_DURATION_WISE     NUMBER DEFAULT 0,
                                     P_DURATION          NUMBER);

  FUNCTION CHK_CGT_CALC_HISTORY(P_Client_Code VARCHAR2, P_TO_Date   Date, P_House_Acc Number Default 0) RETURN VARCHAR2;



end PCKG_CGT_UTILITY;
/
create or replace package body PCKG_CGT_UTILITY is
  --=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  -- CLIENT OPENING FROM CUSTODY HOLDING AT "CGT_DATE"
  -- (ONLY FOR HOUSE ACCOUNTS)
  --=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
PROCEDURE CGT_HOUSE_OPENING(P_Client_code   VARCHAR2,
                        P_Rem_Pos_Rep   Number default 0,
                        P_ISIN          varchar2) IS

    v_Buy_det_Id number := 0;
    v_HOLDING    NUMBER :=0;
    V_SHARES     NUMBER :=0;
    V_DONE       BOOLEAN := FALSE;
    v_CGT_ID     CGT_BUY_DET.CGT_ID%TYPE;

  BEGIN

      -- --------------------------------
      -- Process Execution LOG...
      -- --------------------------------
      if P_Rem_Pos_Rep = 0 then
        begin
             SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING T WHERE T.CLIENT_CODE = P_Client_code and T.HOUSE_ACC = 1;
             insert into CGT_OPENING(CGT_ID, CLIENT_CODE, YEAR, QUARTER, FROM_DATE, TO_DATE, REMARKS, POST, LOG_ID, HOUSE_ACC)
             values (v_CGT_ID, P_Client_code, 2010, 0, (select CGT_DATE from cgt_tax_configuration), (select CGT_DATE from cgt_tax_configuration), 'FIRST TIME CLIENT HOLDING (OPENING POSITIONS) BUILDING', 1, 0, 1);
        exception
          when dup_val_on_index then null;
        end;
      end if;
      -- --------------------------------
      -- Fetch Custody Balances for each client...
      EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_CUSTODY_BALANCE');
      INSERT INTO TEMP_CGT_CUSTODY_BALANCE
        (CLIENT_CODE, ISIN, VOLUME)
        SELECT Client_Code, ISIN, NETT
  FROM (SELECT --dq.client_code,
               client.main_client_code AS Client_code,
               dq.isin,
               SUM(decode(custody_status_activity('ALL', dq.activity_code), 1, 0,
                          decode(dq.in_or_out, 'I', dq.quantity, -dq.quantity))) nett
          FROM (SELECT cm.activity_code,
                       cm.client_code,
                       cm.isin,
                       cm.in_or_out,
                       cm.reg_quantity quantity,
                       1 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_master cm
                 WHERE cm.transaction_Date <= (select CGT_DATE from cgt_tax_configuration)
                   and cm.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                   and cm.post = 1
                UNION ALL
                select scm.activity_code,
                       scm.client_code,
                       scm.isin,
                       scm.in_or_out,
                       sum(scm.quantity),
                       1 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  from (SELECT cm.clearing_no,
                               cm.activity_code,
                               cm.client_code,
                               cm.isin,
                               cm.in_or_out,
                               sum(cm.reg_quantity) quantity
                          FROM custody_master cm
                           WHERE cm.transaction_Date > (select CGT_DATE from cgt_tax_configuration)
                           and cm.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                           and cm.clearing_no is not null
                         group by cm.clearing_no,
                                  cm.activity_code,
                                  cm.client_code,
                                  cm.isin,
                                  cm.in_or_out
                        having(sum(cm.reg_quantity) <> 0)) scm,
                       clearing_calendar cc
                 where scm.clearing_no = cc.clearing_no
                   and cc.clearing_end_date <= (select CGT_DATE from cgt_tax_configuration)
                   and scm.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                 group by scm.activity_code,
                          scm.client_code,
                          scm.isin,
                          scm.in_or_out
                having(sum(scm.quantity) <> 0)
                UNION ALL
                SELECT cm.activity_code,
                       cm.client_code,
                       cm.isin,
                       cm.in_or_out,
                       cm.un_reg_quantity quantity,
                       0 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_master cm
                 WHERE cm.transaction_Date <= (select CGT_DATE from cgt_tax_configuration)
                   and cm.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                   and cm.post = 1
                UNION ALL
                select scm.activity_code,
                       scm.client_code,
                       scm.isin,
                       scm.in_or_out,
                       sum(scm.quantity),
                       0 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  from (SELECT cm.clearing_no,
                               cm.activity_code,
                               cm.client_code,
                               cm.isin,
                               cm.in_or_out,
                               sum(cm.un_reg_quantity) quantity
                          FROM custody_master cm
                           WHERE cm.transaction_Date > (select CGT_DATE from cgt_tax_configuration)
                           and cm.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                           and cm.clearing_no is not null
                         group by cm.clearing_no,
                                  cm.activity_code,
                                  cm.client_code,
                                  cm.isin,
                                  cm.in_or_out
                        having(sum(cm.un_reg_quantity) <> 0)) scm,
                       clearing_calendar cc
                 where scm.clearing_no = cc.clearing_no
                   and cc.clearing_end_date <= (select CGT_DATE from cgt_tax_configuration)
                   and scm.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                 group by scm.activity_code,
                          scm.client_code,
                          scm.isin,
                          scm.in_or_out
                having(sum(scm.quantity) <> 0)

                UNION ALL
                SELECT cob.activity_code,
                       cob.client_code,
                       cob.isin,
                       ca.in_or_out in_or_out,
                       reg_quantity quantity,
                       1 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_opening_balances cob, custody_activity ca
                 Where cob.activity_code = ca.activity_code
                   and cob.post = 1
                   and cob.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                UNION ALL
                SELECT cob.activity_code,
                       cob.client_code,
                       cob.isin,
                       --decode(custody_status_activity('ALL',cob.activity_code),1,'O','I') in_or_out,
                       ca.in_or_out in_or_out,
                       un_reg_quantity quantity,
                       0 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_opening_balances cob, custody_activity ca
                 Where cob.activity_code = ca.activity_code
                   and cob.post = 1
                   and cob.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                UNION ALL
                select decode(s.cds_security,
                              1,
                              decode(eq.buy_or_sell,
                                     'B',
                                     ct.cdc_in_activity_code,
                                     ct.cdc_out_activity_code),
                              decode(eq.buy_or_sell,
                                     'B',
                                     ct.phy_in_activity_code,
                                     ct.phy_out_activity_code)) activity_code,
                       eq.client_code,
                       eq.isin,
                       null,
                       0 quantity,
                       0 registered,
                       cal.clearing_type,
                       decode(ct.trade_days || ct.settlement_days,
                              ct_reg.trade_days || ct_reg.settlement_days,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              0) net_reg_unbilled,
                       decode(ct.trade_days || ct.settlement_days,
                              1 || 1,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              1 || 0,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              0) net_spot_unbilled,
                       decode(ct.forwardable,
                              1,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              0) net_forward_unbilled
                  from equity_trade      eq,
                       clearing_calendar cal,
                       security          s,
                       clearing_type     ct,
                       equity_system     es,
                       clearing_type     ct_reg
                 where eq.clearing_no = cal.clearing_no
                   and cal.clearing_type = ct.clearing_type
                   and ct_reg.clearing_type = es.reg_clr_type
                   and eq.isin = s.isin
                   and eq.bill_number is null
                   and eq.trade_date <= (select CGT_DATE from cgt_tax_configuration)
                   and eq.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                   and eq.post = 1) dq,
               custody_activity_group cag,
               custody_activity ca,
               custody_system cs,
               (select em.isin, em.close_rate, em.price_date
                  from equity_market em,
                       (select isin, max(price_date) P_date
                          from equity_market
                         where price_date <= (select CGT_DATE from cgt_tax_configuration)
                         group by isin) temp
                 where em.isin = temp.isin
                   and em.price_date = temp.p_date) EM,
               security,
               executive_clients,
               client,
               system,
               locations,
               CLIENT_INFO CI
         WHERE ca.activity_group = cag.activity_group
           and dq.activity_code = ca.activity_code
           and dq.isin = security.isin
           and dq.client_code = client.client_code
           and system.location_code = locations.location_code
           and security.isin = em.isin(+)
           AND dq.CLIENT_CODE = CI.CLIENT_CODE(+)
           and dq.client_code = executive_clients.client_code(+)
           and dq.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
           and ca.post = 1
           and cag.post = 1
         GROUP BY --dq.client_code,
                  client.main_client_code,
                  client.client_name,
                  cdc_group_code,
                  cdc_investor_code,
                  dq.isin,
                  security.security_name,
                  em.close_rate)
 WHERE nett > 0
order by CLIENT_CODE, ISIN;

      -- -----------------------------------------------------
      -- WE WILL PICK EACH CLIENTS HOLDING
      -- (OPENING POSITION OF SHARES) AS ON "CGT_DATE"
      -- -----------------------------------------------------
      FOR HOLDING_REC IN (select T.CLIENT_CODE, T.ISIN, SUM(T.VOLUME) VOLUME
                            from TEMP_CGT_CUSTODY_BALANCE T
                           group by T.CLIENT_CODE, T.ISIN ) LOOP
        ---------------------------------
        v_Holding := HOLDING_REC.VOLUME;
        v_DONE := FALSE;
        ---------------------------------
        FOR TRADE_REC IN (Select et.Trade_number,
                                 et.trade_date,
                                 cc.Settlement_date,
                                 cc.clearing_no,
                                 et.Client_code,
                                 et.Isin,
                                 s.symbol,
                                 et.Buy_or_sell,
                                 et.Volume,
                                 et.volume as REMAINING_VOLUME,
                                 et.rate,
                                 et.brk_amount,
                                 eti.cvt,
                                 (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht,
                                 Nvl(etf.fed_amount, 0) Fed_Amount
                            From Equity_trade         et,
                                 Equity_trade_info    eti,
                                 Equity_Trade_Fed_Tax etf,
                                 Clearing_Calendar    cc,
                                 security             s,
                                 client c
                           Where et.Trade_number = eti.Trade_number(+)
                             and et.Trade_number = etf.Trade_number(+)
                             and et.Clearing_No = cc.Clearing_No
                             and et.client_code = c.client_code
                             and et.isin = s.isin
                             and et.Trade_date <= (select CGT_DATE from cgt_tax_configuration)
                             and c.Main_Client_code = HOLDING_REC.CLIENT_CODE
                             and et.buy_or_sell = 'B'
                             and cc.future_period_desc is null
                             and et.trade_type != (select cot_trade from equity_system)
                             and et.trade_type != (select release_cot_trade from equity_system)
                             and et.trade_type != (select reversal_trade_type from equity_system)
                             AND s.isin = HOLDING_REC.ISIN
                             and et.isin LIKE P_ISIN
                          UNION ALL
                          -- From Future (Mark-To-Market)...
                          Select et.Trade_number,
                                 et.trade_date,
                                 cc.Settlement_date,
                                 cc.clearing_no,
                                 et.Client_code,
                                 et.Isin,
                                 s.symbol||CC.FUTURE_PERIOD_DESC AS SYMBOL,
                                 et.Buy_or_sell,
                                 et.Volume,
                                 et.volume as REMAINING_VOLUME,
                                 et.rate,
                                 et.brk_amount,
                                 eti.cvt,
                                 (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht,
                                 Nvl(etf.fed_amount, 0) Fed_Amount
                            From Equity_trade         et,
                                 Equity_trade_info    eti,
                                 Equity_Trade_Fed_Tax etf,
                                 Clearing_Calendar    cc,
                                 security             s,
                                 client               c
                           Where et.Trade_number = eti.Trade_number(+)
                             and et.Trade_number = etf.Trade_number(+)
                             and et.Clearing_No = cc.Clearing_No
                             and et.isin = s.isin
                             and et.client_code = c.client_code
                             and et.Trade_date <= (select CGT_DATE from cgt_tax_configuration)
                             and c.Main_Client_code = HOLDING_REC.CLIENT_CODE
                             and et.buy_or_sell = 'B'
                             and cc.future_period_desc is not null
                             and et.trade_type != (select cot_trade from equity_system)
                             and et.trade_type != (select release_cot_trade from equity_system)
                             and et.trade_type != (select reversal_trade_type from equity_system)
                             AND s.isin = HOLDING_REC.ISIN
                             and et.isin LIKE P_ISIN
                             and exists (select 1 from equity_order eo where eo.order_number = et.order_number and eo.market_type = (select regular_market from equity_system))
                          UNION ALL
                          -- FOR CUSTODY "IN" ACTIVITY...
                          Select cm.transaction_id as Trade_number,
                                 cm.transaction_date as trade_date,
                                 cm.transaction_date as Settlement_date,
                                 NULL clearing_no,
                                 cm.Client_code,
                                 cm.Isin,
                                 s.symbol,
                                 'B' Buy_or_sell,
                                 reg_quantity Volume,
                                 cm.reg_quantity REMAINING_VOLUME,
                                 DECODE(NVL(CME.CUSTODY_RATE,0),0,
                                       (select em.close_rate
                                          from equity_market em
                                         where em.isin = cm.isin
                                           and em.price_date =
                                               (select max(price_date)
                                                  from equity_market em1
                                                 where em1.isin = cm.isin
                                                   and em1.price_date <= cm.transaction_date)),
                                      CME.CUSTODY_RATE) RATE,
                                 0 brk_amount,
                                 0 cvt,
                                 0 Wht,
                                 0 Fed_Amount
                            From CUSTODY_MASTER CM,
                                 CUSTODY_MASTER_EXTRA CME,
                                 security s,
                                 client c
                           Where cm.isin = s.isin
                             and cm.transaction_date <= (select CGT_DATE from cgt_tax_configuration)
                             and cm.client_code = c.client_code
                             and c.Main_Client_code = HOLDING_REC.CLIENT_CODE
                             and cm.in_or_out = 'I'
                             and cm.reg_quantity > 0
                             and cm.clearing_no IS NULL
                             and cm.transaction_id = cme.transaction_id(+)
                             -- Exclude Expopsure related activities.
                             and cm.activity_code NOT IN (select ca.activity_code
                                                        from custody_activity ca
                                                       where ca.activity_code in
                                                             ((Select cs.borrow_kse_delv_actv from custody_system cs),
                                                              (select t.return_activity_code
                                                                 from custody_activity t
                                                                where t.activity_code =
                                                                      (Select cs.borrow_kse_delv_actv from custody_system cs))))
                             -- Exclude Bank related activities.
                             and cm.activity_code NOT IN (select ca.activity_code
                                                        from custody_activity ca
                                                       where ca.activity_code in
                                                             ((Select cs.bank_delv_actv from custody_system cs),
                                                              (select t.return_activity_code
                                                                 from custody_activity t
                                                                where t.activity_code =
                                                                      (Select cs.bank_delv_actv from custody_system cs))))
                             /*and ( cm.activity_code = (select cs.cdc_rcve_actv from custody_system cs)
                                 or cm.activity_code = (select cs.bonus_rcve_actv from custody_system cs)
                                 )*/
                             AND s.isin = HOLDING_REC.ISIN
                             and cm.isin LIKE P_ISIN
                           --order by trade_date desc, trade_number asc)
                           -- This has been changed so that Trade with Lowest Rate
                           -- is picked and eventually Less Tax is paid.
                           order by trade_date desc, rate asc)
        LOOP

                IF TRADE_REC.VOLUME >= V_HOLDING THEN
                   V_SHARES := V_HOLDING;
                   V_DONE := TRUE;
                ELSIF TRADE_REC.VOLUME < V_HOLDING THEN
                   V_SHARES := TRADE_REC.VOLUME;
                   V_HOLDING := V_HOLDING - V_SHARES;
                END IF;

                DBMS_OUTPUT.PUT_LINE('TRADE #: ' || TRADE_REC.TRADE_NUMBER ||' SYMBOL: ' || TRADE_REC.SYMBOL ||', VOLUME: ' || V_SHARES);
                IF P_Rem_Pos_Rep = 1 THEN
                    -- For Remaining Position Report...
                    Select Temp_CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
                            Insert into Temp_Cgt_Buy_Det
                              (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE,
                               CLEARING_NO, CLIENT_CODE, ISIN, RATE,
                               VOLUME, BRK_AMOUNT, FED_AMOUNT, CVT,
                               REM_VOLUME, CGT_ID, Symbol, WHT)
                            Values
                              (v_Buy_Det_id, TRADE_REC.TRADE_NUMBER, TRADE_REC.TRADE_DATE, TRADE_REC.Settlement_Date,
                               TRADE_REC.CLEARING_NO, (select nvl(t.main_client_code,t.client_code) from client t where t.client_code = TRADE_REC.Client_Code) , TRADE_REC.Isin, TRADE_REC.Rate,
                               V_SHARES, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Brk_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Fed_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Cvt,
                               V_SHARES, v_CGT_ID, TRADE_REC.Symbol, (V_SHARES/TRADE_REC.Volume) * NVL(TRADE_REC.WHT,0));
                    IF V_DONE = TRUE THEN
                       EXIT;
                    END IF;
                ELSE
                    -- For Actual CGT Process
                    Select CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
                            Insert into Cgt_Buy_Det
                              (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE,
                               CLEARING_NO, CLIENT_CODE, ISIN, RATE,
                               VOLUME, BRK_AMOUNT, FED_AMOUNT, CVT,
                               REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
                            Values
                              (v_Buy_Det_id, TRADE_REC.TRADE_NUMBER, TRADE_REC.TRADE_DATE, TRADE_REC.Settlement_Date,
                               TRADE_REC.CLEARING_NO, (select nvl(t.main_client_code,t.client_code) from client t where t.client_code = TRADE_REC.Client_Code), TRADE_REC.Isin, TRADE_REC.Rate,
                               V_SHARES, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Brk_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Fed_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Cvt,
                               V_SHARES, v_CGT_ID, TRADE_REC.Symbol, (V_SHARES/TRADE_REC.Volume) * NVL(TRADE_REC.WHT,0), 1);
                    IF V_DONE = TRUE THEN
                       EXIT;
                    END IF;
                END IF;
        END LOOP;
      END LOOP;
      COMMIT;
  END CGT_HOUSE_OPENING;
  --=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  -- CLIENT OPENING FROM CUSTODY HOLDING AT "CGT_DATE"
  --=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  PROCEDURE CGT_OPENING(P_Client_code   VARCHAR2,
                        P_Rem_Pos_Rep   Number default 0) IS

    v_Buy_det_Id number := 0;
    v_HOLDING    NUMBER :=0;
    V_SHARES     NUMBER :=0;
    V_DONE       BOOLEAN := FALSE;
    v_CGT_ID     CGT_BUY_DET.CGT_ID%TYPE;
    v_cgt_year   NUMBER(4) := 0;
    v_cgt_month  NUMBER(2) := 0;
    v_quarter    NUMBER(1) := 0;

  BEGIN

      select to_char(CGT_DATE, 'MM'), to_char(CGT_DATE, 'RRRR')
        into v_cgt_month, v_cgt_year
        from cgt_tax_configuration;

      -- Quarter Wise Year/Month Adjustment...
      if v_cgt_month > 0 and v_cgt_month <= 3 then
        v_cgt_year := v_cgt_year - 1;
        v_quarter := 3;
      elsif v_cgt_month > 3 and v_cgt_month <= 6 then
        v_cgt_year := v_cgt_year;
        v_quarter := 4;
      elsif v_cgt_month > 6 and v_cgt_month <= 9 then
        v_cgt_year := v_cgt_year;
        v_quarter := 1;
      else	
        v_cgt_year := v_cgt_year - 1;
        v_quarter := 2;
      end if;
      -- --------------------------------
      -- Process Execution LOG...
      -- --------------------------------
      if P_Rem_Pos_Rep = 0 then
        begin
             SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING WHERE CGT_OPENING.CLIENT_CODE = P_Client_code and CGT_OPENING.HOUSE_ACC = 0;
             insert into CGT_OPENING(CGT_ID, CLIENT_CODE, YEAR, QUARTER, FROM_DATE, TO_DATE, REMARKS, POST, LOG_ID, HOUSE_ACC)
             values (v_CGT_ID, P_Client_code, v_cgt_year, v_quarter, (select CGT_DATE from cgt_tax_configuration), (select CGT_DATE from cgt_tax_configuration), 'FIRST TIME CLIENT HOLDING (OPENING POSITIONS) BUILDING', 1, 0, 0);
        exception
          when dup_val_on_index then null;
        end;
      end if;
      -- --------------------------------
      -- Fetch Custody Balances for each client...
      EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_CUSTODY_BALANCE');
      INSERT INTO TEMP_CGT_CUSTODY_BALANCE
        (CLIENT_CODE, ISIN, VOLUME)
        SELECT Client_Code, ISIN, NETT
  FROM (SELECT dq.client_code,
               dq.isin,
               SUM(decode(custody_status_activity('ALL', dq.activity_code), 1, 0,
                          decode(dq.in_or_out, 'I', dq.quantity, -dq.quantity))) nett

          FROM (SELECT cm.activity_code,
                       cm.client_code,
                       cm.isin,
                       cm.in_or_out,
                       cm.reg_quantity quantity,
                       1 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_master cm
                 WHERE cm.transaction_Date <= (select CGT_DATE from cgt_tax_configuration)
                   and cm.client_code = decode(P_CLIENT_CODE, 'ALL', cm.client_code, P_CLIENT_CODE)
                   and cm.post = 1
                UNION ALL
                select scm.activity_code,
                       scm.client_code,
                       scm.isin,
                       scm.in_or_out,
                       sum(scm.quantity),
                       1 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  from (SELECT cm.clearing_no,
                               cm.activity_code,
                               cm.client_code,
                               cm.isin,
                               cm.in_or_out,
                               sum(cm.reg_quantity) quantity
                          FROM custody_master cm
                           WHERE cm.transaction_Date > (select CGT_DATE from cgt_tax_configuration)
                           and cm.client_code = decode(P_CLIENT_CODE, 'ALL', cm.client_code, P_CLIENT_CODE)
                           and cm.clearing_no is not null
                         group by cm.clearing_no,
                                  cm.activity_code,
                                  cm.client_code,
                                  cm.isin,
                                  cm.in_or_out
                        having(sum(cm.reg_quantity) <> 0)) scm,
                       clearing_calendar cc
                 where scm.clearing_no = cc.clearing_no
                   and cc.clearing_end_date <= (select CGT_DATE from cgt_tax_configuration)
                   and scm.client_code = decode(P_CLIENT_CODE, 'ALL', scm.client_code, P_CLIENT_CODE)
                 group by scm.activity_code,
                          scm.client_code,
                          scm.isin,
                          scm.in_or_out
                having(sum(scm.quantity) <> 0)
                UNION ALL
                SELECT cm.activity_code,
                       cm.client_code,
                       cm.isin,
                       cm.in_or_out,
                       cm.un_reg_quantity quantity,
                       0 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_master cm
                 WHERE cm.transaction_Date <= (select CGT_DATE from cgt_tax_configuration)
                   and cm.client_code = decode(P_CLIENT_CODE, 'ALL', cm.client_code, P_CLIENT_CODE)
                   and cm.post = 1
                UNION ALL
                select scm.activity_code,
                       scm.client_code,
                       scm.isin,
                       scm.in_or_out,
                       sum(scm.quantity),
                       0 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  from (SELECT cm.clearing_no,
                               cm.activity_code,
                               cm.client_code,
                               cm.isin,
                               cm.in_or_out,
                               sum(cm.un_reg_quantity) quantity
                          FROM custody_master cm
                           WHERE cm.transaction_Date > (select CGT_DATE from cgt_tax_configuration)
                           and cm.client_code = decode(P_CLIENT_CODE, 'ALL', cm.client_code, P_CLIENT_CODE)
                           and cm.clearing_no is not null
                         group by cm.clearing_no,
                                  cm.activity_code,
                                  cm.client_code,
                                  cm.isin,
                                  cm.in_or_out
                        having(sum(cm.un_reg_quantity) <> 0)) scm,
                       clearing_calendar cc
                 where scm.clearing_no = cc.clearing_no
                   and cc.clearing_end_date <= (select CGT_DATE from cgt_tax_configuration)
                   and scm.client_code = decode(P_CLIENT_CODE, 'ALL', scm.client_code, P_CLIENT_CODE)
                 group by scm.activity_code,
                          scm.client_code,
                          scm.isin,
                          scm.in_or_out
                having(sum(scm.quantity) <> 0)

                UNION ALL
                SELECT cob.activity_code,
                       cob.client_code,
                       cob.isin,
                       ca.in_or_out in_or_out,
                       reg_quantity quantity,
                       1 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_opening_balances cob, custody_activity ca
                 Where cob.activity_code = ca.activity_code
                   and cob.post = 1
                UNION ALL
                SELECT cob.activity_code,
                       cob.client_code,
                       cob.isin,
                       --decode(custody_status_activity('ALL',cob.activity_code),1,'O','I') in_or_out,
                       ca.in_or_out in_or_out,
                       un_reg_quantity quantity,
                       0 registered,
                       '0' clearing_type,
                       0 net_reg_unbilled,
                       0 net_spot_unbilled,
                       0 net_forward_unbilled
                  FROM custody_opening_balances cob, custody_activity ca
                 Where cob.activity_code = ca.activity_code
                   and cob.post = 1
                UNION ALL
                select decode(s.cds_security,
                              1,
                              decode(eq.buy_or_sell,
                                     'B',
                                     ct.cdc_in_activity_code,
                                     ct.cdc_out_activity_code),
                              decode(eq.buy_or_sell,
                                     'B',
                                     ct.phy_in_activity_code,
                                     ct.phy_out_activity_code)) activity_code,
                       eq.client_code,
                       eq.isin,
                       null,
                       0 quantity,
                       0 registered,
                       cal.clearing_type,
                       decode(ct.trade_days || ct.settlement_days,
                              ct_reg.trade_days || ct_reg.settlement_days,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              0) net_reg_unbilled,
                       decode(ct.trade_days || ct.settlement_days,
                              1 || 1,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              1 || 0,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              0) net_spot_unbilled,
                       decode(ct.forwardable,
                              1,
                              decode(eq.buy_or_sell,
                                     'B',
                                     eq.volume,
                                     -eq.volume),
                              0) net_forward_unbilled
                  from equity_trade      eq,
                       clearing_calendar cal,
                       security          s,
                       clearing_type     ct,
                       equity_system     es,
                       clearing_type     ct_reg
                 where eq.clearing_no = cal.clearing_no
                   and cal.clearing_type = ct.clearing_type
                   and ct_reg.clearing_type = es.reg_clr_type
                   and eq.isin = s.isin
                   and eq.bill_number is null
                   and eq.trade_date <= (select CGT_DATE from cgt_tax_configuration)
                   and eq.client_code = decode(P_CLIENT_CODE, 'ALL', eq.client_code, P_CLIENT_CODE)
                   and eq.post = 1) dq,
               custody_activity_group cag,
               custody_activity ca,
               custody_system cs,
               (select em.isin, em.close_rate, em.price_date
                  from equity_market em,
                       (select isin, max(price_date) P_date
                          from equity_market
                         where price_date <= (select CGT_DATE from cgt_tax_configuration)
                         group by isin) temp
                 where em.isin = temp.isin
                   and em.price_date = temp.p_date) EM,
               security,
               executive_clients,
               client,
               system,
               locations,
               CLIENT_INFO CI
         WHERE ca.activity_group = cag.activity_group
           and dq.activity_code = ca.activity_code
           and dq.isin = security.isin
           and dq.client_code = client.client_code
           and system.location_code = locations.location_code
           and security.isin = em.isin(+)
           AND dq.CLIENT_CODE = CI.CLIENT_CODE(+)
           and dq.client_code = executive_clients.client_code(+)
           and dq.client_code = decode(P_CLIENT_CODE, 'ALL', dq.client_code, P_CLIENT_CODE)
           and ca.post = 1
           and cag.post = 1
         GROUP BY dq.client_code,
                  client.client_name,
                  cdc_group_code,
                  cdc_investor_code,
                  dq.isin,
                  security.security_name,
                  em.close_rate)
 WHERE nett > 0
order by CLIENT_CODE, ISIN;

      -- -----------------------------------------------------
      -- WE WILL PICK EACH CLIENTS HOLDING
      -- (OPENING POSITION OF SHARES) AS ON "CGT_DATE"
      -- -----------------------------------------------------
      FOR HOLDING_REC IN (select T.CLIENT_CODE, T.ISIN, T.VOLUME
                            from TEMP_CGT_CUSTODY_BALANCE T) LOOP
        ---------------------------------
        v_Holding := HOLDING_REC.VOLUME;
        v_DONE := FALSE;
        ---------------------------------
        FOR TRADE_REC IN (Select et.Trade_number,
                                 et.trade_date,
                                 cc.Settlement_date,
                                 cc.clearing_no,
                                 et.Client_code,
                                 et.Isin,
                                 s.symbol,
                                 et.Buy_or_sell,
                                 et.Volume,
                                 et.volume as REMAINING_VOLUME,
                                 et.rate,
                                 et.brk_amount,
                                 eti.cvt,
                                 (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht,
                                 Nvl(etf.fed_amount, 0) Fed_Amount
                            From Equity_trade         et,
                                 Equity_trade_info    eti,
                                 Equity_Trade_Fed_Tax etf,
                                 Clearing_Calendar    cc,
                                 security             s
                           Where et.Trade_number = eti.Trade_number(+)
                             and et.Trade_number = etf.Trade_number(+)
                             and et.Clearing_No = cc.Clearing_No
                             and et.isin = s.isin
                             and et.Trade_date <= (select CGT_DATE from cgt_tax_configuration)
                             and et.Client_code = HOLDING_REC.CLIENT_CODE
                             and et.buy_or_sell = 'B'
                             and cc.future_period_desc is null
                             and et.trade_type != (select cot_trade from equity_system)
                             and et.trade_type != (select release_cot_trade from equity_system)
                             and et.trade_type != (select reversal_trade_type from equity_system)
                             AND s.isin = HOLDING_REC.ISIN
                          UNION ALL
                          -- From Future (Mark-To-Market)...
                          Select et.Trade_number,
                                 et.trade_date,
                                 cc.Settlement_date,
                                 cc.clearing_no,
                                 et.Client_code,
                                 et.Isin,
                                 s.symbol||CC.FUTURE_PERIOD_DESC AS SYMBOL,
                                 et.Buy_or_sell,
                                 et.Volume,
                                 et.volume as REMAINING_VOLUME,
                                 et.rate,
                                 et.brk_amount,
                                 eti.cvt,
                                 (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht,
                                 Nvl(etf.fed_amount, 0) Fed_Amount
                            From Equity_trade         et,
                                 Equity_trade_info    eti,
                                 Equity_Trade_Fed_Tax etf,
                                 Clearing_Calendar    cc,
                                 security             s
                           Where et.Trade_number = eti.Trade_number(+)
                             and et.Trade_number = etf.Trade_number(+)
                             and et.Clearing_No = cc.Clearing_No
                             and et.isin = s.isin
                             and et.Trade_date <= (select CGT_DATE from cgt_tax_configuration)
                             and et.Client_code = HOLDING_REC.CLIENT_CODE
                             and et.buy_or_sell = 'B'
                             and cc.future_period_desc is not null
                             and et.trade_type != (select cot_trade from equity_system)
                             and et.trade_type != (select release_cot_trade from equity_system)
                             and et.trade_type != (select reversal_trade_type from equity_system)
                             AND s.isin = HOLDING_REC.ISIN
                             and exists (select 1 from equity_order eo where eo.order_number = et.order_number and eo.market_type = (select regular_market from equity_system))
                          UNION ALL

                          -- FOR CUSTODY "IN" ACTIVITY...
                          Select cm.transaction_id as Trade_number,
                                 cm.transaction_date as trade_date,
                                 cm.transaction_date as Settlement_date,
                                 NULL clearing_no,
                                 cm.Client_code,
                                 cm.Isin,
                                 s.symbol,
                                 'B' Buy_or_sell,
                                 reg_quantity Volume,
                                 cm.reg_quantity REMAINING_VOLUME,
                                 DECODE(NVL(CME.CUSTODY_RATE,0),0,
                                       (select em.close_rate
                                          from equity_market em
                                         where em.isin = cm.isin
                                           and em.price_date =
                                               (select max(price_date)
                                                  from equity_market em1
                                                 where em1.isin = cm.isin
                                                   and em1.price_date <= cm.transaction_date)),
                                      CME.CUSTODY_RATE) RATE,
                                 0 brk_amount,
                                 0 cvt,
                                 0 Wht,
                                 0 Fed_Amount
                            From CUSTODY_MASTER CM,
                                 CUSTODY_MASTER_EXTRA CME,
                                 security s
                           Where cm.isin = s.isin
                             and cm.transaction_date <= (select CGT_DATE from cgt_tax_configuration)
                             and cm.Client_code = HOLDING_REC.CLIENT_CODE
                             and cm.in_or_out = 'I'
                             and cm.reg_quantity > 0
                             and cm.clearing_no IS NULL
                             and cm.transaction_id = cme.transaction_id(+)
                             -- Exclude Expopsure related activities.
                             and cm.activity_code NOT IN (select ca.activity_code
                                                        from custody_activity ca
                                                       where ca.activity_code in
                                                             ((Select cs.borrow_kse_delv_actv from custody_system cs),
                                                              (select t.return_activity_code
                                                                 from custody_activity t
                                                                where t.activity_code =
                                                                      (Select cs.borrow_kse_delv_actv from custody_system cs))))
                             -- Exclude Bank related activities.
                             and cm.activity_code NOT IN (select ca.activity_code
                                                        from custody_activity ca
                                                       where ca.activity_code in
                                                             ((Select cs.bank_delv_actv from custody_system cs),
                                                              (select t.return_activity_code
                                                                 from custody_activity t
                                                                where t.activity_code =
                                                                      (Select cs.bank_delv_actv from custody_system cs))))
                             /*and ( cm.activity_code = (select cs.cdc_rcve_actv from custody_system cs)
                                 or cm.activity_code = (select cs.bonus_rcve_actv from custody_system cs)
                                 )*/
                             AND s.isin = HOLDING_REC.ISIN
                           --order by trade_date desc, trade_number asc)
                           -- This has been changed so that Trade with Lowest Rate
                           -- is picked and eventually Less Tax is paid.
                           order by trade_date desc, rate asc)
        LOOP

                IF TRADE_REC.VOLUME >= V_HOLDING THEN
                   V_SHARES := V_HOLDING;
                   V_DONE := TRUE;
                ELSIF TRADE_REC.VOLUME < V_HOLDING THEN
                   V_SHARES := TRADE_REC.VOLUME;
                   V_HOLDING := V_HOLDING - V_SHARES;
                END IF;

                DBMS_OUTPUT.PUT_LINE('TRADE #: ' || TRADE_REC.TRADE_NUMBER ||' SYMBOL: ' || TRADE_REC.SYMBOL ||', VOLUME: ' || V_SHARES);
                IF P_Rem_Pos_Rep = 1 THEN
                    -- For Remaining Position Report...
                    Select Temp_CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
                            Insert into Temp_Cgt_Buy_Det
                              (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE,
                               CLEARING_NO, CLIENT_CODE, ISIN, RATE,
                               VOLUME, BRK_AMOUNT, FED_AMOUNT, CVT,
                               REM_VOLUME, CGT_ID, Symbol, WHT)
                            Values
                              (v_Buy_Det_id, TRADE_REC.TRADE_NUMBER, TRADE_REC.TRADE_DATE, TRADE_REC.Settlement_Date,
                               TRADE_REC.CLEARING_NO, (select nvl(t.main_client_code,t.client_code) from client t where t.client_code = TRADE_REC.Client_Code) , TRADE_REC.Isin, TRADE_REC.Rate,
                               V_SHARES, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Brk_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Fed_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Cvt,
                               V_SHARES, v_CGT_ID, TRADE_REC.Symbol, (V_SHARES/TRADE_REC.Volume) * NVL(TRADE_REC.WHT,0));
                    IF V_DONE = TRUE THEN
                       EXIT;
                    END IF;
                ELSE
                    -- For Actual CGT Process
                    Select CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
                            Insert into Cgt_Buy_Det
                              (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE,
                               CLEARING_NO, CLIENT_CODE, ISIN, RATE,
                               VOLUME, BRK_AMOUNT, FED_AMOUNT, CVT,
                               REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
                            Values
                              (v_Buy_Det_id, TRADE_REC.TRADE_NUMBER, TRADE_REC.TRADE_DATE, TRADE_REC.Settlement_Date,
                               TRADE_REC.CLEARING_NO, (select nvl(t.main_client_code,t.client_code) from client t where t.client_code = TRADE_REC.Client_Code), TRADE_REC.Isin, TRADE_REC.Rate,
                               V_SHARES, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Brk_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Fed_Amount, (V_SHARES/TRADE_REC.Volume) * TRADE_REC.Cvt,
                               V_SHARES, v_CGT_ID, TRADE_REC.Symbol, (V_SHARES/TRADE_REC.Volume) * NVL(TRADE_REC.WHT,0), 0);
                    IF V_DONE = TRUE THEN
                       EXIT;
                    END IF;
                END IF;
        END LOOP;
      END LOOP;
      COMMIT;
  END CGT_OPENING;

--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- DELETE CGT DATA, WHICH WILL THEN BE RELOADED
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  PROCEDURE DELETE_CGT_DATA(P_Client_Code VARCHAR2,
                            P_USER        VARCHAR2,
                            P_Commit      NUMBER DEFAULT 0,
                            P_HOUSE_ACC   NUMBER DEFAULT 0,
                            P_LATEST_CGT  NUMBER,
                            P_LOG_ID      NUMBER,
                            P_Err_Msg     OUT VARCHAR2) IS
  -- Local Variables...
     --v_latest_cgt           CGT_BUY_DET.cgt_id%TYPE;
     v_system_date          DATE;
  BEGIN
      SELECT system_date INTO v_system_date FROM system;
      -- Fetch the Executed duration for CGT Calculation...
      /*SELECT MAX(T.CGT_ID) AS CGT_ID
        INTO v_latest_cgt
        FROM CGT_OPENING T
       WHERE T.CLIENT_CODE = P_Client_Code
         AND T.HOUSE_ACC = P_HOUSE_ACC
         AND T.IS_ROLLBACK = 0;*/
      -- Rollback any BUY volume being netted with current quarter's SELL...
      FOR rec IN (SELECT r.cgt_reference_id, r.cgt_buy_id, r.volume_consumed, s.sell_det_id, s.volume, s.rem_volume
                    FROM CGT_SELL_DET S, cgt_buy_sell_reference r
                   WHERE S.CGT_ID = P_LATEST_CGT
                     AND S.SELL_DET_ID = R.CGT_SELL_ID
                     AND S.CLIENT_CODE = P_Client_Code)
      LOOP
          UPDATE cgt_buy_det b
             SET b.rem_volume = b.rem_volume + rec.volume_consumed
           WHERE b.buy_det_id = rec.cgt_buy_id;
      END LOOP;
      -- Delete All BUY/SELL and their REFERENCE data for the current quarter...
      DELETE FROM cgt_buy_sell_reference bsr
       WHERE EXISTS (SELECT 1 FROM cgt_sell_det s
                      WHERE s.cgt_id = P_LATEST_CGT
                        AND s.sell_det_id = bsr.cgt_sell_id
                        AND s.client_code = P_Client_Code);
      DELETE FROM cgt_sell_det s WHERE s.cgt_id = P_LATEST_CGT AND s.client_code = P_Client_Code;
      DELETE FROM cgt_buy_det b WHERE b.cgt_id = P_LATEST_CGT AND b.client_code = P_Client_Code;
      UPDATE cgt_opening co
         SET co.is_rollback = 1,
             co.remarks = 'Rollback operation performed by '||P_USER,
             co.log_id = P_LOG_ID
       WHERE co.cgt_id = P_LATEST_CGT
         AND co.client_code = P_Client_Code;
      -- Save Changes...
      IF P_COMMIT = 1 THEN
         COMMIT;
      END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      P_Err_Msg := 'Error while rollback CGT: '||SQLERRM;
  END DELETE_CGT_DATA;

--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- CALCULATE (TEMPORARY) CAPITAL GAIN-LOSS TAX CONSIDERING
-- BOTH (FUTURE/REGULAR) SYMBOLS AS SAME SECURITY AND
-- FOR THE PURPOSE OF VIEWING REMAINING POSITION REPORT. (FOR HOUSE CLIENTS ONLY)
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
PROCEDURE Calculate_House_Temp_CGT_Pos(P_To_Date     Date,
                          P_Client_code        Varchar2,
                          P_Isin               Varchar2,
                          v_RetVal             Out Number,
                          v_ErrMsg             Out Varchar2) Is

    -- ******************************************************************
    -- CGT Process will build positions from "CGT_DATE" onwards inorder
    -- to net Buy/Sell Positions, The latest SELL will be  taken and its
    -- respective BUY will be then traced back using FIFI method.
    -- ******************************************************************
    -----------------------------
    -- BUY SIDE POSITION...
    -----------------------------
    Cursor Cur_Buy_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date <= P_To_Date
                  --and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.Client_Code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'B'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)

               UNION ALL
               -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date <= P_To_Date
                  and et.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'B'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
              -- FOR CUSTODY "IN" ACTIVITY...
               Select cm.transaction_id as Trade_number,
                      cm.transaction_date as trade_date,
                      cm.transaction_date as Settlement_date,
                      NULL clearing_no,
                      cm.Client_code,
                      cm.Isin,
                      s.symbol,
                      'B' Buy_or_sell,
                      reg_quantity Volume,
                      cm.reg_quantity REMAINING_VOLUME,
                      DECODE(NVL(CME.CUSTODY_RATE,0),0,
                             (select em.close_rate
                                from equity_market em
                               where em.isin = cm.isin
                                 and em.price_date =
                                     (select max(price_date)
                                        from equity_market em1
                                       where em1.isin = cm.isin
                                         and em1.price_date <= cm.transaction_date)),
                            CME.CUSTODY_RATE) RATE,
                      0 brk_amount,
                      0 cvt,
                      0 Wht,
                      0 Fed_Amount
                 From CUSTODY_MASTER CM,
                      CUSTODY_MASTER_EXTRA CME,
                      security s
                Where cm.isin = s.isin
                  and cm.transaction_id = cme.transaction_id(+)
                  and cm.transaction_date <= P_To_Date
                  and cm.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and cm.isin LIKE P_ISIN
                  and cm.in_or_out = 'I'
                  and cm.reg_quantity > 0
                  and cm.clearing_no IS NULL
                  -- Exclude Expopsure related activities.
                 and cm.activity_code NOT IN (select ca.activity_code
                                            from custody_activity ca
                                           where ca.activity_code in
                                                 ((Select cs.borrow_kse_delv_actv from custody_system cs),
                                                  (select t.return_activity_code
                                                     from custody_activity t
                                                    where t.activity_code =
                                                          (Select cs.borrow_kse_delv_actv from custody_system cs))))
                 -- Exclude Bank related activities.
                 and cm.activity_code NOT IN (select ca.activity_code
                                            from custody_activity ca
                                           where ca.activity_code in
                                                 ((Select cs.bank_delv_actv from custody_system cs),
                                                  (select t.return_activity_code
                                                     from custody_activity t
                                                    where t.activity_code =
                                                          (Select cs.bank_delv_actv from custody_system cs))))
                  /*and (cm.activity_code = (select cs.cdc_rcve_actv from custody_system cs)
                      or cm.activity_code = (select cs.bonus_rcve_actv from custody_system cs)
                      )*/
                  AND cm.transaction_date > (select CGT_DATE from cgt_tax_configuration))
        Order by /*Client_code, */trade_date, ISIN, symbol, trade_number;
    -----------------------------
    -- SELL SIDE POSITION...
    -----------------------------
    Cursor Cur_Sell_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date <= P_To_Date
                  and et.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'S'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
                -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date <= P_To_Date
                  and et.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'S'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration))
        Order by /*Client_code, */trade_date, ISIN, symbol, trade_number;

    Type Ltyp_Client     Is Table Of Client.Client_Code%Type Index By Binary_Integer;
    Type Ltyp_Isin       Is Table Of Security.Isin%Type      Index By Binary_Integer;
    Type Ltyp_Symbol     Is Table Of Security.symbol%Type    Index By Binary_Integer;
    Type Ltyp_Volume     Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rem_Volume Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rate       Is Table Of Number(15, 4)           Index By Binary_Integer;
    Type Ltyp_Cvt        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Wht        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Brk_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Fed_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Tno        Is Table Of Equity_trade.Trade_Number%Type Index By Binary_Integer;
    Type Ltyp_Tdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Sdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Cno        Is Table Of Clearing_Calendar.Clearing_no%Type Index By Binary_Integer;
    Type Ltyp_BS         Is Table Of Char                    Index By Binary_Integer;

    v_Client_code     Ltyp_Client;
    v_Isin            Ltyp_Isin;
    v_Symbol          Ltyp_Symbol;
    v_Volume          Ltyp_Volume;
    v_Rem_Volume      Ltyp_Rem_Volume;
    v_Rate            Ltyp_Rate;
    v_Cvt             Ltyp_Cvt;
    v_Wht             Ltyp_Wht;
    v_Brk_amount      Ltyp_Brk_amount;
    v_Fed_amount      Ltyp_Fed_amount;
    v_Trade_Number    Ltyp_Tno;
    v_Trade_Date      Ltyp_Tdate;
    v_Settlement_Date Ltyp_Sdate;
    v_Clearing_no     Ltyp_Cno;
    v_Buy_Sell        Ltyp_BS;
    v_Buy_det_Id      Number(12);
    v_Sell_det_Id     Number(12);
    -- --------------------------------
    v_CGT_REF_ID      Number(15):= 0;
    v_CGT_ID          Number(15):= 0;
    v_Netting_Qty     EQUITY_TRADE.VOLUME%TYPE := 0;
    v_Flag            BOOLEAN := FALSE;

  BEGIN

    -- REFRESH POSITIONS & CALCULATE OPENING...
    EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_BUY_DET');
    EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_SELL_DET');
    EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_BUY_SELL_REFERENCE');

    CGT_HOUSE_OPENING(P_client_code, 1, '%');


    -- --------------------------------
    -- Process Execution LOG...
    -- --------------------------------
    /*SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING WHERE CGT_OPENING.CLIENT_CODE = P_Client_code;
    insert into CGT_OPENING(CGT_ID, CLIENT_CODE, FROM_DATE, TO_DATE, REMARKS, POST, LOG_ID)
    values (v_CGT_ID, P_Client_code, P_From_Date, P_To_Date, P_Remarks, 1, P_LOG_ID);
    */
    -- --------------------------------
    -- Build BUY Position...
    -- --------------------------------
    Open Cur_Buy_Position;
    Loop
      Fetch Cur_Buy_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;
      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop
        Select Temp_CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
        Insert into Temp_Cgt_Buy_Det
          (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT)
        Values
          (v_Buy_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           (select nvl(t.main_client_code,t.client_code) from client t where t.client_code = v_Client_code(Ind)), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0));
      End Loop;
      Exit When Cur_Buy_Position%Notfound;
    End Loop;
    Close Cur_Buy_Position;

    -- --------------------------------
    -- Build SELL Position...
    -- --------------------------------
    Open Cur_Sell_Position;
    Loop
      Fetch Cur_Sell_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;

      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop

        Select Temp_CGT_SelldetId_SEQ.nextval into v_Sell_det_Id from Dual;
        Insert into Temp_Cgt_Sell_Det
          (SELL_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT)
        Values
          (v_Sell_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           (select nvl(t.main_client_code,t.client_code) from client t where t.client_code = v_Client_code(Ind)), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0));
      End Loop;
      Exit When Cur_Sell_Position%Notfound;
    End Loop;
    Close Cur_Sell_Position;
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                       from Temp_cgt_sell_det s
                      where s.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                        and (s.cgt_id = v_CGT_ID or s.rem_volume <> 0)
                      order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        --change BY irfan @ 19-APR-2012
        --v_Netting_Qty := sell_rec.volume;
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from Temp_cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                           --and b.cgt_id = v_CGT_ID
                           --and b.trade_date <= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Sell Record...
    --**********************************************************************************************
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR "SHORT" SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each Short Sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                      from Temp_cgt_sell_det s
                     where s.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                       and (s.cgt_id = v_CGT_ID or s.rem_volume <> 0)
                       /*and not exists (select 1
                              from cgt_buy_sell_reference r
                             where s.sell_det_id = r.cgt_sell_id)*/
                       and exists (select 1
                              from Temp_cgt_buy_det t
                             where t.client_code = s.client_code
                               and t.isin = s.isin
                               and t.trade_date > s.trade_date
                               and t.rem_volume <> 0)
                     order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from Temp_cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                          -- and b.trade_date >= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Short Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Short Sell Record...
    --**********************************************************************************************
    -- Save Changes...
    IF v_flag = TRUE THEN
       COMMIT;
    END IF;

    v_RetVal := 0;
    v_ErrMsg := Null;
  EXCEPTION
      WHEN OTHERS THEN
      v_RetVal := -1;
      v_ErrMsg := SQLERRM;
  END Calculate_House_Temp_CGT_Pos;
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- CALCULATE (TEMPORARY) CAPITAL GAIN-LOSS TAX CONSIDERING
-- BOTH (FUTURE/REGULAR) SYMBOLS AS SAME SECURITY AND
-- FOR THE PURPOSE OF VIEWING REMAINING POSITION REPORT.
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
PROCEDURE Calculate_Temp_CGT_Pos(P_To_Date     Date,
                          P_Client_code        Varchar2,
                          P_Isin               Varchar2,
                          v_RetVal             Out Number,
                          v_ErrMsg             Out Varchar2) Is

    -- ******************************************************************
    -- CGT Process will build positions from "CGT_DATE" onwards inorder
    -- to net Buy/Sell Positions, The latest SELL will be  taken and its
    -- respective BUY will be then traced back using FIFI method.
    -- ******************************************************************
    -----------------------------
    -- BUY SIDE POSITION...
    -----------------------------
    Cursor Cur_Buy_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date <= P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'B'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)

               UNION ALL
               -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date <= P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'B'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
              -- FOR CUSTODY "IN" ACTIVITY...
               Select cm.transaction_id as Trade_number,
                      cm.transaction_date as trade_date,
                      cm.transaction_date as Settlement_date,
                      NULL clearing_no,
                      cm.Client_code,
                      cm.Isin,
                      s.symbol,
                      'B' Buy_or_sell,
                      reg_quantity Volume,
                      cm.reg_quantity REMAINING_VOLUME,
                      DECODE(NVL(CME.CUSTODY_RATE,0),0,
                             (select em.close_rate
                                from equity_market em
                               where em.isin = cm.isin
                                 and em.price_date =
                                     (select max(price_date)
                                        from equity_market em1
                                       where em1.isin = cm.isin
                                         and em1.price_date <= cm.transaction_date)),
                            CME.CUSTODY_RATE) RATE,
                      0 brk_amount,
                      0 cvt,
                      0 Wht,
                      0 Fed_Amount
                 From CUSTODY_MASTER CM,
                      CUSTODY_MASTER_EXTRA CME,
                      security s
                Where cm.isin = s.isin
                  and cm.transaction_id = cme.transaction_id(+)
                  and cm.transaction_date <= P_To_Date
                  and cm.Client_code = Decode(P_Client_code, 'ALL', cm.client_code, P_Client_code)
                  and cm.isin LIKE P_ISIN
                  and cm.in_or_out = 'I'
                  and cm.reg_quantity > 0
                  and cm.clearing_no IS NULL
                  -- Exclude Expopsure related activities.
                 and cm.activity_code NOT IN (select ca.activity_code
                                            from custody_activity ca
                                           where ca.activity_code in
                                                 ((Select cs.borrow_kse_delv_actv from custody_system cs),
                                                  (select t.return_activity_code
                                                     from custody_activity t
                                                    where t.activity_code =
                                                          (Select cs.borrow_kse_delv_actv from custody_system cs))))
                 -- Exclude Bank related activities.
                 and cm.activity_code NOT IN (select ca.activity_code
                                            from custody_activity ca
                                           where ca.activity_code in
                                                 ((Select cs.bank_delv_actv from custody_system cs),
                                                  (select t.return_activity_code
                                                     from custody_activity t
                                                    where t.activity_code =
                                                          (Select cs.bank_delv_actv from custody_system cs))))
                  /*and (cm.activity_code = (select cs.cdc_rcve_actv from custody_system cs)
                      or cm.activity_code = (select cs.bonus_rcve_actv from custody_system cs)
                      )*/
                  AND cm.transaction_date > (select CGT_DATE from cgt_tax_configuration))
        Order by Client_code, trade_date, ISIN, symbol, trade_number;
    -----------------------------
    -- SELL SIDE POSITION...
    -----------------------------
    Cursor Cur_Sell_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date <= P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'S'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
                -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date <= P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.isin LIKE P_ISIN
                  and et.buy_or_sell = 'S'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration))
        Order by Client_code, trade_date, ISIN, symbol, trade_number;

    Type Ltyp_Client     Is Table Of Client.Client_Code%Type Index By Binary_Integer;
    Type Ltyp_Isin       Is Table Of Security.Isin%Type      Index By Binary_Integer;
    Type Ltyp_Symbol     Is Table Of Security.symbol%Type    Index By Binary_Integer;
    Type Ltyp_Volume     Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rem_Volume Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rate       Is Table Of Number(15, 4)           Index By Binary_Integer;
    Type Ltyp_Cvt        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Wht        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Brk_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Fed_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Tno        Is Table Of Equity_trade.Trade_Number%Type Index By Binary_Integer;
    Type Ltyp_Tdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Sdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Cno        Is Table Of Clearing_Calendar.Clearing_no%Type Index By Binary_Integer;
    Type Ltyp_BS         Is Table Of Char                    Index By Binary_Integer;

    v_Client_code     Ltyp_Client;
    v_Isin            Ltyp_Isin;
    v_Symbol          Ltyp_Symbol;
    v_Volume          Ltyp_Volume;
    v_Rem_Volume      Ltyp_Rem_Volume;
    v_Rate            Ltyp_Rate;
    v_Cvt             Ltyp_Cvt;
    v_Wht             Ltyp_Wht;
    v_Brk_amount      Ltyp_Brk_amount;
    v_Fed_amount      Ltyp_Fed_amount;
    v_Trade_Number    Ltyp_Tno;
    v_Trade_Date      Ltyp_Tdate;
    v_Settlement_Date Ltyp_Sdate;
    v_Clearing_no     Ltyp_Cno;
    v_Buy_Sell        Ltyp_BS;
    v_Buy_det_Id      Number(12);
    v_Sell_det_Id     Number(12);
    -- --------------------------------
    v_CGT_REF_ID      Number(15):= 0;
    v_CGT_ID          Number(15):= 0;
    v_Netting_Qty     EQUITY_TRADE.VOLUME%TYPE := 0;
    v_Flag            BOOLEAN := FALSE;

  BEGIN

    -- REFRESH POSITIONS & CALCULATE OPENING...
    EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_BUY_DET');
    EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_SELL_DET');
    EXECUTE_IMMEDIATE('TRUNCATE TABLE TEMP_CGT_BUY_SELL_REFERENCE');

    CGT_OPENING(P_client_code, 1);


    -- --------------------------------
    -- Process Execution LOG...
    -- --------------------------------
    /*SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING WHERE CGT_OPENING.CLIENT_CODE = P_Client_code;
    insert into CGT_OPENING(CGT_ID, CLIENT_CODE, FROM_DATE, TO_DATE, REMARKS, POST, LOG_ID)
    values (v_CGT_ID, P_Client_code, P_From_Date, P_To_Date, P_Remarks, 1, P_LOG_ID);
    */
    -- --------------------------------
    -- Build BUY Position...
    -- --------------------------------
    Open Cur_Buy_Position;
    Loop
      Fetch Cur_Buy_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;
      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop
        Select Temp_CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
        Insert into Temp_Cgt_Buy_Det
          (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT)
        Values
          (v_Buy_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           v_Client_code(Ind), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0));
      End Loop;
      Exit When Cur_Buy_Position%Notfound;
    End Loop;
    Close Cur_Buy_Position;

    -- --------------------------------
    -- Build SELL Position...
    -- --------------------------------
    Open Cur_Sell_Position;
    Loop
      Fetch Cur_Sell_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;

      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop

        Select Temp_CGT_SelldetId_SEQ.nextval into v_Sell_det_Id from Dual;
        Insert into Temp_Cgt_Sell_Det
          (SELL_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT)
        Values
          (v_Sell_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           v_Client_code(Ind), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0));
      End Loop;
      Exit When Cur_Sell_Position%Notfound;
    End Loop;
    Close Cur_Sell_Position;
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                       from Temp_cgt_sell_det s
                      where s.client_code = DECODE (P_Client_code, 'ALL', s.client_code, P_Client_code)
                        and (s.cgt_id = v_CGT_ID or s.rem_volume <> 0)
                      order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        --change BY irfan @ 19-APR-2012
        --v_Netting_Qty := sell_rec.volume;
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from Temp_cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                           --and b.cgt_id = v_CGT_ID
                           --and b.trade_date <= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Sell Record...
    --**********************************************************************************************
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR "SHORT" SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each Short Sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                      from Temp_cgt_sell_det s
                     where s.client_code = DECODE(P_Client_code, 'ALL', s.client_code, P_Client_code)
                       and (s.cgt_id = v_CGT_ID or s.rem_volume <> 0)
                       /*and not exists (select 1
                              from cgt_buy_sell_reference r
                             where s.sell_det_id = r.cgt_sell_id)*/
                       and exists (select 1
                              from Temp_cgt_buy_det t
                             where t.client_code = s.client_code
                               and t.isin = s.isin
                               and t.trade_date > s.trade_date
                               and t.rem_volume <> 0)
                     order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from Temp_cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                          -- and b.trade_date >= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM Temp_CGT_BUY_SELL_REFERENCE;
               Insert Into Temp_CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update Temp_cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Short Sell Record...
               update Temp_cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Short Sell Record...
    --**********************************************************************************************
    -- Save Changes...
    IF v_flag = TRUE THEN
       COMMIT;
    END IF;

    v_RetVal := 0;
    v_ErrMsg := Null;
  EXCEPTION
      WHEN OTHERS THEN
      v_RetVal := -1;
      v_ErrMsg := SQLERRM;
  END Calculate_Temp_CGT_Pos;
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- CALCULATE CAPITAL GAIN-LOSS TAX CONSIDERING BOTH (FUTURE/REGULAR) SYMBOLS AS SAME SECURITY
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  PROCEDURE Calculate_House_CGT(P_From_Date   Date,
                          P_To_Date     Date,
                          P_Client_code Varchar2,
                          P_Main_Client Varchar2,
                          P_Year        Number,
                          P_Quarter     Number,
                          P_LOG_ID      NUMBER,
                          P_Remarks     VARCHAR2,
                          P_Commit      NUMBER DEFAULT 0,
                          v_RetVal      Out Number,
                          v_ErrMsg      Out Varchar2) Is

    -- ******************************************************************
    -- CGT Process will build positions from "CGT_DATE" onwards inorder
    -- to net Buy/Sell Positions, The latest SELL will be  taken and its
    -- respective BUY will be then traced back using FIFI method.
    -- ******************************************************************
    -----------------------------
    -- BUY SIDE POSITION...
    -----------------------------
    Cursor Cur_Buy_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date Between P_From_Date and P_To_Date
                  --and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.buy_or_sell = 'B'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)

               UNION ALL
               -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date Between P_From_Date and P_To_Date
                  --and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.buy_or_sell = 'B'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
              -- FOR CUSTODY "IN" ACTIVITY...
               Select cm.transaction_id as Trade_number,
                      cm.transaction_date as trade_date,
                      cm.transaction_date as Settlement_date,
                      NULL clearing_no,
                      cm.Client_code,
                      cm.Isin,
                      s.symbol,
                      'B' Buy_or_sell,
                      reg_quantity Volume,
                      cm.reg_quantity REMAINING_VOLUME,
                      DECODE(NVL(CME.CUSTODY_RATE,0),0,
                             (select em.close_rate
                                from equity_market em
                               where em.isin = cm.isin
                                 and em.price_date =
                                     (select max(price_date)
                                        from equity_market em1
                                       where em1.isin = cm.isin
                                         and em1.price_date <= cm.transaction_date)),
                            CME.CUSTODY_RATE) RATE,
                      0 brk_amount,
                      0 cvt,
                      0 Wht,
                      0 Fed_Amount
                 From CUSTODY_MASTER CM,
                      CUSTODY_MASTER_EXTRA CME,
                      security s
                Where cm.isin = s.isin
                  and cm.transaction_id = cme.transaction_id(+)
                  and cm.transaction_date Between P_From_Date and P_To_Date
                  --and cm.Client_code = Decode(P_Client_code, 'ALL', cm.client_code, P_Client_code)
                  and cm.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and cm.in_or_out = 'I'
                  and cm.reg_quantity > 0
                  and cm.clearing_no IS NULL
                  -- Exclude Expopsure related activities.
                   and cm.activity_code NOT IN (select ca.activity_code
                                              from custody_activity ca
                                             where ca.activity_code in
                                                   ((Select cs.borrow_kse_delv_actv from custody_system cs),
                                                    (select t.return_activity_code
                                                       from custody_activity t
                                                      where t.activity_code =
                                                            (Select cs.borrow_kse_delv_actv from custody_system cs))))
                   -- Exclude Bank related activities.
                   and cm.activity_code NOT IN (select ca.activity_code
                                              from custody_activity ca
                                             where ca.activity_code in
                                                   ((Select cs.bank_delv_actv from custody_system cs),
                                                    (select t.return_activity_code
                                                       from custody_activity t
                                                      where t.activity_code =
                                                            (Select cs.bank_delv_actv from custody_system cs))))
                  /*and ( cm.activity_code = (select cs.cdc_rcve_actv from custody_system cs)
                      or cm.activity_code = (select cs.bonus_rcve_actv from custody_system cs)
                      )*/
                  AND cm.transaction_date > (select CGT_DATE from cgt_tax_configuration))
        Order by /*Client_code, */trade_date, ISIN, symbol, trade_number;
    -----------------------------
    -- SELL SIDE POSITION...
    -----------------------------
    Cursor Cur_Sell_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date Between P_From_Date and P_To_Date
                  --and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.buy_or_sell = 'S'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
                -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date Between P_From_Date and P_To_Date
                  --and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                  and et.buy_or_sell = 'S'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration))
        Order by /*Client_code, */trade_date, ISIN, symbol, trade_number;

    Type Ltyp_Client     Is Table Of Client.Client_Code%Type Index By Binary_Integer;
    Type Ltyp_Isin       Is Table Of Security.Isin%Type      Index By Binary_Integer;
    Type Ltyp_Symbol     Is Table Of Security.symbol%Type    Index By Binary_Integer;
    Type Ltyp_Volume     Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rem_Volume Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rate       Is Table Of Number(15, 4)           Index By Binary_Integer;
    Type Ltyp_Cvt        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Wht        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Brk_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Fed_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Tno        Is Table Of Equity_trade.Trade_Number%Type Index By Binary_Integer;
    Type Ltyp_Tdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Sdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Cno        Is Table Of Clearing_Calendar.Clearing_no%Type Index By Binary_Integer;
    Type Ltyp_BS         Is Table Of Char                    Index By Binary_Integer;

    v_Client_code     Ltyp_Client;
    v_Isin            Ltyp_Isin;
    v_Symbol          Ltyp_Symbol;
    v_Volume          Ltyp_Volume;
    v_Rem_Volume      Ltyp_Rem_Volume;
    v_Rate            Ltyp_Rate;
    v_Cvt             Ltyp_Cvt;
    v_Wht             Ltyp_Wht;
    v_Brk_amount      Ltyp_Brk_amount;
    v_Fed_amount      Ltyp_Fed_amount;
    v_Trade_Number    Ltyp_Tno;
    v_Trade_Date      Ltyp_Tdate;
    v_Settlement_Date Ltyp_Sdate;
    v_Clearing_no     Ltyp_Cno;
    v_Buy_Sell        Ltyp_BS;
    v_Buy_det_Id      Number(12);
    v_Sell_det_Id     Number(12);
    -- --------------------------------
    v_CGT_REF_ID      Number(15):= 0;
    v_CGT_ID          Number(15):= 0;
    v_Netting_Qty     EQUITY_TRADE.VOLUME%TYPE := 0;
    v_Flag            BOOLEAN := FALSE;

  BEGIN

    -- --------------------------------
    -- Process Execution LOG...
    -- --------------------------------
    --SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING WHERE CGT_OPENING.CLIENT_CODE = P_Client_code;
    SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING WHERE CGT_OPENING.CLIENT_CODE = P_Main_Client;
    begin
        insert into CGT_OPENING(CGT_ID, CLIENT_CODE, YEAR, QUARTER, FROM_DATE, TO_DATE, REMARKS, POST, LOG_ID, HOUSE_ACC)
        values (v_CGT_ID, NVL(P_Main_Client,P_Client_code), P_Year, P_Quarter, P_From_Date, P_To_Date, P_Remarks, 1, P_LOG_ID, 1);
    exception
       when dup_val_on_index then
       null;
    end;

    -- --------------------------------
    -- Build BUY Position...
    -- --------------------------------
    Open Cur_Buy_Position;
    Loop
      Fetch Cur_Buy_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;
      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop
        Select CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
        Insert into Cgt_Buy_Det
          (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
        Values
          (v_Buy_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           nvl(P_main_client,v_Client_code(Ind)), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0), 1);
      End Loop;
      Exit When Cur_Buy_Position%Notfound;
    End Loop;
    Close Cur_Buy_Position;

    -- --------------------------------
    -- Build SELL Position...
    -- --------------------------------
    Open Cur_Sell_Position;
    Loop
      Fetch Cur_Sell_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;

      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop

        Select CGT_SelldetId_SEQ.nextval into v_Sell_det_Id from Dual;
        Insert into Cgt_Sell_Det
          (SELL_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
        Values
          (v_Sell_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           nvl(P_main_client,v_Client_code(Ind)), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0), 1);
      End Loop;
      Exit When Cur_Sell_Position%Notfound;
    End Loop;
    Close Cur_Sell_Position;
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                       from cgt_sell_det s
                      --where s.client_code = DECODE (P_Client_code, 'ALL', s.client_code, P_Client_code)
                      --where s.client_code = DECODE (P_Main_Client, 'ALL', s.client_code, P_Main_Client)
                      where s.client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                        and ( s.cgt_id = v_CGT_ID or s.rem_volume <> 0 )
                      order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        --change BY irfan @ 19-APR-2012
        --v_Netting_Qty := sell_rec.volume;
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                           --and b.cgt_id = v_CGT_ID
                           --and b.trade_date <= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Sell Record...
    --**********************************************************************************************
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR "SHORT" SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each Short Sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                      from cgt_sell_det s
                     --where s.client_code = DECODE(P_Client_code, 'ALL', s.client_code, P_Client_code)
                     where s.Client_code IN ('K1', 'K4', 'K5', 'K17', 'K189')
                       and (s.cgt_id = v_CGT_ID or s.rem_volume <> 0)
                       /*and not exists (select 1
                              from cgt_buy_sell_reference r
                             where s.sell_det_id = r.cgt_sell_id)*/
                       and exists (select 1
                              from cgt_buy_det t
                             where t.client_code = s.client_code
                               and t.isin = s.isin
                               and t.trade_date > s.trade_date
                               and t.rem_volume <> 0)
                     order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                          -- and b.trade_date >= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Short Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Short Sell Record...
    --**********************************************************************************************
    -- Save Changes...
    --IF v_flag = TRUE AND P_Commit = 1 THEN
    IF P_Commit = 1 THEN
       COMMIT;
    END IF;

    v_RetVal := 0;
    v_ErrMsg := Null;
  EXCEPTION
      WHEN OTHERS THEN
      v_RetVal := -1;
      v_ErrMsg := SQLERRM;
  END Calculate_House_CGT;
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- CALCULATE CAPITAL GAIN-LOSS TAX CONSIDERING BOTH (FUTURE/REGULAR) SYMBOLS AS SAME SECURITY
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  PROCEDURE Calculate_CGT(P_From_Date   Date,
                          P_To_Date     Date,
                          P_Client_code Varchar2,
                          P_Year        Number,
                          P_Quarter     Number,
                          P_LOG_ID      NUMBER,
                          P_Remarks     VARCHAR2,
                          P_Commit      NUMBER DEFAULT 0,
                          v_RetVal      Out Number,
                          v_ErrMsg      Out Varchar2) Is

    -- ******************************************************************
    -- CGT Process will build positions from "CGT_DATE" onwards inorder
    -- to net Buy/Sell Positions, The latest SELL will be  taken and its
    -- respective BUY will be then traced back using FIFI method.
    -- ******************************************************************
    -----------------------------
    -- BUY SIDE POSITION...
    -----------------------------
    Cursor Cur_Buy_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'B'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)

               UNION ALL
               -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'B'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
              -- FOR CUSTODY "IN" ACTIVITY...
               Select cm.transaction_id as Trade_number,
                      cm.transaction_date as trade_date,
                      cm.transaction_date as Settlement_date,
                      NULL clearing_no,
                      cm.Client_code,
                      cm.Isin,
                      s.symbol,
                      'B' Buy_or_sell,
                      reg_quantity Volume,
                      cm.reg_quantity REMAINING_VOLUME,
                      DECODE(NVL(CME.CUSTODY_RATE,0),0,
                             (select em.close_rate
                                from equity_market em
                               where em.isin = cm.isin
                                 and em.price_date =
                                     (select max(price_date)
                                        from equity_market em1
                                       where em1.isin = cm.isin
                                         and em1.price_date <= cm.transaction_date)),
                            CME.CUSTODY_RATE) RATE,
                      0 brk_amount,
                      0 cvt,
                      0 Wht,
                      0 Fed_Amount
                 From CUSTODY_MASTER CM,
                      CUSTODY_MASTER_EXTRA CME,
                      security s
                Where cm.isin = s.isin
                  and cm.transaction_id = cme.transaction_id(+)
                  and cm.transaction_date Between P_From_Date and P_To_Date
                  and cm.Client_code = Decode(P_Client_code, 'ALL', cm.client_code, P_Client_code)
                  and cm.in_or_out = 'I'
                  and cm.reg_quantity > 0
                  and cm.clearing_no IS NULL
                  -- Exclude Expopsure related activities.
                   and cm.activity_code NOT IN (select ca.activity_code
                                              from custody_activity ca
                                             where ca.activity_code in
                                                   ((Select cs.borrow_kse_delv_actv from custody_system cs),
                                                    (select t.return_activity_code
                                                       from custody_activity t
                                                      where t.activity_code =
                                                            (Select cs.borrow_kse_delv_actv from custody_system cs))))
                   -- Exclude Bank related activities.
                   and cm.activity_code NOT IN (select ca.activity_code
                                              from custody_activity ca
                                             where ca.activity_code in
                                                   ((Select cs.bank_delv_actv from custody_system cs),
                                                    (select t.return_activity_code
                                                       from custody_activity t
                                                      where t.activity_code =
                                                            (Select cs.bank_delv_actv from custody_system cs))))
                  /*and ( cm.activity_code = (select cs.cdc_rcve_actv from custody_system cs)
                      or cm.activity_code = (select cs.bonus_rcve_actv from custody_system cs)
                      )*/
                  AND cm.transaction_date > (select CGT_DATE from cgt_tax_configuration))
        Order by /*Client_code, */trade_date, ISIN, symbol, trade_number;
    -----------------------------
    -- SELL SIDE POSITION...
    -----------------------------
    Cursor Cur_Sell_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'S'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
                -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'S'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration))
        Order by Client_code, trade_date, ISIN, symbol, trade_number;

    Type Ltyp_Client     Is Table Of Client.Client_Code%Type Index By Binary_Integer;
    Type Ltyp_Isin       Is Table Of Security.Isin%Type      Index By Binary_Integer;
    Type Ltyp_Symbol     Is Table Of Security.symbol%Type    Index By Binary_Integer;
    Type Ltyp_Volume     Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rem_Volume Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rate       Is Table Of Number(15, 4)           Index By Binary_Integer;
    Type Ltyp_Cvt        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Wht        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Brk_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Fed_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Tno        Is Table Of Equity_trade.Trade_Number%Type Index By Binary_Integer;
    Type Ltyp_Tdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Sdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Cno        Is Table Of Clearing_Calendar.Clearing_no%Type Index By Binary_Integer;
    Type Ltyp_BS         Is Table Of Char                    Index By Binary_Integer;

    v_Client_code     Ltyp_Client;
    v_Isin            Ltyp_Isin;
    v_Symbol          Ltyp_Symbol;
    v_Volume          Ltyp_Volume;
    v_Rem_Volume      Ltyp_Rem_Volume;
    v_Rate            Ltyp_Rate;
    v_Cvt             Ltyp_Cvt;
    v_Wht             Ltyp_Wht;
    v_Brk_amount      Ltyp_Brk_amount;
    v_Fed_amount      Ltyp_Fed_amount;
    v_Trade_Number    Ltyp_Tno;
    v_Trade_Date      Ltyp_Tdate;
    v_Settlement_Date Ltyp_Sdate;
    v_Clearing_no     Ltyp_Cno;
    v_Buy_Sell        Ltyp_BS;
    v_Buy_det_Id      Number(12);
    v_Sell_det_Id     Number(12);
    -- --------------------------------
    v_CGT_REF_ID      Number(15):= 0;
    v_CGT_ID          Number(15):= 0;
    v_Netting_Qty     EQUITY_TRADE.VOLUME%TYPE := 0;
    v_Flag            BOOLEAN := FALSE;

  BEGIN

    -- --------------------------------
    -- Process Execution LOG...
    -- --------------------------------
    SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING WHERE CGT_OPENING.CLIENT_CODE = P_Client_code;
    begin
        insert into CGT_OPENING(CGT_ID, CLIENT_CODE, YEAR, QUARTER, FROM_DATE, TO_DATE, REMARKS, POST, LOG_ID, HOUSE_ACC)
        values (v_CGT_ID, P_Client_code, P_Year, P_Quarter, P_From_Date, P_To_Date, P_Remarks, 1, P_LOG_ID, 0);
    exception
       when dup_val_on_index then
       null;
    end;

    -- --------------------------------
    -- Build BUY Position...
    -- --------------------------------
    Open Cur_Buy_Position;
    Loop
      Fetch Cur_Buy_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;
      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop
        Select CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
        Insert into Cgt_Buy_Det
          (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
        Values
          (v_Buy_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           v_Client_code(Ind), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0), 0);
      End Loop;
      Exit When Cur_Buy_Position%Notfound;
    End Loop;
    Close Cur_Buy_Position;

    -- --------------------------------
    -- Build SELL Position...
    -- --------------------------------
    Open Cur_Sell_Position;
    Loop
      Fetch Cur_Sell_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;

      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop

        Select CGT_SelldetId_SEQ.nextval into v_Sell_det_Id from Dual;
        Insert into Cgt_Sell_Det
          (SELL_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
        Values
          (v_Sell_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           v_Client_code(Ind), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0), 0);
      End Loop;
      Exit When Cur_Sell_Position%Notfound;
    End Loop;
    Close Cur_Sell_Position;
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                       from cgt_sell_det s
                      where s.client_code = DECODE (P_Client_code, 'ALL', s.client_code, P_Client_code)
                        and ( s.cgt_id = v_CGT_ID or s.rem_volume <> 0 )
                      order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        --change BY irfan @ 19-APR-2012
        --v_Netting_Qty := sell_rec.volume;
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                           --and b.cgt_id = v_CGT_ID
                           --and b.trade_date <= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               EXIT;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Sell Record...
    --**********************************************************************************************
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR "SHORT" SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each Short Sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                      from cgt_sell_det s
                     where s.client_code = DECODE(P_Client_code, 'ALL', s.client_code, P_Client_code)
                       and (s.cgt_id = v_CGT_ID or s.rem_volume <> 0)
                       /*and not exists (select 1
                              from cgt_buy_sell_reference r
                             where s.sell_det_id = r.cgt_sell_id)*/
                       and exists (select 1
                              from cgt_buy_det t
                             where t.client_code = s.client_code
                               and t.isin = s.isin
                               and t.trade_date > s.trade_date
                               and t.rem_volume <> 0)
                     order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           and b.isin = sell_rec.isin
                           and b.rem_volume <> 0
                          -- and b.trade_date >= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Short Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Short Sell Record...
    --**********************************************************************************************
    -- Save Changes...
    --IF v_flag = TRUE AND P_Commit = 1 THEN
    IF P_Commit = 1 THEN
       COMMIT;
    END IF;

    v_RetVal := 0;
    v_ErrMsg := Null;
  EXCEPTION
      WHEN OTHERS THEN
      v_RetVal := -1;
      v_ErrMsg := SQLERRM;
  END Calculate_CGT;

--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- CALCULATE CAPITAL GAIN-LOSS TAX WITH RESPECT TO FUTURE SYMBOLS
-- THAT MEANS FUTURE SHALL BE NETTED WITH FUTURE AND REGULAR WITH REGULAR (SEPERATELY)
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  PROCEDURE Calculate_CGT_FUT_WISE(P_From_Date   Date,
                                   P_To_Date     Date,
                                   P_Client_code Varchar2,
                                   P_Year        Number,
                                   P_Quarter     Number,
                                   P_LOG_ID      NUMBER,
                                   P_Remarks     VARCHAR2,
                                   P_Commit      NUMBER DEFAULT 0,
                                   v_RetVal      Out Number,
                                   v_ErrMsg      Out Varchar2) Is

    -- ******************************************************************
    -- CGT Process will build positions from "CGT_DATE" onwards inorder
    -- to net Buy/Sell Positions, The latest SELL will be  taken and its
    -- respective BUY will be then traced back using FIFI method.
    -- ******************************************************************
    -----------------------------
    -- BUY SIDE POSITION...
    -----------------------------
    Cursor Cur_Buy_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'B'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)

               UNION ALL
               -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'B'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for BUY trades from 01-JUL-2009 and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
              -- FOR CUSTODY "IN" ACTIVITY...
               Select cm.transaction_id as Trade_number,
                      cm.transaction_date as trade_date,
                      cm.transaction_date as Settlement_date,
                      NULL clearing_no,
                      cm.Client_code,
                      cm.Isin,
                      s.symbol,
                      'B' Buy_or_sell,
                      reg_quantity Volume,
                      cm.reg_quantity REMAINING_VOLUME,
                      DECODE(NVL(CME.CUSTODY_RATE,0),0,
                             (select em.close_rate
                                from equity_market em
                               where em.isin = cm.isin
                                 and em.price_date =
                                     (select max(price_date)
                                        from equity_market em1
                                       where em1.isin = cm.isin
                                         and em1.price_date <= cm.transaction_date)),
                            CME.CUSTODY_RATE) RATE,
                      0 brk_amount,
                      0 cvt,
                      0 Wht,
                      0 Fed_Amount
                 From CUSTODY_MASTER CM,
                      CUSTODY_MASTER_EXTRA CME,
                      security s
                Where cm.isin = s.isin
                  and cm.transaction_id = cme.transaction_id(+)
                  and cm.transaction_date Between P_From_Date and P_To_Date
                  and cm.Client_code = Decode(P_Client_code, 'ALL', cm.client_code, P_Client_code)
                  and cm.in_or_out = 'I'
                  and cm.reg_quantity > 0
                  and cm.clearing_no IS NULL
                  -- Exclude Expopsure related activities.
                 and cm.activity_code NOT IN (select ca.activity_code
                                            from custody_activity ca
                                           where ca.activity_code in
                                                 ((Select cs.borrow_kse_delv_actv from custody_system cs),
                                                  (select t.return_activity_code
                                                     from custody_activity t
                                                    where t.activity_code =
                                                          (Select cs.borrow_kse_delv_actv from custody_system cs))))
                 -- Exclude Bank related activities.
                 and cm.activity_code NOT IN (select ca.activity_code
                                            from custody_activity ca
                                           where ca.activity_code in
                                                 ((Select cs.bank_delv_actv from custody_system cs),
                                                  (select t.return_activity_code
                                                     from custody_activity t
                                                    where t.activity_code =
                                                          (Select cs.bank_delv_actv from custody_system cs))))
                  /*and ( cm.activity_code = (select cs.cdc_rcve_actv from custody_system cs)
                      or cm.activity_code = (select cs.bonus_rcve_actv from custody_system cs)
                      )*/
                  AND cm.transaction_date > (select CGT_DATE from cgt_tax_configuration))
        Order by Client_code, symbol, trade_date, trade_number;
    -----------------------------
    -- SELL SIDE POSITION...
    -----------------------------
    Cursor Cur_Sell_Position Is
       SELECT Trade_number, trade_date, Settlement_date, clearing_no, Client_code, Isin, SYMBOL,
              Buy_or_sell, Volume, REMAINING_VOLUME, rate, brk_amount, cvt,
              Wht, Fed_Amount
        From
              (Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'S'
                  and cc.future_period_desc is null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  and et.trade_type != (select reversal_trade_type from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration)
               UNION ALL
                -- FOR FUTURE TRADES....
               Select et.Trade_number, et.trade_date, cc.Settlement_date, cc.clearing_no, et.Client_code, et.Isin, (select symbol||cc.future_period_desc from security where isin = et.isin) SYMBOL,
                      et.Buy_or_sell, et.Volume, et.volume as REMAINING_VOLUME, et.rate, et.brk_amount, eti.cvt,
                      (Nvl(eti.wht, 0) + Nvl(eti.wht_cot, 0)) Wht, Nvl(etf.fed_amount, 0) Fed_Amount
                 From Equity_trade         et,
                      Equity_trade_info    eti,
                      Equity_Trade_Fed_Tax etf,
                      Clearing_Calendar    cc
                Where et.Trade_number = eti.Trade_number(+)
                  and et.Trade_number = etf.Trade_number(+)
                  and et.Clearing_No = cc.Clearing_No
                  --and et.bill_number is not null
                  and et.Trade_date Between P_From_Date and P_To_Date
                  and et.Client_code = Decode(P_Client_code, 'ALL', et.client_code, P_Client_code)
                  and et.buy_or_sell = 'S'
                  and et.trade_type <> (select reg_trade from equity_system)
                  and et.trade_type <> (select reversal_trade_type from equity_system)
                  and cc.future_period_desc is not null
                  and et.trade_type != (select cot_trade from equity_system)
                  and et.trade_type != (select release_cot_trade from equity_system)
                  -- We will make sure that system is searched for SELL trades from "CGT_DATE" and onwards ONLY.
                  AND et.trade_date > (select CGT_DATE from cgt_tax_configuration))
        Order by Client_code, symbol, trade_date, trade_number;

    Type Ltyp_Client     Is Table Of Client.Client_Code%Type Index By Binary_Integer;
    Type Ltyp_Isin       Is Table Of Security.Isin%Type      Index By Binary_Integer;
    Type Ltyp_Symbol     Is Table Of Security.symbol%Type    Index By Binary_Integer;
    Type Ltyp_Volume     Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rem_Volume Is Table Of Number(15)              Index By Binary_Integer;
    Type Ltyp_Rate       Is Table Of Number(15, 4)           Index By Binary_Integer;
    Type Ltyp_Cvt        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Wht        Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Brk_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Fed_amount Is Table Of Number(15, 2)           Index By Binary_Integer;
    Type Ltyp_Tno        Is Table Of Equity_trade.Trade_Number%Type Index By Binary_Integer;
    Type Ltyp_Tdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Sdate      Is Table Of Date                    Index By Binary_Integer;
    Type Ltyp_Cno        Is Table Of Clearing_Calendar.Clearing_no%Type Index By Binary_Integer;
    Type Ltyp_BS         Is Table Of Char                    Index By Binary_Integer;

    v_Client_code     Ltyp_Client;
    v_Isin            Ltyp_Isin;
    v_Symbol          Ltyp_Symbol;
    v_Volume          Ltyp_Volume;
    v_Rem_Volume      Ltyp_Rem_Volume;
    v_Rate            Ltyp_Rate;
    v_Cvt             Ltyp_Cvt;
    v_Wht             Ltyp_Wht;
    v_Brk_amount      Ltyp_Brk_amount;
    v_Fed_amount      Ltyp_Fed_amount;
    v_Trade_Number    Ltyp_Tno;
    v_Trade_Date      Ltyp_Tdate;
    v_Settlement_Date Ltyp_Sdate;
    v_Clearing_no     Ltyp_Cno;
    v_Buy_Sell        Ltyp_BS;
    v_Buy_det_Id      Number(12);
    v_Sell_det_Id     Number(12);
    -- --------------------------------
    v_CGT_REF_ID      Number(15):= 0;
    v_CGT_ID          Number(15):= 0;
    v_Netting_Qty     EQUITY_TRADE.VOLUME%TYPE := 0;
    v_Flag            BOOLEAN := FALSE;

  BEGIN

    -- --------------------------------
    -- Process Execution LOG...
    -- --------------------------------
    SELECT nvl(max(CGT_ID),0) + 1 INTO v_CGT_ID FROM CGT_OPENING WHERE CGT_OPENING.CLIENT_CODE = P_Client_code;
    insert into CGT_OPENING(CGT_ID, CLIENT_CODE, FROM_DATE, TO_DATE, REMARKS, POST, LOG_ID)
    values (v_CGT_ID, P_Client_code, P_From_Date, P_To_Date, P_Remarks, 1, P_LOG_ID);

    -- --------------------------------
    -- Build BUY Position...
    -- --------------------------------
    Open Cur_Buy_Position;
    Loop
      Fetch Cur_Buy_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;
      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop
        Select CGT_BuydetId_SEQ.nextval into v_Buy_det_Id from Dual;
        Insert into Cgt_Buy_Det
          (BUY_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
        Values
          (v_Buy_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           v_Client_code(Ind), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0), 0);
      End Loop;
      Exit When Cur_Buy_Position%Notfound;
    End Loop;
    Close Cur_Buy_Position;

    -- --------------------------------
    -- Build SELL Position...
    -- --------------------------------
    Open Cur_Sell_Position;
    Loop
      Fetch Cur_Sell_Position Bulk Collect
        Into v_Trade_Number, v_Trade_date, v_Settlement_Date, v_Clearing_no, v_Client_code, v_Isin, v_Symbol, v_Buy_Sell, v_Volume, v_Rem_Volume, v_Rate, v_Brk_amount, v_Cvt, v_Wht, v_Fed_amount Limit 1000;

      if v_Client_code.Count > 0 then
        v_Flag := TRUE;
      end if;
      For Ind In 1 .. v_Client_code.Count Loop

        Select CGT_SelldetId_SEQ.nextval into v_Sell_det_Id from Dual;
        Insert into Cgt_Sell_Det
          (SELL_DET_ID, TRADE_NUMBER, TRADE_DATE, SETTLEMENT_DATE, CLEARING_NO,
           CLIENT_CODE, ISIN, RATE, VOLUME, BRK_AMOUNT, FED_AMOUNT,
           CVT, REM_VOLUME, CGT_ID, Symbol, WHT, HOUSE_ACC)
        Values
          (v_Sell_Det_id, v_Trade_Number(Ind), v_Trade_Date(Ind), v_Settlement_Date(Ind), v_Clearing_no(Ind),
           v_Client_code(Ind), v_Isin(Ind), v_Rate(Ind), v_Volume(Ind), v_Brk_amount(ind), v_Fed_amount(Ind),
           v_Cvt(Ind), v_Rem_Volume(ind), v_CGT_ID, v_Symbol(Ind), NVL(v_Wht(Ind),0), 0);
      End Loop;
      Exit When Cur_Sell_Position%Notfound;
    End Loop;
    Close Cur_Sell_Position;
    --=============================================================================--
    --:-:-:-:-:-:-:-:-:-:-:-:-:-: TRACE BUY(s) FOR SELL :-:-:-:-:-:-:-:-:-:-:-:-:-:--
    -- For each sell record there can be multiple buy records
    --=============================================================================--
    FOR SELL_REC IN (select *
                       from cgt_sell_det s
                      where s.client_code = DECODE (P_Client_code, 'ALL', s.client_code, P_Client_code)
                        and ( s.cgt_id = v_CGT_ID or s.rem_volume <> 0 )
                      order by s.trade_date, s.sell_det_id asc)
    LOOP
        dbms_output.put_line('Sell Volume: '||sell_rec.volume);
        --change BY irfan @ 19-APR-2012
        --v_Netting_Qty := sell_rec.volume;
        v_Netting_Qty := sell_rec.rem_volume;
        FOR BUY_REC IN (select *
                          from cgt_buy_det b
                         where b.client_code = sell_rec.client_code
                           --and b.isin = sell_rec.isin
                           and b.symbol = sell_rec.symbol
                           and b.rem_volume <> 0
                           --and b.cgt_id = v_CGT_ID
                           and b.trade_date <= SELL_REC.TRADE_DATE
                           order by b.trade_date, b.buy_det_id asc)
        LOOP
            IF v_Netting_Qty = 0 THEN

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;
               dbms_output.put_line('*** Sell Netted ***');
               exit;

            ELSIF v_Netting_Qty > buy_rec.rem_volume THEN
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, buy_rec.rem_volume);

               v_Netting_Qty := v_Netting_Qty - buy_rec.rem_volume;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = 0
                where b.buy_det_id = buy_rec.buy_det_id;

               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||buy_rec.rem_volume);
            ELSE
               -- Maintain CGT Process Execution LOG...
               SELECT nvl(max(CGT_REFERENCE_ID),0) + 1 INTO v_CGT_REF_ID FROM CGT_BUY_SELL_REFERENCE;
               Insert Into CGT_BUY_SELL_REFERENCE (CGT_REFERENCE_ID, CGT_SELL_ID, CGT_BUY_ID, VOLUME_CONSUMED)
               Values (v_CGT_REF_ID, sell_rec.sell_det_id, buy_rec.buy_det_id, v_Netting_Qty);

               v_Netting_Qty := buy_rec.rem_volume - v_Netting_Qty;
               -- Update Buy Record...
               update cgt_buy_det b
                  set b.sell_det_id = sell_rec.sell_det_id,
                      b.rem_volume = v_Netting_Qty
                where b.buy_det_id = buy_rec.buy_det_id;

               v_Netting_Qty := 0;
               -- Update Sell Record...
               update cgt_Sell_det s
                  set s.rem_volume = v_Netting_Qty
                where s.sell_det_id = sell_rec.sell_det_id;

               dbms_output.put_line('- Buy Volume: '||v_Netting_Qty);

            END IF;
        END LOOP; -- Buy Record...
    END LOOP; -- Sell Record...

    -- Save Changes...
    --IF v_flag = TRUE AND P_Commit = 1 THEN
    IF P_Commit = 1 THEN
       COMMIT;
    END IF;

    v_RetVal := 0;
    v_ErrMsg := Null;
  EXCEPTION
      WHEN OTHERS THEN
      v_RetVal := -1;
      v_ErrMsg := SQLERRM;
  END Calculate_CGT_FUT_WISE;
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- CGT REPORT WORKING
/*
IF FOR A PARTICULAR "SELL" ITS CORERESPONDING "BUY" TRADES ARE RANGING FROM
6 MONTHS TO 1 YEAR OR ABOVE DURATION SLOT THEN THAT "SELL" SHALL BE BREAKED DOWN
TO THE VOLUME BEING "PURCHASED" WITHIN SELECTED DURATION SLOT.
*/
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  PROCEDURE CGT_REPORT_WORK(P_Clause            VARCHAR2,
                            P_Duration_Clause   VARCHAR2,
                            P_REPORT_TYPE_DS    CHAR DEFAULT 'D',
                            P_DURATION_WISE     NUMBER DEFAULT 0,
                            P_DURATION          NUMBER) IS
       V_SQL_STMT         VARCHAR2(8000);
       V_BUY_VOLUME       NUMBER(15) := 0;
       V_SELL_VOLUME      NUMBER(15) := 0;
       V_DUR_1            NUMBER;
       V_DUR_2            NUMBER;
       V_SELL_ID          NUMBER(15) := 0;
       SELL_ROW           TEMP_CGT_REPORT%ROWTYPE;

  BEGIN

      select duration_1, duration_2
        into V_DUR_1, v_dur_2
        from cgt_tax_configuration;

      IF P_REPORT_TYPE_DS = 'S' THEN
          V_SQL_STMT := 'INSERT INTO TEMP_CGT_REPORT(CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID, PREV_SALE_PURCHASE,
                            SELL_DATE, SELL_VOLUME, SELL_NET_RATE, SELL_AMOUNT, BUY_SYMBOL, BUY_ID, BUY_DATE,
                            BUY_VOLUME, BUY_NET_RATE, BUY_AMOUNT, GAIN_LOSS, NO_OF_DAYS, CGT_PAYABLE,
                            SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_ACTUAL_RATE, BUY_ACTUAL_RATE)';
          --=================
          V_SQL_STMT := V_SQL_STMT ||' SELECT REPORT.CLIENT_CODE, REPORT.CLIENT_NAME, REPORT.SYMBOL, REPORT.SELL_SYMBOL, REPORT.SELL_ID,
                  LAG(REPORT.SELL_ID, 1, 0) OVER (ORDER BY REPORT.SELL_ID ASC) AS PREV_SALE_PURCHASE,
                  REPORT.SELL_DATE, REPORT.SELL_VOLUME, REPORT.SELL_NET_RATE, REPORT.SELL_AMOUNT,
                  REPORT.BUY_SYMBOL, REPORT.BUY_ID, REPORT.BUY_DATE, REPORT.BUY_VOLUME, REPORT.BUY_NET_RATE,
                  REPORT.BUY_AMOUNT, REPORT.GAIN_LOSS, REPORT.No_Of_Days, REPORT.CGT_PAYABLE,
                  REPORT.SELL_ACTUAL_VOLUME, REPORT.BUY_ACTUAL_VOLUME, REPORT.SELL_ACTUAL_CHARGES, REPORT.BUY_ACTUAL_CHARGES, REPORT.SELL_ACTUAL_RATE, REPORT.BUY_ACTUAL_RATE
            FROM (
            SELECT SELL_TAB.CLIENT_CODE, SELL_TAB.CLIENT_NAME, SELL_TAB.SYMBOL, SELL_TAB.SELL_SYMBOL, MAX(SELL_TAB.SELL_ID) SELL_ID,
                   SELL_TAB.SELL_DATE, SUM(SELL_TAB.SELL_VOLUME) SELL_VOLUME, SELL_TAB.SELL_NET_RATE, SUM(SELL_TAB.SELL_AMOUNT) SELL_AMOUNT,
                   SELL_TAB.BUY_SYMBOL, MAX(SELL_TAB.BUY_ID) BUY_ID, SELL_TAB.BUY_DATE, SUM(SELL_TAB.BUY_VOLUME) BUY_VOLUME,
                   SELL_TAB.BUY_NET_RATE, SUM(SELL_TAB.BUY_AMOUNT) BUY_AMOUNT, SUM(SELL_TAB.GAIN_LOSS) GAIN_LOSS,
                   SELL_TAB.No_Of_Days, SUM(SELL_TAB.CGT_PAYABLE) CGT_PAYABLE,
                   SUM(SELL_TAB.SELL_ACTUAL_VOLUME) SELL_ACTUAL_VOLUME, SUM(SELL_TAB.BUY_ACTUAL_VOLUME) BUY_ACTUAL_VOLUME, SUM(SELL_TAB.SELL_ACTUAL_CHARGES) SELL_ACTUAL_CHARGES, SUM(SELL_TAB.BUY_ACTUAL_CHARGES) BUY_ACTUAL_CHARGES, SELL_TAB.SELL_ACTUAL_RATE, SELL_TAB.BUY_ACTUAL_RATE
            FROM ( SELECT TAB.CLIENT_CODE, TAB.CLIENT_NAME, TAB.SYMBOL, TAB.SELL_SYMBOL, TAB.SELL_ID,
                   TAB.SELL_DATE, SUM(TAB.SELL_VOLUME) SELL_VOLUME,
                   TAB.SELL_NET_RATE, SUM(TAB.SELL_AMOUNT) SELL_AMOUNT, TAB.BUY_SYMBOL, MAX(TAB.BUY_ID) BUY_ID, TAB.BUY_DATE, SUM(TAB.BUY_VOLUME) BUY_VOLUME,
                   TAB.BUY_NET_RATE, SUM(TAB.BUY_AMOUNT) BUY_AMOUNT, SUM(TAB.GAIN_LOSS) GAIN_LOSS,
                   TAB.No_Of_Days, SUM(TAB.CGT_PAYABLE) CGT_PAYABLE,
                   SUM(TAB.SELL_ACTUAL_VOLUME) SELL_ACTUAL_VOLUME, SUM(TAB.BUY_ACTUAL_VOLUME) BUY_ACTUAL_VOLUME, SUM(TAB.SELL_ACTUAL_CHARGES) SELL_ACTUAL_CHARGES, SUM(TAB.BUY_ACTUAL_CHARGES) BUY_ACTUAL_CHARGES, TAB.SELL_ACTUAL_RATE, TAB.BUY_ACTUAL_RATE
            FROM (
            SELECT CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID, SELL_DATE, SELL_VOLUME,
                   ROUND((SELL_AMOUNT / SELL_VOLUME),6) AS SELL_NET_RATE,
                   SELL_AMOUNT, BUY_SYMBOL, BUY_ID, BUY_DATE, BUY_VOLUME,
                   DECODE(BUY_VOLUME,0,0,ROUND((BUY_AMOUNT / BUY_VOLUME),6)) AS BUY_NET_RATE,
                   BUY_AMOUNT, ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) AS GAIN_LOSS,
                   No_Of_Days,
                   CASE
                     -- CGT PAYABLE = GAIN_LOSS * (Particular_Duration_Tax_Ratio / 100)
                     WHEN No_Of_Days <= ctc.duration_1 THEN
                      ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_1_ratio / 100), 2)
                     WHEN No_Of_Days > ctc.duration_1 AND No_Of_Days <= ctc.duration_2 THEN
                      ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_2_ratio / 100), 2)
                     ELSE
                      0
                   END CGT_PAYABLE,
                   SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_RATE AS SELL_ACTUAL_RATE, BUY_RATE AS BUY_ACTUAL_RATE
              FROM Cgt_Tax_Configuration ctc,
              (Select summ.sell_cnt, s.client_code CLIENT_CODE, c.client_name, (Select t.symbol from security t where t.isin = s.isin) symbol,
                      s.symbol sell_symbol, s.sell_det_id SELL_ID, s.trade_date SELL_DATE, (r.volume_consumed) SELL_VOLUME, s.rate SELL_RATE,
                      ((r.volume_consumed * s.rate) - (r.volume_consumed * (s.brk_amount + s.fed_amount + s.wht + s.cvt)/s.volume)) SELL_AMOUNT,
                      b.symbol buy_symbol, b.buy_det_id BUY_ID, b.trade_date BUY_DATE,
                      r.volume_consumed BUY_VOLUME, b.rate BUY_RATE,
                      ((r.volume_consumed * b.rate) + (r.volume_consumed/b.volume)*(b.brk_amount + b.fed_amount + b.wht + b.cvt))  BUY_AMOUNT,
                      ABS((s.trade_date - b.trade_date)) AS No_Of_Days,
                      b.Rem_Volume BUY_REM_QTY, s.rem_volume SELL_REM_QTY,
                      b.volume BUY_ACTUAL_VOLUME, s.volume SELL_ACTUAL_VOLUME,
                      (s.brk_amount + s.fed_amount + s.wht + s.cvt) SELL_ACTUAL_CHARGES,
                      (b.brk_amount + b.fed_amount + b.wht + b.cvt) BUY_ACTUAL_CHARGES
                 from cgt_sell_det s, cgt_buy_sell_reference r, cgt_buy_det b, client c,
                (Select s.sell_det_id, count(s.sell_det_id) sell_cnt
                  From cgt_sell_det s, cgt_buy_sell_reference r, cgt_buy_det b
                 where b.buy_det_id = r.cgt_buy_id
                  and b.client_code = s.client_code
                  and s.sell_det_id = r.cgt_sell_id
                  and s.isin = b.isin '||P_CLAUSE||'
                group by s.sell_det_id) Summ
                Where b.buy_det_id = r.cgt_buy_id
                  and s.client_code = c.client_code
                  and b.client_code = s.client_code
                  and s.sell_det_id = r.cgt_sell_id
                  and summ.sell_det_id = s.sell_det_id
                  and s.isin = b.isin '||P_CLAUSE||'
             )
            ) TAB
            GROUP BY TAB.CLIENT_CODE, TAB.CLIENT_NAME, TAB.SYMBOL, TAB.SELL_SYMBOL, TAB.SELL_ID, TAB.SELL_DATE,
                     TAB.SELL_NET_RATE, TAB.BUY_SYMBOL, TAB.BUY_DATE, TAB.BUY_NET_RATE, TAB.No_Of_Days,
                     TAB.SELL_ACTUAL_RATE, TAB.BUY_ACTUAL_RATE) SELL_TAB
            GROUP BY SELL_TAB.CLIENT_CODE, SELL_TAB.CLIENT_NAME, SELL_TAB.SYMBOL, SELL_TAB.SELL_SYMBOL, SELL_TAB.SELL_DATE,
                     SELL_TAB.SELL_NET_RATE, SELL_TAB.BUY_SYMBOL, SELL_TAB.BUY_DATE, SELL_TAB.BUY_NET_RATE, SELL_TAB.No_Of_Days,
                     SELL_TAB.SELL_ACTUAL_RATE, SELL_TAB.BUY_ACTUAL_RATE
                   ) REPORT
            WHERE 1 = 1 '; --|| P_DURATION_CLAUSE ||'
            --======================
            if P_DURATION_WISE = 1 and P_DURATION = V_DUR_1 then
                 V_SQL_STMT := V_SQL_STMT ||' ORDER BY REPORT.CLIENT_CODE, REPORT.SYMBOL, REPORT.SELL_ID, REPORT.NO_OF_DAYS';
            elsif P_DURATION_WISE = 1 and P_DURATION = V_DUR_2 then
                V_SQL_STMT := V_SQL_STMT ||' ORDER BY REPORT.CLIENT_CODE, REPORT.SYMBOL, REPORT.SELL_ID, REPORT.BUY_ID';
            else
                V_SQL_STMT := V_SQL_STMT ||'order by REPORT.SELL_ID, REPORT.sell_date, REPORT.buy_date, REPORT.buy_id';
            end if;

      ELSE
          V_SQL_STMT := 'INSERT INTO TEMP_CGT_REPORT(CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID, PREV_SALE_PURCHASE,
                            SELL_DATE, SELL_VOLUME, SELL_NET_RATE, SELL_AMOUNT, BUY_SYMBOL, BUY_ID, BUY_DATE,
                            BUY_VOLUME, BUY_NET_RATE, BUY_AMOUNT, GAIN_LOSS, NO_OF_DAYS, CGT_PAYABLE,
                            SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_ACTUAL_RATE, BUY_ACTUAL_RATE)
          SELECT CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID,
                 LAG(SELL_ID, 1, 0) OVER (ORDER BY SELL_ID ASC) AS PREV_SALE_PURCHASE,
                 SELL_DATE, SELL_VOLUME, ROUND((SELL_AMOUNT / SELL_VOLUME),4) AS SELL_NET_RATE, SELL_AMOUNT,
                 BUY_SYMBOL, BUY_ID, BUY_DATE, BUY_VOLUME,
                 DECODE(BUY_VOLUME,0,0,ROUND((BUY_AMOUNT / BUY_VOLUME),4)) AS BUY_NET_RATE,
                 BUY_AMOUNT, ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) AS GAIN_LOSS,
                 No_Of_Days,
                 CASE
                   -- CGT PAYABLE = GAIN_LOSS * (Particular_Duration_Tax_Ratio / 100)
                   WHEN No_Of_Days <= ctc.duration_1 THEN
                    ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_1_ratio / 100), 2)
                   WHEN No_Of_Days > ctc.duration_1 AND No_Of_Days <= ctc.duration_2 THEN
                    ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_2_ratio / 100), 2)
                   ELSE
                    0
                 END CGT_PAYABLE,
                 SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_RATE AS SELL_ACTUAL_RATE, BUY_RATE AS BUY_ACTUAL_RATE
            FROM Cgt_Tax_Configuration ctc,
            (select s.client_code CLIENT_CODE, c.client_name, (select t.symbol from security t where t.isin = s.isin) symbol, s.symbol sell_symbol, s.sell_det_id SELL_ID,
                    s.trade_date SELL_DATE, r.volume_consumed SELL_VOLUME, s.rate SELL_RATE,
                    ROUND(((r.volume_consumed * s.rate) - (r.volume_consumed/s.volume)*(s.brk_amount + s.fed_amount + s.wht + s.cvt)),2)  SELL_AMOUNT,
                    b.symbol buy_symbol, b.buy_det_id BUY_ID, b.trade_date BUY_DATE, r.volume_consumed BUY_VOLUME, b.rate BUY_RATE,
                    ROUND(((r.volume_consumed * b.rate) + (r.volume_consumed/b.volume)*(b.brk_amount + b.fed_amount + b.wht + b.cvt)),2)  BUY_AMOUNT,
                    ABS((s.trade_date - b.trade_date)) AS No_Of_Days,
                    b.Rem_Volume BUY_REM_QTY, s.rem_volume SELL_REM_QTY,
                    b.volume BUY_ACTUAL_VOLUME, s.volume SELL_ACTUAL_VOLUME,
                    (s.brk_amount + s.fed_amount + s.wht + s.cvt) SELL_ACTUAL_CHARGES,
                    (b.brk_amount + b.fed_amount + b.wht + b.cvt) BUY_ACTUAL_CHARGES
               from cgt_sell_det s, cgt_buy_sell_reference r, cgt_buy_det b, client c
              where b.buy_det_id = r.cgt_buy_id
                and s.client_code = c.client_code
                and b.client_code = s.client_code
                and s.sell_det_id = r.cgt_sell_id
                and s.isin = b.isin '||P_CLAUSE||'
          )
          WHERE 1 = 1 ';
           --P_DURATION_CLAUSE||
          if P_DURATION_WISE = 1 and P_DURATION = V_DUR_1 then
               V_SQL_STMT := V_SQL_STMT ||' ORDER BY CLIENT_CODE, SYMBOL, SELL_ID, NO_OF_DAYS';
          elsif P_DURATION_WISE = 1 and P_DURATION = V_DUR_2 then
              V_SQL_STMT := V_SQL_STMT ||' ORDER BY CLIENT_CODE, SYMBOL, SELL_ID, BUY_ID';
          else
              V_SQL_STMT := V_SQL_STMT ||' order by SELL_ID, sell_date, buy_date, buy_id';
          end if;

      END IF;
      dbms_output.put_line(SUBSTR(V_SQL_STMT,1,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,1001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,1501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,2001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,2501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,3001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,3501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,4001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,4501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,5001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,5501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,6001));

      EXECUTE_IMMEDIATE('DELETE FROM temp_cgt_report');
      EXECUTE_IMMEDIATE(V_SQL_STMT);
      V_BUY_VOLUME := 0;

      IF P_DURATION_WISE = 1 THEN
          FOR REC IN (SELECT ROWID, T.* FROM TEMP_CGT_REPORT T)
          LOOP
               IF V_SELL_ID <> REC.SELL_ID THEN
                  V_SELL_ID := REC.SELL_ID;
                  V_SELL_VOLUME := REC.SELL_VOLUME;
                  V_BUY_VOLUME  := 0;
               END IF;

                  IF P_DURATION = V_DUR_1 THEN
                      IF REC.NO_OF_DAYS > 182 AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                         UPDATE TEMP_CGT_REPORT
                            SET SELL_VOLUME = V_BUY_VOLUME,
                                --SELL_AMOUNT = ROUND((V_BUY_VOLUME * REC.SELL_RATE),2)
                                SELL_AMOUNT = ROUND(((V_BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                          WHERE SELL_ID = REC.SELL_ID;
                      ELSIF REC.NO_OF_DAYS < 182 AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                         UPDATE TEMP_CGT_REPORT
                            SET SELL_VOLUME = REC.BUY_VOLUME,
                                --SELL_AMOUNT = ROUND((REC.BUY_VOLUME * REC.SELL_RATE),2)
                                SELL_AMOUNT = ROUND(((REC.BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (REC.BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                          WHERE ROWID = REC.ROWID;
                      END IF;
                  ELSIF P_DURATION = V_DUR_2 THEN
                      IF (REC.NO_OF_DAYS < 182 OR REC.NO_OF_DAYS > 365) AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                       UPDATE TEMP_CGT_REPORT
                          SET SELL_VOLUME = V_BUY_VOLUME,
                              --SELL_AMOUNT = ROUND((V_BUY_VOLUME * REC.SELL_RATE),2)
                              SELL_AMOUNT = ROUND(((V_BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                        --WHERE SELL_ID = REC.SELL_ID;
                        WHERE ROWID = REC.ROWID;
                      END IF;
                  ELSE
                      IF REC.NO_OF_DAYS < 366 AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                       UPDATE TEMP_CGT_REPORT
                          SET SELL_VOLUME = V_BUY_VOLUME,
                              --SELL_AMOUNT = ROUND((V_BUY_VOLUME * REC.SELL_RATE),2)
                              SELL_AMOUNT = ROUND(((V_BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                        --WHERE SELL_ID = REC.SELL_ID;
                        WHERE ROWID = REC.ROWID;
                      END IF;
                  END IF;
               IF V_BUY_VOLUME <> V_SELL_VOLUME THEN
                  V_BUY_VOLUME := V_BUY_VOLUME + REC.Buy_Volume;
               END IF;
          END LOOP;
      -- "ELSE" portion just added for SHORT SELL being performed in
      -- Non-Duration based report. By Irfan @ 13.MAY.2011
      ELSE
          FOR REC IN (SELECT rowid, t.* FROM TEMP_CGT_REPORT t)
          LOOP
               IF V_SELL_ID <> REC.SELL_ID THEN
                  V_SELL_ID := REC.SELL_ID;
                  V_SELL_VOLUME := REC.SELL_VOLUME;
                  V_BUY_VOLUME  := 0;
                  --select sum(t.buy_volume) into V_BUY_VOLUME from TEMP_CGT_REPORT t where t.sell_id = rec.sell_id group by t.sell_id;
               END IF;

               IF V_BUY_VOLUME <> V_SELL_VOLUME THEN
                 UPDATE TEMP_CGT_REPORT
                    SET SELL_VOLUME = REC.BUY_VOLUME,
                        --SELL_AMOUNT = ROUND((REC.BUY_VOLUME * REC.SELL_RATE),2)
                        SELL_AMOUNT = ROUND(((REC.BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (REC.BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                  --WHERE SELL_ID = REC.SELL_ID;
                  WHERE ROWID = REC.rowid;
               END IF;
               V_BUY_VOLUME := V_BUY_VOLUME + REC.Buy_Volume;
          END LOOP;
      END IF;
      -- Verify Last Report Entry....
      IF V_SELL_VOLUME > V_BUY_VOLUME THEN
         SELECT * INTO SELL_ROW FROM TEMP_CGT_REPORT WHERE SELL_ID = V_SELL_ID AND ROWNUM = 1;
         UPDATE TEMP_CGT_REPORT
            SET SELL_VOLUME = V_BUY_VOLUME,
                --SELL_AMOUNT = ROUND((V_BUY_VOLUME * SELL_ROW.SELL_RATE),2)
                SELL_AMOUNT = ROUND(((V_BUY_VOLUME * SELL_ROW.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * SELL_ROW.SELL_ACTUAL_CHARGES / SELL_ROW.SELL_ACTUAL_VOLUME)),2)
          WHERE SELL_ID = V_SELL_ID;
      END IF;
      COMMIT;
  END CGT_REPORT_WORK;

--===-=-=-=-=-=-=-=--=-=-==-=-=-==-=-=--=-=--
-- CGT REPORT WITHOUT ADDING WHT CHARGES
--====--=-==-====-=-==-=--=-=-=-=-=-=-=-=-=--
PROCEDURE CGT_WHT_FREE_REPORT_WORK(P_Clause            VARCHAR2,
                                   P_Duration_Clause   VARCHAR2,
                                   P_REPORT_TYPE_DS    CHAR DEFAULT 'D',
                                   P_DURATION_WISE     NUMBER DEFAULT 0,
                                   P_DURATION          NUMBER) IS
       V_SQL_STMT         VARCHAR2(8000);
       V_BUY_VOLUME       NUMBER(15) := 0;
       V_SELL_VOLUME      NUMBER(15) := 0;
       V_DUR_1            NUMBER;
       V_DUR_2            NUMBER;
       V_SELL_ID          NUMBER(15) := 0;
       SELL_ROW           TEMP_CGT_REPORT%ROWTYPE;

  BEGIN

      select duration_1, duration_2
        into V_DUR_1, v_dur_2
        from cgt_tax_configuration;

      IF P_REPORT_TYPE_DS = 'S' THEN
          V_SQL_STMT := 'INSERT INTO TEMP_CGT_REPORT(CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID, PREV_SALE_PURCHASE,
                            SELL_DATE, SELL_VOLUME, SELL_NET_RATE, SELL_AMOUNT, BUY_SYMBOL, BUY_ID, BUY_DATE,
                            BUY_VOLUME, BUY_NET_RATE, BUY_AMOUNT, GAIN_LOSS, NO_OF_DAYS, CGT_PAYABLE,
                            SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_ACTUAL_RATE, BUY_ACTUAL_RATE)';
          --=================
          V_SQL_STMT := V_SQL_STMT ||' SELECT REPORT.CLIENT_CODE, REPORT.CLIENT_NAME, REPORT.SYMBOL, REPORT.SELL_SYMBOL, REPORT.SELL_ID,
                  LAG(REPORT.SELL_ID, 1, 0) OVER (ORDER BY REPORT.SELL_ID ASC) AS PREV_SALE_PURCHASE,
                  REPORT.SELL_DATE, REPORT.SELL_VOLUME, REPORT.SELL_NET_RATE, REPORT.SELL_AMOUNT,
                  REPORT.BUY_SYMBOL, REPORT.BUY_ID, REPORT.BUY_DATE, REPORT.BUY_VOLUME, REPORT.BUY_NET_RATE,
                  REPORT.BUY_AMOUNT, REPORT.GAIN_LOSS, REPORT.No_Of_Days, REPORT.CGT_PAYABLE,
                  REPORT.SELL_ACTUAL_VOLUME, REPORT.BUY_ACTUAL_VOLUME, REPORT.SELL_ACTUAL_CHARGES, REPORT.BUY_ACTUAL_CHARGES, REPORT.SELL_ACTUAL_RATE, REPORT.BUY_ACTUAL_RATE
            FROM (
            SELECT SELL_TAB.CLIENT_CODE, SELL_TAB.CLIENT_NAME, SELL_TAB.SYMBOL, SELL_TAB.SELL_SYMBOL, MAX(SELL_TAB.SELL_ID) SELL_ID,
                   SELL_TAB.SELL_DATE, SUM(SELL_TAB.SELL_VOLUME) SELL_VOLUME, SELL_TAB.SELL_NET_RATE, SUM(SELL_TAB.SELL_AMOUNT) SELL_AMOUNT,
                   SELL_TAB.BUY_SYMBOL, MAX(SELL_TAB.BUY_ID) BUY_ID, SELL_TAB.BUY_DATE, SUM(SELL_TAB.BUY_VOLUME) BUY_VOLUME,
                   SELL_TAB.BUY_NET_RATE, SUM(SELL_TAB.BUY_AMOUNT) BUY_AMOUNT, SUM(SELL_TAB.GAIN_LOSS) GAIN_LOSS,
                   SELL_TAB.No_Of_Days, SUM(SELL_TAB.CGT_PAYABLE) CGT_PAYABLE,
                   SUM(SELL_TAB.SELL_ACTUAL_VOLUME) SELL_ACTUAL_VOLUME, SUM(SELL_TAB.BUY_ACTUAL_VOLUME) BUY_ACTUAL_VOLUME, SUM(SELL_TAB.SELL_ACTUAL_CHARGES) SELL_ACTUAL_CHARGES, SUM(SELL_TAB.BUY_ACTUAL_CHARGES) BUY_ACTUAL_CHARGES, SELL_TAB.SELL_ACTUAL_RATE, SELL_TAB.BUY_ACTUAL_RATE
            FROM ( SELECT TAB.CLIENT_CODE, TAB.CLIENT_NAME, TAB.SYMBOL, TAB.SELL_SYMBOL, TAB.SELL_ID,
                   TAB.SELL_DATE, SUM(TAB.SELL_VOLUME) SELL_VOLUME,
                   TAB.SELL_NET_RATE, SUM(TAB.SELL_AMOUNT) SELL_AMOUNT, TAB.BUY_SYMBOL, MAX(TAB.BUY_ID) BUY_ID, TAB.BUY_DATE, SUM(TAB.BUY_VOLUME) BUY_VOLUME,
                   TAB.BUY_NET_RATE, SUM(TAB.BUY_AMOUNT) BUY_AMOUNT, SUM(TAB.GAIN_LOSS) GAIN_LOSS,
                   TAB.No_Of_Days, SUM(TAB.CGT_PAYABLE) CGT_PAYABLE,
                   SUM(TAB.SELL_ACTUAL_VOLUME) SELL_ACTUAL_VOLUME, SUM(TAB.BUY_ACTUAL_VOLUME) BUY_ACTUAL_VOLUME, SUM(TAB.SELL_ACTUAL_CHARGES) SELL_ACTUAL_CHARGES, SUM(TAB.BUY_ACTUAL_CHARGES) BUY_ACTUAL_CHARGES, TAB.SELL_ACTUAL_RATE, TAB.BUY_ACTUAL_RATE
            FROM (
            SELECT CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID, SELL_DATE, SELL_VOLUME,
                   ROUND((SELL_AMOUNT / SELL_VOLUME),6) AS SELL_NET_RATE,
                   SELL_AMOUNT, BUY_SYMBOL, BUY_ID, BUY_DATE, BUY_VOLUME,
                   DECODE(BUY_VOLUME,0,0,ROUND((BUY_AMOUNT / BUY_VOLUME),6)) AS BUY_NET_RATE,
                   BUY_AMOUNT, ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) AS GAIN_LOSS,
                   No_Of_Days,
                   CASE
                     -- CGT PAYABLE = GAIN_LOSS * (Particular_Duration_Tax_Ratio / 100)
                     WHEN No_Of_Days <= ctc.duration_1 THEN
                      ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_1_ratio / 100), 2)
                     WHEN No_Of_Days > ctc.duration_1 AND No_Of_Days <= ctc.duration_2 THEN
                      ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_2_ratio / 100), 2)
                     ELSE
                      0
                   END CGT_PAYABLE,
                   SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_RATE AS SELL_ACTUAL_RATE, BUY_RATE AS BUY_ACTUAL_RATE
              FROM Cgt_Tax_Configuration ctc,
              (Select summ.sell_cnt, s.client_code CLIENT_CODE, c.client_name, (Select t.symbol from security t where t.isin = s.isin) symbol,
                      s.symbol sell_symbol, s.sell_det_id SELL_ID, s.trade_date SELL_DATE, (r.volume_consumed) SELL_VOLUME, s.rate SELL_RATE,
                      ((r.volume_consumed * s.rate)) SELL_AMOUNT,
                      b.symbol buy_symbol, b.buy_det_id BUY_ID, b.trade_date BUY_DATE,
                      r.volume_consumed BUY_VOLUME, b.rate BUY_RATE,
                      ((r.volume_consumed * b.rate))  BUY_AMOUNT,
                      ABS((s.trade_date - b.trade_date)) AS No_Of_Days,
                      b.Rem_Volume BUY_REM_QTY, s.rem_volume SELL_REM_QTY,
                      b.volume BUY_ACTUAL_VOLUME, s.volume SELL_ACTUAL_VOLUME,
                      0 SELL_ACTUAL_CHARGES,
                      0 BUY_ACTUAL_CHARGES
                 from cgt_sell_det s, cgt_buy_sell_reference r, cgt_buy_det b, client c,
                (Select s.sell_det_id, count(s.sell_det_id) sell_cnt
                  From cgt_sell_det s, cgt_buy_sell_reference r, cgt_buy_det b
                 where b.buy_det_id = r.cgt_buy_id
                  and b.client_code = s.client_code
                  and s.sell_det_id = r.cgt_sell_id
                  and s.isin = b.isin '||P_CLAUSE||'
                group by s.sell_det_id) Summ
                Where b.buy_det_id = r.cgt_buy_id
                  and s.client_code = c.client_code
                  and b.client_code = s.client_code
                  and s.sell_det_id = r.cgt_sell_id
                  and summ.sell_det_id = s.sell_det_id
                  and s.isin = b.isin '||P_CLAUSE||'
             )
            ) TAB
            GROUP BY TAB.CLIENT_CODE, TAB.CLIENT_NAME, TAB.SYMBOL, TAB.SELL_SYMBOL, TAB.SELL_ID, TAB.SELL_DATE,
                     TAB.SELL_NET_RATE, TAB.BUY_SYMBOL, TAB.BUY_DATE, TAB.BUY_NET_RATE, TAB.No_Of_Days,
                     TAB.SELL_ACTUAL_RATE, TAB.BUY_ACTUAL_RATE) SELL_TAB
            GROUP BY SELL_TAB.CLIENT_CODE, SELL_TAB.CLIENT_NAME, SELL_TAB.SYMBOL, SELL_TAB.SELL_SYMBOL, SELL_TAB.SELL_DATE,
                     SELL_TAB.SELL_NET_RATE, SELL_TAB.BUY_SYMBOL, SELL_TAB.BUY_DATE, SELL_TAB.BUY_NET_RATE, SELL_TAB.No_Of_Days,
                     SELL_TAB.SELL_ACTUAL_RATE, SELL_TAB.BUY_ACTUAL_RATE
                   ) REPORT
            WHERE 1 = 1 '; --|| P_DURATION_CLAUSE ||'
            --======================
            if P_DURATION_WISE = 1 and P_DURATION = V_DUR_1 then
                 V_SQL_STMT := V_SQL_STMT ||' ORDER BY REPORT.CLIENT_CODE, REPORT.SYMBOL, REPORT.SELL_ID, REPORT.NO_OF_DAYS';
            elsif P_DURATION_WISE = 1 and P_DURATION = V_DUR_2 then
                V_SQL_STMT := V_SQL_STMT ||' ORDER BY REPORT.CLIENT_CODE, REPORT.SYMBOL, REPORT.SELL_ID, REPORT.BUY_ID';
            else
                V_SQL_STMT := V_SQL_STMT ||'order by REPORT.SELL_ID, REPORT.sell_date, REPORT.buy_date, REPORT.buy_id';
            end if;

      ELSE
          V_SQL_STMT := 'INSERT INTO TEMP_CGT_REPORT(CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID, PREV_SALE_PURCHASE,
                            SELL_DATE, SELL_VOLUME, SELL_NET_RATE, SELL_AMOUNT, BUY_SYMBOL, BUY_ID, BUY_DATE,
                            BUY_VOLUME, BUY_NET_RATE, BUY_AMOUNT, GAIN_LOSS, NO_OF_DAYS, CGT_PAYABLE,
                            SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_ACTUAL_RATE, BUY_ACTUAL_RATE)
          SELECT CLIENT_CODE, CLIENT_NAME, SYMBOL, SELL_SYMBOL, SELL_ID,
                 LAG(SELL_ID, 1, 0) OVER (ORDER BY SELL_ID ASC) AS PREV_SALE_PURCHASE,
                 SELL_DATE, SELL_VOLUME, ROUND((SELL_AMOUNT / SELL_VOLUME),4) AS SELL_NET_RATE, SELL_AMOUNT,
                 BUY_SYMBOL, BUY_ID, BUY_DATE, BUY_VOLUME,
                 DECODE(BUY_VOLUME,0,0,ROUND((BUY_AMOUNT / BUY_VOLUME),4)) AS BUY_NET_RATE,
                 BUY_AMOUNT, ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) AS GAIN_LOSS,
                 No_Of_Days,
                 CASE
                   -- CGT PAYABLE = GAIN_LOSS * (Particular_Duration_Tax_Ratio / 100)
                   WHEN No_Of_Days <= ctc.duration_1 THEN
                    ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_1_ratio / 100), 2)
                   WHEN No_Of_Days > ctc.duration_1 AND No_Of_Days <= ctc.duration_2 THEN
                    ROUND((ROUND(((BUY_VOLUME * (SELL_AMOUNT / SELL_VOLUME)) - BUY_AMOUNT),2) * ctc.duration_2_ratio / 100), 2)
                   ELSE
                    0
                 END CGT_PAYABLE,
                 SELL_ACTUAL_VOLUME, BUY_ACTUAL_VOLUME, SELL_ACTUAL_CHARGES, BUY_ACTUAL_CHARGES, SELL_RATE AS SELL_ACTUAL_RATE, BUY_RATE AS BUY_ACTUAL_RATE
            FROM Cgt_Tax_Configuration ctc,
            (select s.client_code CLIENT_CODE, c.client_name, (select t.symbol from security t where t.isin = s.isin) symbol, s.symbol sell_symbol, s.sell_det_id SELL_ID,
                    s.trade_date SELL_DATE, r.volume_consumed SELL_VOLUME, s.rate SELL_RATE,
                    ROUND(((r.volume_consumed * s.rate)),2) SELL_AMOUNT,
                    b.symbol buy_symbol, b.buy_det_id BUY_ID, b.trade_date BUY_DATE, r.volume_consumed BUY_VOLUME, b.rate BUY_RATE,
                    ROUND(((r.volume_consumed * b.rate)),2)  BUY_AMOUNT,
                    ABS((s.trade_date - b.trade_date)) AS No_Of_Days,
                    b.Rem_Volume BUY_REM_QTY, s.rem_volume SELL_REM_QTY,
                    b.volume BUY_ACTUAL_VOLUME, s.volume SELL_ACTUAL_VOLUME,
                    0 SELL_ACTUAL_CHARGES,
                    0 BUY_ACTUAL_CHARGES
               from cgt_sell_det s, cgt_buy_sell_reference r, cgt_buy_det b, client c
              where b.buy_det_id = r.cgt_buy_id
                and s.client_code = c.client_code
                and b.client_code = s.client_code
                and s.sell_det_id = r.cgt_sell_id
                and s.isin = b.isin '||P_CLAUSE||'
          )
          WHERE 1 = 1 ';
           --P_DURATION_CLAUSE||
          if P_DURATION_WISE = 1 and P_DURATION = V_DUR_1 then
               V_SQL_STMT := V_SQL_STMT ||' ORDER BY CLIENT_CODE, SYMBOL, SELL_ID, NO_OF_DAYS';
          elsif P_DURATION_WISE = 1 and P_DURATION = V_DUR_2 then
              V_SQL_STMT := V_SQL_STMT ||' ORDER BY CLIENT_CODE, SYMBOL, SELL_ID, BUY_ID';
          else
              V_SQL_STMT := V_SQL_STMT ||' order by SELL_ID, sell_date, buy_date, buy_id';
          end if;

      END IF;
      dbms_output.put_line(SUBSTR(V_SQL_STMT,1,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,1001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,1501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,2001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,2501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,3001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,3501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,4001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,4501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,5001,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,5501,500));
      dbms_output.put_line(SUBSTR(V_SQL_STMT,6001,500));

      EXECUTE_IMMEDIATE('DELETE FROM temp_cgt_report');
      EXECUTE_IMMEDIATE(V_SQL_STMT);
      V_BUY_VOLUME := 0;

      IF P_DURATION_WISE = 1 THEN
          FOR REC IN (SELECT ROWID, T.* FROM TEMP_CGT_REPORT T)
          LOOP
               IF V_SELL_ID <> REC.SELL_ID THEN
                  V_SELL_ID := REC.SELL_ID;
                  V_SELL_VOLUME := REC.SELL_VOLUME;
                  V_BUY_VOLUME  := 0;
               END IF;

                  IF P_DURATION = V_DUR_1 THEN
                      IF REC.NO_OF_DAYS > 182 AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                         UPDATE TEMP_CGT_REPORT
                            SET SELL_VOLUME = V_BUY_VOLUME,
                                --SELL_AMOUNT = ROUND((V_BUY_VOLUME * REC.SELL_RATE),2)
                                SELL_AMOUNT = ROUND(((V_BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                          WHERE SELL_ID = REC.SELL_ID;
                      ELSIF REC.NO_OF_DAYS < 182 AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                         UPDATE TEMP_CGT_REPORT
                            SET SELL_VOLUME = REC.BUY_VOLUME,
                                --SELL_AMOUNT = ROUND((REC.BUY_VOLUME * REC.SELL_RATE),2)
                                SELL_AMOUNT = ROUND(((REC.BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (REC.BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                          WHERE ROWID = REC.ROWID;
                      END IF;
                  ELSIF P_DURATION = V_DUR_2 THEN
                      IF (REC.NO_OF_DAYS < 182 OR REC.NO_OF_DAYS > 365) AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                       UPDATE TEMP_CGT_REPORT
                          SET SELL_VOLUME = V_BUY_VOLUME,
                              --SELL_AMOUNT = ROUND((V_BUY_VOLUME * REC.SELL_RATE),2)
                              SELL_AMOUNT = ROUND(((V_BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                        --WHERE SELL_ID = REC.SELL_ID;
                        WHERE ROWID = REC.ROWID;
                      END IF;
                  ELSE
                      IF REC.NO_OF_DAYS < 366 AND V_BUY_VOLUME <> V_SELL_VOLUME THEN
                       UPDATE TEMP_CGT_REPORT
                          SET SELL_VOLUME = V_BUY_VOLUME,
                              --SELL_AMOUNT = ROUND((V_BUY_VOLUME * REC.SELL_RATE),2)
                              SELL_AMOUNT = ROUND(((V_BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                        --WHERE SELL_ID = REC.SELL_ID;
                        WHERE ROWID = REC.ROWID;
                      END IF;
                  END IF;
               IF V_BUY_VOLUME <> V_SELL_VOLUME THEN
                  V_BUY_VOLUME := V_BUY_VOLUME + REC.Buy_Volume;
               END IF;
          END LOOP;
      -- "ELSE" portion just added for SHORT SELL being performed in
      -- Non-Duration based report. By Irfan @ 13.MAY.2011
      ELSE
          FOR REC IN (SELECT rowid, t.* FROM TEMP_CGT_REPORT t)
          LOOP
               IF V_SELL_ID <> REC.SELL_ID THEN
                  V_SELL_ID := REC.SELL_ID;
                  V_SELL_VOLUME := REC.SELL_VOLUME;
                  V_BUY_VOLUME  := 0;
                  --select sum(t.buy_volume) into V_BUY_VOLUME from TEMP_CGT_REPORT t where t.sell_id = rec.sell_id group by t.sell_id;
               END IF;

               IF V_BUY_VOLUME <> V_SELL_VOLUME THEN
                 UPDATE TEMP_CGT_REPORT
                    SET SELL_VOLUME = REC.BUY_VOLUME,
                        --SELL_AMOUNT = ROUND((REC.BUY_VOLUME * REC.SELL_RATE),2)
                        SELL_AMOUNT = ROUND(((REC.BUY_VOLUME * REC.SELL_ACTUAL_RATE) - (REC.BUY_VOLUME * REC.SELL_ACTUAL_CHARGES / REC.SELL_ACTUAL_VOLUME)),2)
                  --WHERE SELL_ID = REC.SELL_ID;
                  WHERE ROWID = REC.rowid;
               END IF;
               V_BUY_VOLUME := V_BUY_VOLUME + REC.Buy_Volume;
          END LOOP;
      END IF;
      -- Verify Last Report Entry....
      IF V_SELL_VOLUME > V_BUY_VOLUME THEN
         SELECT * INTO SELL_ROW FROM TEMP_CGT_REPORT WHERE SELL_ID = V_SELL_ID AND ROWNUM = 1;
         UPDATE TEMP_CGT_REPORT
            SET SELL_VOLUME = V_BUY_VOLUME,
                --SELL_AMOUNT = ROUND((V_BUY_VOLUME * SELL_ROW.SELL_RATE),2)
                SELL_AMOUNT = ROUND(((V_BUY_VOLUME * SELL_ROW.SELL_ACTUAL_RATE) - (V_BUY_VOLUME * SELL_ROW.SELL_ACTUAL_CHARGES / SELL_ROW.SELL_ACTUAL_VOLUME)),2)
          WHERE SELL_ID = V_SELL_ID;
      END IF;
      COMMIT;
  END CGT_WHT_FREE_REPORT_WORK;
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- MAINTAIN CGT EXECUTION HISTORY
--=-=-=-=-=--=-=-=-=-=-=-=-=-=-=--=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

  FUNCTION CHK_CGT_CALC_HISTORY(P_Client_Code VARCHAR2, P_To_Date   Date, P_House_Acc Number Default 0) RETURN VARCHAR2
  IS
    v_flag      number(1) := 0;
    v_result    varchar2(255);
  BEGIN
    select count(t.cgt_id)
      into v_flag
      from cgt_opening t
     where t.client_code = P_Client_Code
       AND t.is_rollback = 0
       and t.house_acc = P_House_Acc
       and P_To_Date between t.from_date and t.to_date;

    if v_flag > 0 then
       v_result := 'CGT has already being executed for all or some trades in the given duration.';
    else
       v_result := 'OK';
    end if;

    RETURN v_result;
  END CHK_CGT_CALC_HISTORY;


End PCKG_CGT_UTILITY;
/
