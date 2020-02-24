-- Create table
create table CLIENT_CDC_FILE
(
  IMPORT_DATE                   DATE,
  CLIENT_CODE                   VARCHAR2(100),
  CDCSTATUS                     VARCHAR2(1),
  CDC_STATUS                    VARCHAR2(50),
  CDC_DETAIL                    VARCHAR2(50),
  CDC_CODE                      VARCHAR2(50),
  CDC_BROKER                    VARCHAR2(200),
  CDC_ALL                       VARCHAR2(20),
  CDC_CODE2                     VARCHAR2(20),
  CDC_CLIENT_STATUS             VARCHAR2(30),
  CDC_CLIENT_ALL                VARCHAR2(20),
  CDC_BROK_CODE                 VARCHAR2(50),
  CDC_DATE                      VARCHAR2(50),
  CDC_TIME                      VARCHAR2(50),
  ACCOUNT_TYPE                  VARCHAR2(10),
  ACCOUNT_NUMBER                VARCHAR2(100),
  ACCOUNT_TITLE                 VARCHAR2(100),
  ADDITIONAL_INFORMATION        VARCHAR2(500),
  CONTACT_PERSON_NAME           VARCHAR2(500),
  CONTACT_NO                    VARCHAR2(100),
  LOCAL_MOBILE_NO               VARCHAR2(100),
  FAZ_NUMBER                    VARCHAR2(100),
  EMAILADDRESS                  VARCHAR2(250),
  ZAKAT_STATUS                  VARCHAR2(50),
  RESIDENT_STATUS               VARCHAR2(50),
  NATIONALITY                   VARCHAR2(50),
  SHARE_HOLDER_DESCRIPTION      VARCHAR2(500),
  DIVIDENT_MANDATE              VARCHAR2(10),
  BANK_ACCOUNT_TITLE            VARCHAR2(500),
  MANDATE_ACCOUNT_NO            VARCHAR2(500),
  BANK                          VARCHAR2(250),
  BRANCH                        VARCHAR2(250),
  BANK_CITY                     VARCHAR2(250),
  SCRA_DETAILS                  VARCHAR2(500),
  SCRA_ACCOUNT_NO               VARCHAR2(250),
  SCRA_BANK                     VARCHAR2(250),
  SCRA_BANK_BRANCH              VARCHAR2(150),
  SCRA_CITY                     VARCHAR2(150),
  REGISTRATION_NUMBER           VARCHAR2(500),
  FATHERHUSBAND                 VARCHAR2(250),
  FATHER_HUSBAND_NAME           VARCHAR2(250),
  MAILING_ADDRESS1              VARCHAR2(500),
  MAILING_ADDRESS2              VARCHAR2(500),
  MAILING_ADDRESS3              VARCHAR2(500),
  PERMREG_HEADOADDRES1          VARCHAR2(500),
  PERMREG_HEADOADDRES2          VARCHAR2(500),
  PERMREG_HEADOADDRES3          VARCHAR2(500),
  OCCUPATION_DESCRIPTION        VARCHAR2(500),
  CNICNICOP                     VARCHAR2(50),
  CNICNICOP_TITLE               VARCHAR2(150),
  CNICNICOP_EXPIRY_DATE         DATE,
  PASSPOC_NO                    VARCHAR2(150),
  PASSPOC_TITLE                 VARCHAR2(150),
  PASSPOC_ISSUE_DATE            DATE,
  PASSPOC_EXPIRY_DATE           DATE,
  PASSPOC_PLACE_OF_ISSUE        VARCHAR2(250),
  NATIONAL_TAX_NO               VARCHAR2(250),
  OPENING_DATE                  DATE,
  STATUS                        VARCHAR2(50),
  STATEMENT_STATUS              VARCHAR2(100),
  STATUS_DATE                   DATE,
  FIRST_J_NAME                  VARCHAR2(250),
  FIRST_J_CNICNICOP             VARCHAR2(150),
  FIRST_J_CNICNICOP_TITLE       VARCHAR2(250),
  FIRST_J_CNICNICOP_EXPIRY_DATE DATE,
  FIRST_J_PASSPOC_NUMBER        VARCHAR2(250),
  FIRST_J_PASSPOC_TITLE         VARCHAR2(250),
  FIRST_J_PASSPOC_PLACE_ISSUE   VARCHAR2(100),
  FIRST_J_PASSPOC_ISSUE_DATE    DATE,
  FIRST_J_PASSPOC_EXPIRY_DATE   DATE,
  SEC_J_NAME                    VARCHAR2(250),
  SEC_J_CNICNICOP               VARCHAR2(150),
  SEC_J_CNICNICOP_TITLE         VARCHAR2(250),
  SEC_J_CNICNICOP_EXPIRY_DATE   DATE,
  SEC_J_PASSPOC_NUMBER          VARCHAR2(250),
  SEC_J_PASSPOC_TITLE           VARCHAR2(250),
  SEC_J_PASSPOC_PLACE_ISSUE     VARCHAR2(100),
  SEC_J_PASSPOC_ISSUE_DATE      DATE,
  SEC_J_PASSPOC_EXPIRY_DATE     DATE,
  THIRD_J_NAME                  VARCHAR2(250),
  THIRD_J_CNICNICOP             VARCHAR2(150),
  THIRD_J_CNICNICOP_TITLE       VARCHAR2(250),
  THIRD_J_CNICNICOP_EXPIRY_DATE DATE,
  THIRD_J_PASSPOC_NUMBER        VARCHAR2(250),
  THIRD_J_PASSPOC_TITLE         VARCHAR2(250),
  THIRD_J_PASSPOC_PLACE_ISSUE   VARCHAR2(100),
  THIRD_J_PASSPOC_ISSUE_DATE    DATE,
  THIRD_J_PASSPOC_EXPIRY_DATE   DATE,
  NOMINEE                       VARCHAR2(250),
  NOM_CNICNICOP                 VARCHAR2(150),
  NOM_CNICNICOP_EXPIRY_DATE     DATE,
  RELATION                      VARCHAR2(250),
  NOM_PASSPOC_NO                VARCHAR2(250),
  NOM_PASSPOC_PLACE_ISSUE       VARCHAR2(100),
  NOM_PASSPOC_ISSUE_DATE        DATE,
  NOM_PASSPOC_EXPIRY_DATE       DATE,
  ATTORNEY                      VARCHAR2(250),
  ATT_CNICNICOP                 VARCHAR2(150),
  ATT_CNICNICOP_EXPIRY_DATE     DATE,
  ATT_PASSPOC_NO                VARCHAR2(150),
  ATT_PASSPOC_PLACE_ISSUE       VARCHAR2(100),
  ATT_PASSPOC_ISSUE_DATE        DATE,
  ATT_PASSPOC_EXPIRY_DATE       DATE,
  UNKNOWN1                      VARCHAR2(200),
  UNKNOWN2                      VARCHAR2(200),
  EALERT                        VARCHAR2(10),
  SMS                           VARCHAR2(10),
  ESTATEMENT                    VARCHAR2(10),
  PHYSICAL_CDC                  VARCHAR2(10),
  FREQUENCY_CDC                 VARCHAR2(50),
  EINFO_REMARKS                 VARCHAR2(150),
  ACCOUNT_STATUS                CHAR(1) default 'P'
);