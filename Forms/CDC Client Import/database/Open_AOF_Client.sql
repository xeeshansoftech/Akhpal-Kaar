CREATE OR REPLACE PROCEDURE Open_AOF_Client(P_APPLICATION_ID     NUMBER,
                                            P_CLIENT_TYPE        VARCHAR2,
                                            P_CLIENT_GROUP       VARCHAR2,
                                            P_TRADER             VARCHAR2,
                                            P_BRANCH             VARCHAR2,
                                            P_MAIN_CLIENT_CODE   VARCHAR2,
                                            P_NTAX_NUMBER        VARCHAR2,
                                            P_CLIENTS_SHORT_NAME VARCHAR2,
                                            P_CURRENCY_POPLIST   VARCHAR2,
                                            P_RELIGION_POPLIST   VARCHAR2,
                                            P_LANGUAGE_POPLIST   VARCHAR2,
                                            P_CDC_INVESTOR_CODE  VARCHAR2,
                                            P_CDC_GROUP_CODE     VARCHAR2,
                                            P_FED_REG_NO         VARCHAR2,
                                            P_PARTICIPANT_NO     VARCHAR2,
                                            P_PARTICIPANT_SUB_ACC VARCHAR2,
                                            P_APPLICANT_NATURE    VARCHAR2,
                                            P_LOG_ID             NUMBER,
                                            P_ERR_MSG            OUT VARCHAR2)
IS
  V_NEW_CLIENT        CLIENT.CLIENT_CODE%TYPE;
  v_online_flag       NUMBER := 0;
  v_SR_NO             NUMBER(5);

BEGIN
  /*
  This procedure is used to open an account in Backoffice against online submitted Applications.
  */
  V_NEW_CLIENT := GET_NEXT_CODE('CLIENT_CODE', 'CLIENT');
  --1. Open Client...
  INSERT INTO client(CLIENT_CODE, CLIENT_NAME, FATHER_HUSB_NAME, MOTHER_NAME, CITY_CODE, ADDRESS1,
                     NATIONALITY, ADDRESS2, /*PERMANENT_CITY, */OCCUPATION_CODE, PHONE_DIRECT, PHONE_MOBILE,
                     PHONE_OTHER, FAX_OFFICE, E_MAIL, ZAKAT_STATUS, CONFIRMATION_SEND, CONFIRMATION_MODE,
                     ACCOUNT_OPEN_DATE, EMPLOYER_BUSINESS_NAME, DESIGNATION, EMPLOYER_BUSINESS_ADDRESS,
                     DOB, GENDER, Comp_Id_Card_Number,id_card_number,nic_expiry_date, DATE_OF_ISSUE, DATE_OF_EXPIRY, PLACE_OF_ISSUE,
                     POWER_OF_ATTORNEY, BRANCH_CODE, CLIENT_TYPE, CLIENT_NATURE,bank_account_no,account_name,client_bank_name,client_bank_loc,
                     MAIN_CLIENT_CODE,ntax_number,clients_short_name,currency_code,religion_code,language_code,cdc_investor_code,cdc_group_code,fed_reg_no,
                     participant_no,participant_sub_acc, Reference, client_group, POST, LOG_ID)
  SELECT V_NEW_CLIENT, a.account_title, a.father_husband_name, null/*a.mother_name*/, cm.city_code, a.mailing_address1||' '||a.mailing_address2 || ' ' || a.mailing_address3 || ' ' ||upper(ct.country_name),
         ct.nationality, a.permreg_headoaddres1||' '||a.permreg_headoaddres2 || ' ' || a.permreg_headoaddres3 || ' ' ||upper(ct.country_name),/* a.permanent_city,*/ co.occupation_code, a.contact_no, a.local_mobile_no,
         a.contact_no, a.faz_number, a.emailaddress, decode(instr(a.zakat_status,'PAYABLE'),0,0,1), 1, DECODE(upper(a.ealert), 'YES', 'E', 'P'),
         a.opening_date, null, null, null,
         null, null, a.cnicnicop,a.cnicnicop,a.cnicnicop_expiry_date, null, a.cnicnicop_expiry_date, null,
         1, P_BRANCH, P_CLIENT_TYPE, P_APPLICANT_NATURE ,a.mandate_account_no, a.bank_account_title, b.bank_code, a.branch,
         P_MAIN_CLIENT_CODE,P_NTAX_NUMBER,P_CLIENTS_SHORT_NAME,P_CURRENCY_POPLIST,P_RELIGION_POPLIST,P_LANGUAGE_POPLIST,P_CDC_INVESTOR_CODE,P_CDC_GROUP_CODE,P_FED_REG_NO,
         P_PARTICIPANT_NO,P_PARTICIPANT_SUB_ACC, 'AOF ACCOUNT', P_CLIENT_GROUP, 1, P_LOG_ID
    FROM CLIENT_CDC_FILE a, city cm, city cp, country ct, client_occupation co, bank b
    where upper(a.permreg_headoaddres3) = upper(cp.city)
   and upper(a.mailing_address3) = upper(cm.city)
   and a.nationality = ct.nationality
   and a.bank = b.bank_name
   and upper(a.occupation_description) like upper(co.occupation_desc)
   and a.account_number = P_APPLICATION_ID;

  --2. Open Client Info...
  INSERT INTO client_info(client_code, client_lot_code, online_client)
  SELECT V_NEW_CLIENT, V_NEW_CLIENT, 1
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;


  --------------------------------------------
   insert into Client_Bank_Info
     (Client_Code, Log_Id, Post)
   values
     (V_NEW_CLIENT, P_LOG_ID, 1);

  --3. Open Branch Client...
  --a. For Equity Area
  INSERT INTO BRANCH_CLIENT(CLIENT_CODE, BRANCH_CODE, AREA_CODE, TRADER_CODE, POST, LOG_ID)
  SELECT V_NEW_CLIENT, P_BRANCH, ES.EQUITY_AREA_CODE, P_TRADER, 1, P_LOG_ID
    FROM CLIENT_CDC_FILE a, EQUITY_SYSTEM ES
   WHERE a.account_number = P_APPLICATION_ID;
  --b. For Custody Area
  INSERT INTO BRANCH_CLIENT(CLIENT_CODE, BRANCH_CODE, AREA_CODE, TRADER_CODE, POST, LOG_ID)
  SELECT V_NEW_CLIENT, P_BRANCH, cs.custody_area_code, P_TRADER, 1, P_LOG_ID
    FROM CLIENT_CDC_FILE a, Custody_System cs
   WHERE a.account_number = P_APPLICATION_ID;

  --4. Open Client Foreign...
  INSERT INTO Client_Foreign(Client_Code, Passport_Number, Date_Of_Issue, Place_Of_Issue/*, log_id, post*/)
  SELECT V_NEW_CLIENT, a.passpoc_no, a.passpoc_issue_date, a.passpoc_place_of_issue/*, P_LOG_ID, 1 */
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID
     AND upper(a.nationality) <> 'PAKISTANI';

  --5. Open Client Dividend...
  INSERT INTO Client_Dividend_Mandate(Client_Code, Bank_Name, Account_Title, Account_Number,Branch,City_Code,Log_Id,Post)
  /*SELECT V_NEW_CLIENT,d.bank_name, d.bank_account_title, d.bank_account_number,d.bank_branch, c.city_code
    FROM aof_opening_form a, aof_dividend_bank d, city c
    WHERE a.application_id = d.application_id
    and instr(upper(d.bank_address),upper(c.city)) > 0
     AND d.application_id = P_APPLICATION_ID
     AND a.dividend_mandate = 1;*/
  SELECT V_NEW_CLIENT, b.bank_name, a.bank_account_title, a.mandate_account_no,b.branch_name,bb.city,P_LOG_ID,1
    FROM CLIENT_CDC_FILE a, bank b, bank_branch bb
    WHERE b.bank_code = bb.bank_code
     AND a.account_number = P_APPLICATION_ID
     AND upper(b.bank_name) = upper(a.bank);

  --6. Open Client SCRA...
  INSERT INTO Client_Scra_Det(Client_Code, Bank_Branch, Bank_Address, Account_No)
  SELECT V_NEW_CLIENT, a.scra_bank_branch, a.scra_bank_branch||' '||a.scra_city, a.scra_account_no
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;

  --7. Open Client KYCI...
  /*V_SR_NO := GET_NEXT_CODE('SR_NO', 'CLIENT_KYC');

  INSERT INTO Client_KYC(Client_Code, Sr_No, TYPE, Residence_Status, Accommodation_Type,
                         Maritial_Status, Qualification, Source_Of_Investment, Business_Nature,
                         Tenure_Years, Tenure_Months, Gross_Income, Net_Income,
                         Reference_Name, Gender, Relation, Address, City,
                         Cnic, Expiry_Date, Phone_Res, Mobile)
  SELECT V_NEW_CLIENT, V_SR_NO, k.type, k.current_residence, k.accomodation_type,
         k.married, k.qualification, k.fund_source, k.business_nature,
         k.busi_empl_tenure_y, k.busi_empl_tenure_m,(CASE WHEN k.monthly_net_income <= 50000 THEN 0 WHEN k.monthly_net_income BETWEEN 50000 AND 100000 THEN 1 WHEN k.monthly_net_income BETWEEN 100000 AND 500000 THEN 2 WHEN k.monthly_net_income BETWEEN 500000 AND 1000000 THEN 3 ELSE 4 END) ,(CASE WHEN k.monthly_net_income <= 50000 THEN 0 WHEN k.monthly_net_income BETWEEN 50000 AND 100000 THEN 1 WHEN k.monthly_net_income BETWEEN 100000 AND 500000 THEN 2 WHEN k.monthly_net_income BETWEEN 500000 AND 1000000 THEN 3 ELSE 4 END),
         k.reference_name, 'M', k.relationship, k.residence_address, k.residence_city,
         k.cnic_nicop, k.expiry_date, k.contact_landline, k.contact_cell
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;*/

  --8. Open Client Bank Verification...
  INSERT INTO Client_Bank_Verification(Client_Code, Bank_Code, Bank_Branch, Account_No,City)
  SELECT V_NEW_CLIENT, b.bank_code, b.branch_code, a.account_number,b.city_code
    FROM CLIENT_CDC_FILE a, bank b, bank_branch bb
    WHERE b.bank_code = bb.bank_code
     AND a.account_number = P_APPLICATION_ID
     AND upper(b.bank_name) = upper(a.bank);

  --9. Open Client Authorised...
  /*V_SR_NO := GET_NEXT_CODE('SR_NO', 'CLIENT_AUTHORISED');
  INSERT INTO Client_Authorised (Client_Code, Sr_No, Name, Gender, Address, City,
                                 Phone, Cell, e_Mail, Cnic_Passport_No, Date_Of_Expiry)
  SELECT V_NEW_CLIENT, V_SR_NO, a.a, p.gender, p.residence_address, p.residence_city,
         p.contact_landline, p.contact_cell, p.email, NVL(p.cnic_nicop,p.passport_number),
         DECODE(NVL(p.cnic_nicop,''),'',p.date_of_expiry, p.expiry_date)
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;*/

  --10. Open Client Successor...
  INSERT INTO Client_Successor(Client_Code, Name, Father_Husb_Name, Relationship_Code, Address, City,
                               Phone, Fax, Cell, e_Mail, Dob, Nationality, Gender, Comp_Id_Card_Number,
                               Date_Of_Issue, Date_Of_Expiry, Place_Of_Issue, Log_Id, Post)
  SELECT V_NEW_CLIENT, a.nominee, a.relation, a.relation, null, null,
         null, null, null, null, null, null, null, a.nom_cnicnicop,
         null, a.nom_cnicnicop_expiry_date, null, P_LOG_ID, 1
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;

  --10. Open Client Successor...
  /*INSERT INTO Client_Successor(Client_Code,Name,Relationship_Code,Id_Card_Number,Comp_Id_Card_Number,Nic_Expiry_Date)
  SELECT V_NEW_CLIENT, n.name_of_nominee, n.relationship, n.cnic_nicop, n.cnic_nicop, n.expiry_date
    FROM aof_opening_form a, aof_nominee n
   WHERE a.application_id = n.application_id
     AND n.application_id = P_APPLICATION_ID;*/

  --11. Open Cliet Joint Account...
  V_SR_NO := GET_NEXT_CODE('SR_NO', 'CLIENT_JOINT_ACCOUNT');
  INSERT INTO Client_Joint_Account(Client_Code, Sr_No, Name, Father_Husb_Name, Mother_Name, Mailing_Address, City,
                                   Permanent_Address, Phone, Cell, Office_Phone, Office_Fax, e_Mail,
                                   Employer_Business_Name, Designation, Employer_Business_Address, Occupation, Dob, Nationality,
                                   Gender, Comp_Id_Card_Number, Cnic_Passport, Date_Of_Issue, Date_Of_Expiry, Place_Of_Issue, Log_Id, Post)
  SELECT V_NEW_CLIENT, v_SR_NO, a.first_j_name, null, null, null, null,
         null, null, null, null, null, null,
         null, null, null, null, null, null,
         null, a.first_j_cnicnicop, a.first_j_passpoc_number, a.first_j_passpoc_issue_date, a.first_j_passpoc_expiry_date, a.first_j_passpoc_place_issue, P_LOG_ID, 1
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;
     
  V_SR_NO := GET_NEXT_CODE('SR_NO', 'CLIENT_JOINT_ACCOUNT');
  INSERT INTO Client_Joint_Account(Client_Code, Sr_No, Name, Father_Husb_Name, Mother_Name, Mailing_Address, City,
                                   Permanent_Address, Phone, Cell, Office_Phone, Office_Fax, e_Mail,
                                   Employer_Business_Name, Designation, Employer_Business_Address, Occupation, Dob, Nationality,
                                   Gender, Comp_Id_Card_Number, Cnic_Passport, Date_Of_Issue, Date_Of_Expiry, Place_Of_Issue, Log_Id, Post)
  SELECT V_NEW_CLIENT, v_SR_NO, a.sec_j_name, null, null, null, null,
         null, null, null, null, null, null,
         null, null, null, null, null, null,
         null, a.sec_j_cnicnicop, a.sec_j_passpoc_number, a.sec_j_passpoc_issue_date, a.sec_j_passpoc_expiry_date, a.sec_j_passpoc_place_issue, P_LOG_ID, 1
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;
     
  V_SR_NO := GET_NEXT_CODE('SR_NO', 'CLIENT_JOINT_ACCOUNT');
  INSERT INTO Client_Joint_Account(Client_Code, Sr_No, Name, Father_Husb_Name, Mother_Name, Mailing_Address, City,
                                   Permanent_Address, Phone, Cell, Office_Phone, Office_Fax, e_Mail,
                                   Employer_Business_Name, Designation, Employer_Business_Address, Occupation, Dob, Nationality,
                                   Gender, Comp_Id_Card_Number, Cnic_Passport, Date_Of_Issue, Date_Of_Expiry, Place_Of_Issue, Log_Id, Post)
  SELECT V_NEW_CLIENT, v_SR_NO, a.third_j_name, null, null, null, null,
         null, null, null, null, null, null,
         null, null, null, null, null, null,
         null, a.third_j_cnicnicop, a.third_j_passpoc_number, a.third_j_passpoc_issue_date, a.third_j_passpoc_expiry_date, a.third_j_passpoc_place_issue, P_LOG_ID, 1
    FROM CLIENT_CDC_FILE a
   WHERE a.account_number = P_APPLICATION_ID;
  --11. Open Cliet Joint Account...
  /*V_SR_NO := GET_NEXT_CODE('SR_NO', 'CLIENT_JOINT_ACCOUNT');
  INSERT INTO Client_Joint_Account(Client_Code, Name,Id_Card_Number,Comp_Id_Card_Number,Nic_Expiry_Date)
  SELECT V_NEW_CLIENT, j.applicant_name,j.cnic_nicop,j.cnic_nicop, j.date_of_expiry
    FROM aof_opening_form a, aof_joint_account j
   WHERE a.application_id = j.application_id
     AND j.application_id = P_APPLICATION_ID;*/

  --12. Open Client Bank Info...
  Update Client_Bank_Info
     set (bank_acount_code, bank_acount_title) =
         (select ab.mandate_account_no, ab.bank_account_title
            from CLIENT_CDC_FILE ab
           where ab.account_number = P_APPLICATION_ID)
   where client_code = V_NEW_CLIENT;

  --13. Map newly opened client with AOF Appliction_ID
  UPDATE CLIENT_CDC_FILE F
     SET F.CLIENT_CODE = V_NEW_CLIENT
   WHERE F.account_number = P_APPLICATION_ID;



  P_ERR_MSG := 'OK';
EXCEPTION
  WHEN OTHERS THEN
    P_ERR_MSG := 'Error in Open_AOF_Client: '||SQLERRM;
    ROLLBACK;
END Open_AOF_Client;
/
