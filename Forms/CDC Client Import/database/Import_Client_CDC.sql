create or replace package Import_Client_CDC is


  TYPE FIELDARRAY IS VARRAY(100) OF VARCHAR2(1000);

  FUNCTION GetBreakPoint(source_str VARCHAR2, delim VARCHAR2) RETURN NUMBER;

  PROCEDURE getNextToken(source_str IN OUT VARCHAR2,
                         token      OUT VARCHAR2,
                         delim      IN VARCHAR2,
                         breakpoint OUT NUMBER);

  PROCEDURE getNextToken2(source_str IN OUT VARCHAR2,
                          token      OUT VARCHAR2,
                          delim      IN VARCHAR2,
                          breakpoint OUT NUMBER);


  PROCEDURE Parser_Client_CDC(log_id         number,
                           client_row      varchar2,
                           file_date      date,
                           ignored_clients in out number,
                           invalid_clients in out number,
                           error_mess     out varchar2);


end Import_Client_CDC;
/
create or replace package body Import_Client_CDC is

  -------------------------Gets the breakpoint, which is the index of the delimeter-------------------
  ---------------------------------------------------------------------------------------------

  FUNCTION GetBreakPoint(source_str VARCHAR2, delim VARCHAR2) RETURN NUMBER IS

    returnIndex   NUMBER(3) := -1;
    temp          NUMBER(3) := -1;
    source_length NUMBER := NVL(LENGTH(SOURCE_STR), 0);
    V_CHAR        VARCHAR2(12);

  BEGIN
    V_CHAR := INSTR(SOURCE_STR,delim);
    -----------------------------------
    IF(V_CHAR = 0) THEN
      source_length := source_length+1;
    END IF;
    -----------------------------------
    IF source_length <= 0 THEN
      RETURN returnIndex;
    END IF;
    IF (source_length > 1) THEN
      FOR i IN 1 .. (source_length) LOOP
        temp := i;
        IF (SUBSTR(SOURCE_STR, i, 1) = delim) THEN
          returnIndex := i;
          EXIT;
        END IF;
      END LOOP;
    END IF;
    IF (temp = source_length) THEN
      returnIndex := temp;
    END IF;

    RETURN(returnIndex);
  END GetBreakPoint;

  -------------------------Gets the next token before the next delimeter,--------------------------------------------------------------------
  -------------------------NOTE: this fucntion midifies the source string--------------------------------------------------------------------

  PROCEDURE getNextToken(source_str IN OUT VARCHAR2,
                         token      OUT VARCHAR2,
                         delim      IN VARCHAR2,
                         breakpoint OUT NUMBER) IS

  BEGIN

    token      := ' ';
    breakpoint := -1;
    breakpoint := GetBreakPoint(source_str, delim);
    token      := SUBSTR(source_str, 1, breakpoint - 1);
    source_str := SUBSTR(source_str, breakpoint + 1);

  END getNextToken;

  --------this funciton is used for files where delimeter is not comma but slash

  PROCEDURE getNextToken2(source_str IN OUT VARCHAR2,
                          token      OUT VARCHAR2,
                          delim      IN VARCHAR2,
                          breakpoint OUT NUMBER) IS

  BEGIN

    token      := ' ';
    breakpoint := -1;
    breakpoint := GetBreakPoint(source_str, delim);
    token      := SUBSTR(source_str, 1, breakpoint); -----this is where this function differs from the previous one
    source_str := SUBSTR(source_str, breakpoint + 1);

  END getNextToken2;


-------------------------------------------------------------------------
  PROCEDURE Parser_Client_CDC(log_id         number,
                           client_row      varchar2,
                           file_date      date,
                           ignored_clients in out number,
                           invalid_clients in out number,
                           error_mess     out varchar2) IS

    ROW_ELEMENTS       FIELDARRAY;
    FieldNumber        number(10) := 0;
    LengthOfLine       number(10);
    --regular_delimeter  varchar2(1) := ',';
    regular_delimeter  varchar2(1) := ',';
    new_row            varchar2(32760);
    next_token         varchar2(100);
    break_point        number(20);
    DUPLICATE_EXCP     exception;
    MyException        exception;
    v_remarks             VARCHAR2(2000);

    V_IMPORT_DATE                   DATE;
    V_CLIENT_CODE                   VARCHAR2(100);
    V_CDCSTATUS                     VARCHAR2(1);
    V_CDC_STATUS                    VARCHAR2(50);
    V_CDC_DETAIL                    VARCHAR2(50);
    V_CDC_CODE                      VARCHAR2(50);
    V_CDC_BROKER                    VARCHAR2(200);
    V_CDC_ALL                       VARCHAR2(20);
    V_CDC_CODE2                     VARCHAR2(20);
    V_CDC_CLIENT_STATUS             VARCHAR2(30);
    V_CDC_CLIENT_ALL                VARCHAR2(20);
    V_CDC_BROK_CODE                 VARCHAR2(50);
    V_CDC_DATE                      VARCHAR2(50);
    V_CDC_TIME                      VARCHAR2(50);
    V_ACCOUNT_TYPE                  VARCHAR2(10);
    V_ACCOUNT_NUMBER                VARCHAR2(100);
    V_ACCOUNT_TITLE                 VARCHAR2(100);
    V_ADDITIONAL_INFORMATION        VARCHAR2(500);
    V_CONTACT_PERSON_NAME           VARCHAR2(500);
    V_CONTACT_NO                    VARCHAR2(100);
    V_LOCAL_MOBILE_NO               VARCHAR2(100);
    V_FAZ_NUMBER                    VARCHAR2(100);
    V_EMAILADDRESS                  VARCHAR2(250);
    V_ZAKAT_STATUS                  VARCHAR2(50);
    V_RESIDENT_STATUS               VARCHAR2(50);
    V_NATIONALITY                   VARCHAR2(50);
    V_SHARE_HOLDER_DESCRIPTION      VARCHAR2(500);
    V_DIVIDENT_MANDATE              VARCHAR2(10);
    V_BANK_ACCOUNT_TITLE            VARCHAR2(500);
    V_MANDATE_ACCOUNT_NO            VARCHAR2(500);
    V_BANK                          VARCHAR2(250);
    V_BRANCH                        VARCHAR2(250);
    V_BANK_CITY                     VARCHAR2(250);
    V_SCRA_DETAILS                  VARCHAR2(500);
    V_SCRA_ACCOUNT_NO               VARCHAR2(250);
    V_SCRA_BANK                     VARCHAR2(250);
    V_SCRA_BANK_BRANCH              VARCHAR2(150);
    V_SCRA_CITY                     VARCHAR2(150);
    V_REGISTRATION_NUMBER           VARCHAR2(500);
    V_FATHERHUSBAND                 VARCHAR2(250);
    V_FATHER_HUSBAND_NAME           VARCHAR2(250);
    V_MAILING_ADDRESS1               VARCHAR2(500);
    V_MAILING_ADDRESS2               VARCHAR2(500);
    V_MAILING_ADDRESS3               VARCHAR2(500);
    V_PERMREG_HEADOADDRES1           VARCHAR2(500);
    V_PERMREG_HEADOADDRES2           VARCHAR2(500);
    V_PERMREG_HEADOADDRES3           VARCHAR2(500);
    V_OCCUPATION_DESCRIPTION        VARCHAR2(500);
    V_CNICNICOP                     VARCHAR2(50);
    V_CNICNICOP_TITLE               VARCHAR2(150);
    V_CNICNICOP_EXPIRY_DATE         DATE;
    V_PASSPOC_NO                    VARCHAR2(150);
    V_PASSPOC_TITLE                 VARCHAR2(150);
    V_PASSPOC_ISSUE_DATE            DATE;
    V_PASSPOC_EXPIRY_DATE           DATE;
    V_PASSPOC_PLACE_OF_ISSUE        VARCHAR2(250);
    V_NATIONAL_TAX_NO               VARCHAR2(250);
    V_OPENING_DATE                  DATE;
    V_STATUS                        VARCHAR2(50);
    V_STATEMENT_STATUS              VARCHAR2(100);
    V_STATUS_DATE                   DATE;
    V_FIRST_J_NAME                  VARCHAR2(250);
    V_FIRST_J_CNICNICOP             VARCHAR2(150);
    V_FIRST_J_CNICNICOP_TITLE       VARCHAR2(250);
    V_FIRST_J_CNICNICOP_EXP_DATE    DATE;
    V_FIRST_J_PASSPOC_NUMBER        VARCHAR2(250);
    V_FIRST_J_PASSPOC_TITLE         VARCHAR2(250);
    V_FIRST_J_PASSPOC_PLACE_ISSUE   VARCHAR2(100);
    V_FIRST_J_PASSPOC_ISSUE_DATE    DATE;
    V_FIRST_J_PASSPOC_EXPIRY_DATE   DATE;
    V_SEC_J_NAME                    VARCHAR2(250);
    V_SEC_J_CNICNICOP               VARCHAR2(150);
    V_SEC_J_CNICNICOP_TITLE         VARCHAR2(250);
    V_SEC_J_CNICNICOP_EXP_DATE      DATE;
    V_SEC_J_PASSPOC_NUMBER          VARCHAR2(250);
    V_SEC_J_PASSPOC_TITLE           VARCHAR2(250);
    V_SEC_J_PASSPOC_PLACE_ISSUE     VARCHAR2(100);
    V_SEC_J_PASSPOC_ISSUE_DATE      DATE;
    V_SEC_J_PASSPOC_EXPIRY_DATE     DATE;
    V_THIRD_J_NAME                  VARCHAR2(250);
    V_THIRD_J_CNICNICOP             VARCHAR2(150);
    V_THIRD_J_CNICNICOP_TITLE       VARCHAR2(250);
    V_THIRD_J_CNICNICOP_EXP_DATE    DATE;
    V_THIRD_J_PASSPOC_NUMBER        VARCHAR2(250);
    V_THIRD_J_PASSPOC_TITLE         VARCHAR2(250);
    V_THIRD_J_PASSPOC_PLACE_ISSUE   VARCHAR2(100);
    V_THIRD_J_PASSPOC_ISSUE_DATE    DATE;
    V_THIRD_J_PASSPOC_EXPIRY_DATE   DATE;
    V_NOMINEE                       VARCHAR2(250);
    V_NOM_CNICNICOP                 VARCHAR2(150);
    V_NOM_CNICNICOP_EXPIRY_DATE     DATE;
    V_RELATION                      VARCHAR2(250);
    V_NOM_PASSPOC_NO                VARCHAR2(250);
    V_NOM_PASSPOC_PLACE_ISSUE       VARCHAR2(100);
    V_NOM_PASSPOC_ISSUE_DATE        DATE;
    V_NOM_PASSPOC_EXPIRY_DATE       DATE;
    V_ATTORNEY                      VARCHAR2(250);
    V_ATT_CNICNICOP                 VARCHAR2(150);
    V_ATT_CNICNICOP_EXPIRY_DATE     DATE;
    V_ATT_PASSPOC_NO                VARCHAR2(150);
    V_ATT_PASSPOC_PLACE_ISSUE       VARCHAR2(100);
    V_ATT_PASSPOC_ISSUE_DATE        DATE;
    V_ATT_PASSPOC_EXPIRY_DATE       DATE;
    V_UNKNOWN1                      VARCHAR2(200);
    V_UNKNOWN2                      VARCHAR2(200);                    
    V_EALERT                        VARCHAR2(10);
    V_SMS                           VARCHAR2(10);
    V_ESTATEMENT                    VARCHAR2(10);
    V_PHYSICAL_CDC                  VARCHAR2(10);
    V_FREQUENCY_CDC                 VARCHAR2(50);
    V_EINFO_REMARKS                 VARCHAR2(150);

  BEGIN
    BEGIN
      new_row      := client_row;
      ROW_ELEMENTS := FIELDARRAY('', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '',
                                 '', '', '', '', '', '', '', '', '', '');

      LengthOfLine := length(new_row);
      WHILE (LengthOfLine <> 0) LOOP
        FieldNumber := FieldNumber + 1;
        break_point := Getbreakpoint(new_row, regular_delimeter);
        getNextToken(new_row,ROW_ELEMENTS(FieldNumber),
                     regular_delimeter,break_point);
        ROW_ELEMENTS(FieldNumber) := TRIM('"' from ROW_ELEMENTS(FieldNumber));
        LengthOfLine := length(new_row);
      END LOOP;

      ----------------------------------------------------
      select S.SYSTEM_DATE INTO V_IMPORT_DATE FROM SYSTEM S;
      V_CLIENT_CODE                   := NULL;
      V_CDCSTATUS                        := NULL;
      /*V_CDC_STATUS                    := rtrim(ltrim(ROW_ELEMENTS(1),' '),' ');
      V_CDC_DETAIL                    := rtrim(ltrim(ROW_ELEMENTS(2),' '),' ');
      V_CDC_CODE                      := rtrim(ltrim(ROW_ELEMENTS(3),' '),' ');
      V_CDC_BROKER                    := rtrim(ltrim(ROW_ELEMENTS(4),' '),' ');
      V_CDC_ALL                       := rtrim(ltrim(ROW_ELEMENTS(5),' '),' ');
      V_CDC_CODE2                     := rtrim(ltrim(ROW_ELEMENTS(6),' '),' ');
      V_CDC_CLIENT_STATUS             := rtrim(ltrim(ROW_ELEMENTS(7),' '),' ');
      V_CDC_CLIENT_ALL                := rtrim(ltrim(ROW_ELEMENTS(8),' '),' ');
      V_CDC_BROK_CODE                 := rtrim(ltrim(ROW_ELEMENTS(9),' '),' ');
      V_CDC_DATE                      := rtrim(ltrim(ROW_ELEMENTS(10),' '),' ');
      V_CDC_TIME                      := rtrim(ltrim(ROW_ELEMENTS(11),' '),' ');*/
      V_ACCOUNT_TYPE                  := rtrim(ltrim(ROW_ELEMENTS(1),' '),' ');
      V_ACCOUNT_NUMBER                := rtrim(ltrim(ROW_ELEMENTS(2),' '),' ');
      V_ACCOUNT_TITLE                 := rtrim(ltrim(ROW_ELEMENTS(3),' '),' ');
      V_ADDITIONAL_INFORMATION        := rtrim(ltrim(ROW_ELEMENTS(4),' '),' ');
      V_CONTACT_PERSON_NAME           := rtrim(ltrim(ROW_ELEMENTS(5),' '),' ');
      V_CONTACT_NO                    := rtrim(ltrim(ROW_ELEMENTS(6),' '),' ');
      V_LOCAL_MOBILE_NO               := rtrim(ltrim(ROW_ELEMENTS(7),' '),' ');
      V_FAZ_NUMBER                    := rtrim(ltrim(ROW_ELEMENTS(8),' '),' ');
      V_EMAILADDRESS                  := rtrim(ltrim(ROW_ELEMENTS(9),' '),' ');
      V_ZAKAT_STATUS                  := rtrim(ltrim(ROW_ELEMENTS(10),' '),' ');
      V_RESIDENT_STATUS               := rtrim(ltrim(ROW_ELEMENTS(11),' '),' ');
      V_NATIONALITY                   := rtrim(ltrim(ROW_ELEMENTS(12),' '),' ');
      V_SHARE_HOLDER_DESCRIPTION      := rtrim(ltrim(ROW_ELEMENTS(13),' '),' ');
      V_DIVIDENT_MANDATE              := rtrim(ltrim(ROW_ELEMENTS(14),' '),' ');
      V_BANK_ACCOUNT_TITLE            := rtrim(ltrim(ROW_ELEMENTS(15),' '),' ');
      V_MANDATE_ACCOUNT_NO            := rtrim(ltrim(ROW_ELEMENTS(16),' '),' ');
      V_BANK                          := rtrim(ltrim(ROW_ELEMENTS(17),' '),' ');
      V_BRANCH                        := rtrim(ltrim(ROW_ELEMENTS(18),' '),' ');
      V_BANK_CITY                     := rtrim(ltrim(ROW_ELEMENTS(19),' '),' ');
      V_SCRA_DETAILS                  := rtrim(ltrim(ROW_ELEMENTS(28),' '),' ');
      V_SCRA_ACCOUNT_NO               := rtrim(ltrim(ROW_ELEMENTS(21),' '),' ');
      V_SCRA_BANK                     := rtrim(ltrim(ROW_ELEMENTS(22),' '),' ');
      V_SCRA_BANK_BRANCH              := rtrim(ltrim(ROW_ELEMENTS(23),' '),' ');
      V_SCRA_CITY                     := rtrim(ltrim(ROW_ELEMENTS(24),' '),' ');
      V_REGISTRATION_NUMBER           := rtrim(ltrim(ROW_ELEMENTS(25),' '),' ');
      V_FATHERHUSBAND                 := rtrim(ltrim(ROW_ELEMENTS(26),' '),' ');
      V_FATHER_HUSBAND_NAME           := rtrim(ltrim(ROW_ELEMENTS(27),' '),' ');
      V_MAILING_ADDRESS1               := rtrim(ltrim(ROW_ELEMENTS(28),' '),' ');
      V_MAILING_ADDRESS2               := rtrim(ltrim(ROW_ELEMENTS(29),' '),' ');
      V_MAILING_ADDRESS3               := rtrim(ltrim(ROW_ELEMENTS(30),' '),' ');
      V_PERMREG_HEADOADDRES1           := rtrim(ltrim(ROW_ELEMENTS(31),' '),' ');
      V_PERMREG_HEADOADDRES2           := rtrim(ltrim(ROW_ELEMENTS(32),' '),' ');
      V_PERMREG_HEADOADDRES3           := rtrim(ltrim(ROW_ELEMENTS(33),' '),' ');
      V_OCCUPATION_DESCRIPTION        := rtrim(ltrim(ROW_ELEMENTS(34),' '),' ');
      V_CNICNICOP                     := rtrim(ltrim(ROW_ELEMENTS(35),' '),' ');
      V_CNICNICOP_TITLE               := rtrim(ltrim(ROW_ELEMENTS(36),' '),' ');
      V_CNICNICOP_EXPIRY_DATE         := to_date(rtrim(ltrim(ROW_ELEMENTS(37),' '),' '), 'DD/MM/YYYY');
      V_PASSPOC_NO                    := rtrim(ltrim(ROW_ELEMENTS(38),' '),' ');
      V_PASSPOC_TITLE                 := rtrim(ltrim(ROW_ELEMENTS(39),' '),' ');
      V_PASSPOC_ISSUE_DATE            := to_date(rtrim(ltrim(ROW_ELEMENTS(40),' '),' '), 'DD/MM/YYYY');
      V_PASSPOC_EXPIRY_DATE           := to_date(rtrim(ltrim(ROW_ELEMENTS(41),' '),' '), 'DD/MM/YYYY');
      V_PASSPOC_PLACE_OF_ISSUE        := rtrim(ltrim(ROW_ELEMENTS(42),' '),' ');
      V_NATIONAL_TAX_NO               := rtrim(ltrim(ROW_ELEMENTS(43),' '),' ');
      V_OPENING_DATE                  := to_date(rtrim(ltrim(ROW_ELEMENTS(44),' '),' '), 'DD/MM/YYYY');
      V_STATUS                        := rtrim(ltrim(ROW_ELEMENTS(45),' '),' ');
      V_STATEMENT_STATUS              := rtrim(ltrim(ROW_ELEMENTS(46),' '),' ');
      V_STATUS_DATE                   := to_date(rtrim(ltrim(ROW_ELEMENTS(47),' '),' '), 'DD/MM/YYYY');
      V_FIRST_J_NAME                  := rtrim(ltrim(ROW_ELEMENTS(48),' '),' ');
      V_FIRST_J_CNICNICOP             := rtrim(ltrim(ROW_ELEMENTS(49),' '),' ');
      V_FIRST_J_CNICNICOP_TITLE       := rtrim(ltrim(ROW_ELEMENTS(50),' '),' ');
      V_FIRST_J_CNICNICOP_EXP_DATE    := to_date(rtrim(ltrim(ROW_ELEMENTS(51),' '),' '), 'DD/MM/YYYY');
      V_FIRST_J_PASSPOC_NUMBER        := rtrim(ltrim(ROW_ELEMENTS(52),' '),' ');
      V_FIRST_J_PASSPOC_TITLE         := rtrim(ltrim(ROW_ELEMENTS(53),' '),' ');
      V_FIRST_J_PASSPOC_PLACE_ISSUE   := rtrim(ltrim(ROW_ELEMENTS(54),' '),' ');
      V_FIRST_J_PASSPOC_ISSUE_DATE    := to_date(rtrim(ltrim(ROW_ELEMENTS(55),' '),' '), 'DD/MM/YYYY');
      V_FIRST_J_PASSPOC_EXPIRY_DATE   := to_date(rtrim(ltrim(ROW_ELEMENTS(56),' '),' '), 'DD/MM/YYYY');
      V_SEC_J_NAME                    := rtrim(ltrim(ROW_ELEMENTS(57),' '),' ');
      V_SEC_J_CNICNICOP               := rtrim(ltrim(ROW_ELEMENTS(58),' '),' ');
      V_SEC_J_CNICNICOP_TITLE         := rtrim(ltrim(ROW_ELEMENTS(59),' '),' ');
      V_SEC_J_CNICNICOP_EXP_DATE      := to_date(rtrim(ltrim(ROW_ELEMENTS(60),' '),' '), 'DD/MM/YYYY');
      V_SEC_J_PASSPOC_NUMBER          := rtrim(ltrim(ROW_ELEMENTS(61),' '),' ');
      V_SEC_J_PASSPOC_TITLE           := rtrim(ltrim(ROW_ELEMENTS(62),' '),' ');
      V_SEC_J_PASSPOC_PLACE_ISSUE     := rtrim(ltrim(ROW_ELEMENTS(63),' '),' ');
      V_SEC_J_PASSPOC_ISSUE_DATE      := to_date(rtrim(ltrim(ROW_ELEMENTS(64),' '),' '), 'DD/MM/YYYY');
      V_SEC_J_PASSPOC_EXPIRY_DATE     := to_date(rtrim(ltrim(ROW_ELEMENTS(65),' '),' '), 'DD/MM/YYYY');
      V_THIRD_J_NAME                  := rtrim(ltrim(ROW_ELEMENTS(66),' '),' ');
      V_THIRD_J_CNICNICOP             := rtrim(ltrim(ROW_ELEMENTS(67),' '),' ');
      V_THIRD_J_CNICNICOP_TITLE       := rtrim(ltrim(ROW_ELEMENTS(68),' '),' ');
      V_THIRD_J_CNICNICOP_EXP_DATE    := to_date(rtrim(ltrim(ROW_ELEMENTS(69),' '),' '), 'DD/MM/YYYY');
      V_THIRD_J_PASSPOC_NUMBER        := rtrim(ltrim(ROW_ELEMENTS(70),' '),' ');
      V_THIRD_J_PASSPOC_TITLE         := rtrim(ltrim(ROW_ELEMENTS(71),' '),' ');
      V_THIRD_J_PASSPOC_PLACE_ISSUE   := rtrim(ltrim(ROW_ELEMENTS(72),' '),' ');
      V_THIRD_J_PASSPOC_ISSUE_DATE    := to_date(rtrim(ltrim(ROW_ELEMENTS(73),' '),' '), 'DD/MM/YYYY');
      V_THIRD_J_PASSPOC_EXPIRY_DATE   := to_date(rtrim(ltrim(ROW_ELEMENTS(74),' '),' '), 'DD/MM/YYYY');
      V_NOMINEE                       := rtrim(ltrim(ROW_ELEMENTS(75),' '),' ');
      V_NOM_CNICNICOP                 := rtrim(ltrim(ROW_ELEMENTS(76),' '),' ');
      V_NOM_CNICNICOP_EXPIRY_DATE     := to_date(rtrim(ltrim(ROW_ELEMENTS(77),' '),' '), 'DD/MM/YYYY');
      V_RELATION                      := rtrim(ltrim(ROW_ELEMENTS(78),' '),' ');
      V_NOM_PASSPOC_NO                := rtrim(ltrim(ROW_ELEMENTS(79),' '),' ');
      V_NOM_PASSPOC_PLACE_ISSUE       := rtrim(ltrim(ROW_ELEMENTS(80),' '),' ');
      V_NOM_PASSPOC_ISSUE_DATE        := to_date(rtrim(ltrim(ROW_ELEMENTS(81),' '),' '), 'DD/MM/YYYY');
      V_NOM_PASSPOC_EXPIRY_DATE       := to_date(rtrim(ltrim(ROW_ELEMENTS(82),' '),' '), 'DD/MM/YYYY');
      V_ATTORNEY                      := rtrim(ltrim(ROW_ELEMENTS(83),' '),' ');
      V_ATT_CNICNICOP                 := rtrim(ltrim(ROW_ELEMENTS(84),' '),' ');
      V_ATT_CNICNICOP_EXPIRY_DATE     := to_date(rtrim(ltrim(ROW_ELEMENTS(85),' '),' '), 'DD/MM/YYYY');
      V_ATT_PASSPOC_NO                := rtrim(ltrim(ROW_ELEMENTS(86),' '),' ');
      V_ATT_PASSPOC_PLACE_ISSUE       := rtrim(ltrim(ROW_ELEMENTS(87),' '),' ');
      V_ATT_PASSPOC_ISSUE_DATE        := to_date(rtrim(ltrim(ROW_ELEMENTS(88),' '),' '), 'DD/MM/YYYY');
      V_ATT_PASSPOC_EXPIRY_DATE       := to_date(rtrim(ltrim(ROW_ELEMENTS(89),' '),' '), 'DD/MM/YYYY');
      V_UNKNOWN1                      := rtrim(ltrim(ROW_ELEMENTS(90),' '),' ');
      V_UNKNOWN2                      := rtrim(ltrim(ROW_ELEMENTS(91),' '),' ');   
      V_EALERT                        := rtrim(ltrim(ROW_ELEMENTS(92),' '),' ');
      V_SMS                           := rtrim(ltrim(ROW_ELEMENTS(93),' '),' ');
      V_ESTATEMENT                    := rtrim(ltrim(ROW_ELEMENTS(94),' '),' ');
      V_PHYSICAL_CDC                  := rtrim(ltrim(ROW_ELEMENTS(95),' '),' ');
      V_FREQUENCY_CDC                 := rtrim(ltrim(ROW_ELEMENTS(96),' '),' ');
      V_EINFO_REMARKS                 := rtrim(ltrim(ROW_ELEMENTS(97),' '),' ');
      ----------------------------------------------------
      /*_______________________________________________________________________________________
      ***************************insertion in Equity Trade***************************----------*/

      BEGIN
        INSERT INTO CLIENT_CDC_FILE
          (import_date,
           client_code,
           cdcstatus,
           cdc_status,
           cdc_detail,
           cdc_code,
           cdc_broker,
           cdc_all,
           cdc_code2,
           cdc_client_status,
           cdc_client_all,
           cdc_brok_code,
           cdc_date,
           cdc_time,
           account_type,
           account_number,
           account_title,
           additional_information,
           contact_person_name,
           contact_no,
           local_mobile_no,
           faz_number,
           emailaddress,
           zakat_status,
           resident_status,
           nationality,
           share_holder_description,
           divident_mandate,
           bank_account_title,
           mandate_account_no,
           bank,
           branch,
           bank_city,
           scra_details,
           scra_account_no,
           scra_bank,
           scra_bank_branch,
           scra_city,
           registration_number,
           fatherhusband,
           father_husband_name,
           mailing_address1,
           mailing_address2,
           mailing_address3,
           permreg_headoaddres1,
           permreg_headoaddres2,
           permreg_headoaddres3,
           occupation_description,
           cnicnicop,
           cnicnicop_title,
           cnicnicop_expiry_date,
           passpoc_no,
           passpoc_title,
           passpoc_issue_date,
           passpoc_expiry_date,
           passpoc_place_of_issue,
           national_tax_no,
           opening_date,
           status,
           statement_status,
           status_date,
           first_j_name,
           first_j_cnicnicop,
           first_j_cnicnicop_title,
           first_j_cnicnicop_expiry_date,
           first_j_passpoc_number,
           first_j_passpoc_title,
           first_j_passpoc_place_issue,
           first_j_passpoc_issue_date,
           first_j_passpoc_expiry_date,
           sec_j_name,
           sec_j_cnicnicop,
           sec_j_cnicnicop_title,
           sec_j_cnicnicop_expiry_date,
           sec_j_passpoc_number,
           sec_j_passpoc_title,
           sec_j_passpoc_place_issue,
           sec_j_passpoc_issue_date,
           sec_j_passpoc_expiry_date,
           third_j_name,
           third_j_cnicnicop,
           third_j_cnicnicop_title,
           third_j_cnicnicop_expiry_date,
           third_j_passpoc_number,
           third_j_passpoc_title,
           third_j_passpoc_place_issue,
           third_j_passpoc_issue_date,
           third_j_passpoc_expiry_date,
           nominee,
           nom_cnicnicop,
           nom_cnicnicop_expiry_date,
           relation,
           nom_passpoc_no,
           nom_passpoc_place_issue,
           nom_passpoc_issue_date,
           nom_passpoc_expiry_date,
           attorney,
           att_cnicnicop,
           att_cnicnicop_expiry_date,
           att_passpoc_no,
           att_passpoc_place_issue,
           att_passpoc_issue_date,
           att_passpoc_expiry_date,
           unknown1,
           unknown2,
           ealert,
           sms,
           estatement,
           physical_cdc,
           frequency_cdc,
           einfo_remarks)
        
        VALUES
          (V_IMPORT_DATE,
           V_CLIENT_CODE,
           V_CDCSTATUS,
           V_CDC_STATUS,
           V_CDC_DETAIL,
           V_CDC_CODE,
           V_CDC_BROKER,
           V_CDC_ALL,
           V_CDC_CODE2,
           V_CDC_CLIENT_STATUS,
           V_CDC_CLIENT_ALL,
           V_CDC_BROK_CODE,
           V_CDC_DATE,
           V_CDC_TIME,
           V_ACCOUNT_TYPE,
           V_ACCOUNT_NUMBER,
           V_ACCOUNT_TITLE,
           V_ADDITIONAL_INFORMATION,
           V_CONTACT_PERSON_NAME,
           V_CONTACT_NO,
           V_LOCAL_MOBILE_NO,
           V_FAZ_NUMBER,
           V_EMAILADDRESS,
           V_ZAKAT_STATUS,
           V_RESIDENT_STATUS,
           V_NATIONALITY,
           V_SHARE_HOLDER_DESCRIPTION,
           V_DIVIDENT_MANDATE,
           V_BANK_ACCOUNT_TITLE,
           V_MANDATE_ACCOUNT_NO,
           V_BANK,
           V_BRANCH,
           V_BANK_CITY,
           V_SCRA_DETAILS,
           V_SCRA_ACCOUNT_NO,
           V_SCRA_BANK,
           V_SCRA_BANK_BRANCH,
           V_SCRA_CITY,
           V_REGISTRATION_NUMBER,
           V_FATHERHUSBAND,
           V_FATHER_HUSBAND_NAME,
           V_MAILING_ADDRESS1,
           V_MAILING_ADDRESS2,
           V_MAILING_ADDRESS3,
           V_PERMREG_HEADOADDRES1,
           V_PERMREG_HEADOADDRES2,
           V_PERMREG_HEADOADDRES3,
           V_OCCUPATION_DESCRIPTION,
           V_CNICNICOP,
           V_CNICNICOP_TITLE,
           V_CNICNICOP_EXPIRY_DATE,
           V_PASSPOC_NO,
           V_PASSPOC_TITLE,
           V_PASSPOC_ISSUE_DATE,
           V_PASSPOC_EXPIRY_DATE,
           V_PASSPOC_PLACE_OF_ISSUE,
           V_NATIONAL_TAX_NO,
           V_OPENING_DATE,
           V_STATUS,
           V_STATEMENT_STATUS,
           V_STATUS_DATE,
           V_FIRST_J_NAME,
           V_FIRST_J_CNICNICOP,
           V_FIRST_J_CNICNICOP_TITLE,
           V_FIRST_J_CNICNICOP_EXP_DATE,
           V_FIRST_J_PASSPOC_NUMBER,
           V_FIRST_J_PASSPOC_TITLE,
           V_FIRST_J_PASSPOC_PLACE_ISSUE,
           V_FIRST_J_PASSPOC_ISSUE_DATE,
           V_FIRST_J_PASSPOC_EXPIRY_DATE,
           V_SEC_J_NAME,
           V_SEC_J_CNICNICOP,
           V_SEC_J_CNICNICOP_TITLE,
           V_SEC_J_CNICNICOP_EXP_DATE,
           V_SEC_J_PASSPOC_NUMBER,
           V_SEC_J_PASSPOC_TITLE,
           V_SEC_J_PASSPOC_PLACE_ISSUE,
           V_SEC_J_PASSPOC_ISSUE_DATE,
           V_SEC_J_PASSPOC_EXPIRY_DATE,
           V_THIRD_J_NAME,
           V_THIRD_J_CNICNICOP,
           V_THIRD_J_CNICNICOP_TITLE,
           V_THIRD_J_CNICNICOP_EXP_DATE,
           V_THIRD_J_PASSPOC_NUMBER,
           V_THIRD_J_PASSPOC_TITLE,
           V_THIRD_J_PASSPOC_PLACE_ISSUE,
           V_THIRD_J_PASSPOC_ISSUE_DATE,
           V_THIRD_J_PASSPOC_EXPIRY_DATE,
           V_NOMINEE,
           V_NOM_CNICNICOP,
           V_NOM_CNICNICOP_EXPIRY_DATE,
           V_RELATION,
           V_NOM_PASSPOC_NO,
           V_NOM_PASSPOC_PLACE_ISSUE,
           V_NOM_PASSPOC_ISSUE_DATE,
           V_NOM_PASSPOC_EXPIRY_DATE,
           V_ATTORNEY,
           V_ATT_CNICNICOP,
           V_ATT_CNICNICOP_EXPIRY_DATE,
           V_ATT_PASSPOC_NO,
           V_ATT_PASSPOC_PLACE_ISSUE,
           V_ATT_PASSPOC_ISSUE_DATE,
           V_ATT_PASSPOC_EXPIRY_DATE,
           V_UNKNOWN1,
           V_UNKNOWN2,
           V_EALERT,
           V_SMS,
           V_ESTATEMENT,
           V_PHYSICAL_CDC,
           V_FREQUENCY_CDC,
           V_EINFO_REMARKS);

        COMMIT;
      EXCEPTION
        when DUP_VAL_ON_INDEX then
        
          error_mess := 'Duplicate trade found, such trade already exists in system';
          raise DUPLICATE_EXCP;
        
        WHEN OTHERS THEN
          error_mess := 'Error occured while inserting trade in Equity Trade - ' ||
                        SUBSTR(SQLERRM, 1, 70);
          raise MyException;
        
      END;

    EXCEPTION
      WHEN DUPLICATE_EXCP then
      -------------------
      ---IGNORED trade---
      -------------------
        ignored_clients := ignored_clients + 1;
        rollback;
--      When OTHERS THEN
      WHEN MyException then
      -------------------
      ---invalid trade---
      -------------------
        invalid_clients := invalid_clients + 1;
        rollback;
        if error_mess is null then
          error_mess := 'Error:';
        end if;
--        DBMS_OUTPUT.PUT_LINE('Result ' || Result);
--        v_remarks := error_mess;
        v_remarks := substr(error_mess, 1, 150);



      WHEN OTHERS THEN
        invalid_clients := invalid_clients + 1;
        error_mess     := SUBSTR(SQLERRM, 1, 100);
        rollback;

        if error_mess is null then
          error_mess := 'Error:';
        end if;

--        DBMS_OUTPUT.PUT_LINE('Result ' || Result);
        v_remarks := error_mess;
        v_remarks := v_remarks || SUBSTR(SQLERRM, 1, 70);

    end;
  END Parser_Client_CDC;


end Import_Client_CDC;
/
