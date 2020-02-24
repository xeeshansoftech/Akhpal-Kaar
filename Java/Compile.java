import java.io.IOException;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileNotFoundException;

public class Compile
{

    public static final boolean lib      	= true;
    public static final boolean framwork 	= true;
    public static final boolean forms    	= true;

    public static final boolean equity   	= true;
    public static final boolean gl       	= true;
    public static final boolean custody  	= true;

    public static final boolean fis	        = false;
    public static final boolean moneyMarket	= false;
    public static final boolean forex	 	= false;

    public static final boolean hr       	= false;
    public static final boolean payroll  	= false;

    public static final boolean phone    	= false;
    public static final boolean mailing  	= false;
    public static final boolean library  	= false;
    public static final boolean stockfuel	= false;
    public static final boolean tax      	= false;

    public static final boolean listing     = true;


    public static String CONNECT_STRING = "zafar_bc/zafar@db";

    /**
     * The Root directory of the Back Connect Application
     */
    public static String ROOT = "C:\\KASB\\BackConnect\\Application";

    public static String FORMS       = ROOT + "\\forms";
    public static String PACKAGES    = ROOT + "\\packages";
    public static String FRAMEWORK   = FORMS + "\\framework";
    public static String REPORTS     = ROOT + "\\reports";
    public static String TARGET      = ROOT + "\\Launch";

    /**
     * File Name of the Forms6i Compiler
     */
    public static String COMPILER = "ifcmp60.exe";
    public static String CONVERTOR = "rwcon60.exe";

    public static void main (String arg[])
    {
        System.out.println("____________________________________________________________________");
        System.out.println("Arg. 1 ROOT DIRECTORY, default is " + ROOT);
        System.out.println("Arg. 2 CONNECTION_STRING, default is " + CONNECT_STRING);
        System.out.println("____________________________________________________________________");
        if (arg.length == 2)
        {
            ROOT = arg[0];
            CONNECT_STRING = arg[1];
        }
        //deleteOldBinaries();
        if (lib)
            buildPackages();
        if (framwork)
            buildFramework();


        // Build Standard Forms
        String files[] = {
            "AGENT_FORM",
            "BANK_FORM",
            "BILL_CANCELATION",
            "BILLING_PRINTING",
            "BRANCH_CLIENT_FORM",
            "BRANCH_FORM",
            "BUSINESS_AREA_FORM",
            "CITY_FORM",
            "CLEARING_TYPE_FORM",
            "CLIENT_BUSINESS_FORM",
            "CLIENT_DOCUMENT_FORM",
            "CLIENT_FORM",
            "CLIENT_GROUP_FORM",
            "CLIENT_OCCUPATION_FORM",
            "CLIENT_TYPE_FORM",
            "COMMISSION_CALCULATION",
            "COUNTRY_FORM",
            "CS_MARGIN_CATAGORY_FORM",
            "CURRENCY_FORM",
            "CUSTODIAN_FORM",
            "CUSTODY_BILL_CANCELATION",
            "CUSTODY_BILLING_FORM",
            "CUSTODY_CLIENT_DETAIL_FORM",
            "DAY_END_PROCEDURE",
            "DEPARTMENT_FORM",
            "EXECUTIVES_FORM",
            "EXPOSURE_FORM",
            "FINANCIAL_YEARS_FORM",
            "FOREIGN_CLIENT",
            "HOLIDAY_FORM",
            "INDIVIDUAL_CLIENT_BILLING",
            "INVESTOR_FORM",
            "LANGUAGE_FORM",
            "LIST_PARAMETER_FORM",
            "MARGIN_CASH_BAL_COST_CENTRE",
            "MARGIN_HOLDING_VALUE_FORM",
            "MARGIN_ORDER_LIMITS_FORM",
            "MARGIN_PERCENTAGE_FORM",
            "MARKET_TYPE_FORM",
            "MEMBER_FORM",
            "NCSS_IMPORT",
            //"OPENING_POSITIONS",
            //"OPR_CODE_FORM",
            "ONLINE_CLIENT_FORM",
            "ORDER_LIST",
            "PARAMETER_FORM",
            "RELIGION_FORM",
            "SE_CT_CLIENT_FORM",
            "SE_SECURITY_FORM",
            "SECTOR_FORM",
            "SECURITY_FORM",
            "SECURITY_TYPE_FORM",
            "SLAB_GROUP_FORM",
            "STOCK_EXCHANGE_FORM",
            "SYSTEM_FORM",
            "TARIFF_ID_UPDATE",
            "TARRIF_FORM",
            "TARRIF_SECURITIES",
            "TRADE_TYPE_FORM",
            "TRADERS_FORM",
            "TRANSACTION_PERIODS_FORM",
            "USER_EXCEPTION_FORM",
            "USER_PREFERENCES_FORM",
            "USER_ROLE_FORM",
            "USERS_FORM"
        };
        if (forms) buildForms(FORMS + "\\", files);


        // ________________________________________________________________
        //
        // Build Equity
        // ________________________________________________________________
        String equity_files[] = {
            "BACKUP_RESTORE_FORM",
            "BANK_PAY_AND_COLLECT",
            "BORROWING_TRADES",
            "CALCULATE_MARGIN",
            "CLEARING_CALENDAR_FORM",
            "CLIENT_LOAN",
            "COMMISSION_ROLLBACK",
            //"COTTRADE_ENTRY",
            "CTC_TRADES_FORM",
            "Custody_merging",
            "DELETE_TRADE_BATCH",
            "EQUITY_CASH_BOOK_OP_BAL_FORM",
	        "EQUITY_MARKET_FORM",
	        "EQUITY_OPENING_PORTFOLIO_FORM",
            "EQUITY_ORDER_FORM",
            "EQUITY_ORDER_VIEW",
            "EQUITY_SYSTEM_FORM",
            "EQUITY_TRADE_EXECUTION",
            "EQUITY_TRADE_EXPORT",
            "EQUITY_TRADES_FORM",
            "EXECUTE_CTC_TRADE",
            "EXECUTE_VALIDATE_ORDER",
            "EXPORT_FOR_MERRILLINCH",
            "FORWARD_MARKET_FORM",
            "FORWARD_PL_SETTLEMENT",
            "FUTURE_PL_SETT_FORM",
            "IMPORT_MARKET_RATES",
            "IMPORT_MEMBER_BOOKCLOSING_FILE",
            "KATS_TRADE_ENTRY",
            "LCONF_PARAMETER_FORM",
            "LOCK_TRADES_FORM",
            "LSS_COT_TRADE_ENTRY",
            "MEMBER_LOAN",
            "NET_SHARE_EXPORT",
            "OP_STAFF_PAY_AND_COLLECT",
            "SINGLE_COMMISSION_CALCULATION",
            "SPLIT_TRADES",
            "SPOT_TRADE_MODIFY_FORM",
            "TRADE_ENTRY",
            "UPDATE_TRADE_DATE_FORM",
            "VIEW_INVALID_TRADE"
        };
        if (equity) buildForms(FORMS + "\\Equity\\", equity_files);


        String equityReports [] = {
            "Agent_Book",
            "Agent_Clearing_House_Summary",
            "Agent_Sauda_Book",
            "Badla_All_Client_Status_Report",
            "Badla_Client_Status_Report",
            "BILL_Cancelation",
            "Brokerage_Report",
            "BrokerageSummaryOnTradeDate",
            "CapitaGainLoss_Sum",
            "CapitalGainLossDetail",
            "Cashbook_Detail(Lahore)",
            "Cashbook_Detail_wrt_BILL",
            "Cashbook_Detail_wrt_Trades",
            "Cashbook_Summary_wrt_Bill",
            "Cashbook_Summary_wrt_Trades",
            "CH_Delivery",
            "CH_Payment",
            "Clearing_Exposure",
            "clearing_register",
            "Client_Account_Ledgers",
            "CLIENT_EQUITY_TARRIF_LIST",
            "CLIENT_MARGIN_HOLDING_LIST",
            "CLIENT_MARGIN_PERCENTAGE_LIST",
            "Client_Security_Clearing_Detail",
            "Client_Security_Clearing_Detail2",
            "Client_Security_Clearing_Summary",
            "Client_Security_Clearing_Summary2",
            "Client_Security_Periodic_Trade_Detail",
            "Client_Security_Periodic_Trade_Detail_billed",
            "Client_Security_Periodic_Trade_Detail_Unbilled",
            "Client_Security_Periodic_Trade_Summary",
            "Client_Type_Wise_Brokerage",
            "Client_Wise_Margin_COT_Report",
            "Client_Wise_Margin_Report",
            "Client_Wise_Margin_Report_LSE",
            "consolidate(new_Format)",
            "consolidate",
            "CTC_Difference",
            "Daily_Trade_List",
            "DAILY_TRADE_LIST_TRADER_WISE",
            "DEBIT_BILL_REPORT",
            "Difference_register",
            "Diminution_Sum_Report",
            "EQUITY_MARKET_SECURITY_LIST",
            "Equity_Slab_List",
            "Equity_Tarrif_List",
            "Executive_comission_detail",
            "Executive_comission_summary",
            "Exposure_Report",
            "Foreign_Confirmation",
            "Foreign_Settlement_Statement",
            "ForeignInvestorMonthWiseSummary",
            "forward_short_sell_report",
            "Future_Contracts_Exposure",
            "Future_Contracts_Losses",
            "HAWALA_REGISTER",
            //"IMPORT_MEMBER_BOOKCLOSING_FILE",
            "inavlid_order_list2",
            "ind_bill",
            "invalid_orders",
            "Investor_Client_List",
            "Local_Confirmation",
            "Local_Confirmation_New_Format",
            "Margin_order_history",
            "Net_Trades_List",
            "Order_list",
            "periodic_bill",
            "profitLoss",
            "Risk_Management(Lahore)",
            "Risk_Management",            
            "risk_management_lse_format",
            "Risk_Management_New_Format",
            "risk_mgt_lse_summary",
            "Sec_Clt_Periodic_Trade_Summary",
            "SECURITY_CLIENT_LAHORE",
            "Security_Client_Periodic_Trade_Detail",
            "Security_Client_Periodic_Trade_Detail2",
            "Security_Client_Periodic_Trade_Summary",
            "Security_Client_Periodic_Trade_Summary2",
            "Security_Wise_Clearing_Detail",
            "Security_Wise_Clearing_Detail2",
            "Security_Wise_Clearing_Detail3",
            "Security_Wise_Clearing_Summury",
            "Security_Wise_Clearing_Summury2",
            "Security_Wise_Clearing_Summury3",
            "Trader_Wise_Detail_Brokerage",
            "Trader_Wise_Summary_Brokerage",
            "UNRELEASED_COT_TRADE"
        };
        if (equity) buildReports(REPORTS + "\\Equity\\", equityReports);


        // ________________________________________________________________
        //
        // Build General ledger
        // ________________________________________________________________
        String glForms[] = {
            "ACCOUNT_MERGING_FORM",
            "ACCOUNT_REF_DEFINITION",
            "AGING_TEMPLATE_FORM",
            "BALANCE_TRANSFER_FORM",
            "BANK_BOOK_DEFINITION_FORM",
            "BANK_PAYMENT_VOUCHER",
            "BANK_RECEIPT_VOUCHER",
            "CASH_BOOK_DEFINITION_FORM",
            "CASH_PAYMENT_VOUCHER",
            "CASH_RECEIPT_VOUCHER",
            "CHART_ACC_DEFINITION_FORM",
            "COST_CENTRE_FORM",
            "FORMAT_REPORT",
            "GL_ASSET_OPENING_FORM",
            "GL_ASSET_TYPE_FORM",
            "GL_BANK_CHEQUE",
            "GL_PARAMETER_FORM",
            "GL_SYSTEM_FORM",
            "GL_USER_BOOK_TYPE_FORM",
            "GL_USER_GLMF_FORM",
            "GROUP_COST_CENTRE_FORM",
            "JOURNAL_VOUCHER",
            "JV_BOOK_DEFINITION_FORM",
            "OPENING_BALANCE",
            "PERIOD_TEMPLATE_FORM",
            "PETTY_CASH_OPENING_BALANCE",
            "PROVISIONAL_VOUCHER",
            "SL_BOOK_ACC_DEFINITION",
            "TRANS_TYPE_DEFINITION_FORM",
            "UNPOST_VOUCHER_FORM",
            "VOUCHER_TEMPLATE",
            "VOUCHER_TRIGGER_FORM",
            "YEAR_END_VOUCHER"
        };
        if (gl) buildForms(FORMS + "\\GL\\", glForms);

        String glReports [] = {
            "Account_Ref_list",
            "Aging_Report",
            "allied_bank_cheque",
            "askari_bank_cheque",
            "Bank_payment_book",
            "Bank_Payment_list",
            "Bank_Payment_org_book",
            "Bank_Receipt_book",
            "Bank_Receipt_list",
            "Bank_Receipt_org_book",
            "cash_payment_book",
            "Cash_Payment_list",
            "Cash_Payment_org_book",
            "Cash_Receipt_book",
            "Cash_Receipt_list",
            "Cash_Receipt_org_book",
            "Chart_of_Account_list",
            "Chart_of_Account_Short_list",
            "city_bank_cheque",
            "DEPRECIATION_SCHEDULE",
            "FA_TEMPLATES_DESIGN",
            "faysal_bank_cheque",
            "gl_book_type",
            "GL_CASHBOOK",
            "GL_CASHBOOK_COST_CENTRE",
            "GL_FINAL_ACCOUNTS_NOTES",
            "GL_LEDGER",
            "GL_LEDGER_BRANCH",
            "GL_LEDGER_COST_CENTRE",
            "GL_PROFITLOSS_BALANCESHEET",
            "GL_PROFITLOSS_BALANCESHEET_LS",
            "gl_provisional_org_book",
            "GL_SUBLEDGER",
            "GL_SUBLEDGER_BRANCH",
            "GL_SUBLEDGER_COST_CENTRE",
            "GL_VOUCHER",
            "imarat_bank_cheque",
            "imarat_bank_cheque2",
            "Integrated_Vouchers",
            "Journal_Voucher_book",
            "Journal_Voucher_list",
            "Journal_Voucher_org_book",
            "List_of_Checks",
            "mcb_bank_cheque",
            "mcb_bank_cheque2",
            "petty_cash_balance",
            "Petty_cash_reconciliation",
            "petty_cash_vouchers",
            "state_bank_cheque",
            "Sub_Ledger_book",
            "Sub_Ledger_list",
            "SUBTRIAL_BALANCE",
            "SUBTRIAL_BALANCE_CLOSE_BAL",
            "SUBTRIAL_BALANCE_COST_CENTRE",
            "TRIAL_BALANCE",
            "TRIAL_BALANCE_CLOSE_BAL",
            "TRIAL_BALANCE_COST_CENTRE",
            "TRIAL_BALANCE_COST_CENTRE_CLOSE_BAL",
            "TRIAL_BALANCE_FOR_THE_PERIOD",
            "TRIAL_BALANCE_OPEN_BALANCE",
            "union_bank_cheque",
            "united_bank_cheque"
        };
        if (gl) buildReports(REPORTS + "\\GL\\", glReports);


        // ________________________________________________________________
        //
        // Build Custody
        // ________________________________________________________________
        String custodyForms[] = {
            "CUSTODY_ACTIVITY_FORM",
            "CUSTODY_ACTIVITY_GROUP_FORM",
            "CUSTODY_ANNOUNCEMENTS_FORM",
            "CUSTODY_DIVIDEND_FORM",
            "CUSTODY_EXPENSE_MASTER_FORM",
            "CUSTODY_EXPENSES_FORM",
            "CUSTODY_MASTER_FORM",
            "CUSTODY_OPENING_BALANCE",
            "CUSTODY_PARAMETER_FORM",
            "CUSTODY_PHY_SHARES_RECV_DET",
            "CUSTODY_SLABS_FORM",
            "CUSTODY_SYSTEM_FORM",
            "CUSTODY_TARIFF_FORM",
            "FIS_CUSTODY_MERGING",
            "PHYSICAL_SHARES_MERGING",
            "TARIFF_SECURITY_CUSTODY_FORM",
            "UPDATE_CDC_BALANCE_FILE"
        };
        if (custody) buildForms(FORMS + "\\Custody\\", custodyForms);

        String custodyReports[] = {
            "Announcement_Client",
            "Announcement_Detail",
            "Announcement_Security",
            "Audit_Log",
            "AvailableShares_Client",
            "AvailableShares_Security",
            "BONUS_RECEIPT_PRINTING",
            "BRANCH_WISE_AVAILABILITY",
            "CDC_BALANCE_COMPARISON",
            "ClientWiseTransLedger",
            "CLOSING_RATE_CHK_LST",
            "Cust_Bill_sum",
            "Custody_Activities",
            "Custody_Activity_List",
            "Custody_bill",
            "CUSTODY_BILL_SUM_SINGLE_CLNT",
            "CUSTODY_CASH_BOOK_MARGIN_SUMMARY",
            "CUSTODY_DIVIDEND_CLIENT_WISE",
            "CUSTODY_DIVIDEND_SECURITY_WISE",
            "CUSTODY_EXPENSE_CLIENT_WISE",
            "Custody_Expense_Master_List",
            "CUSTODY_EXPENSE_WISE",
            "CUSTODY_HOLDING_SUMMARY",
            "Custody_NetShares_Client",
            "CUSTODY_SHARE_VALUATION",
            "Custody_Slab_List",
            "CUSTODY_SUMMARY_BILL_QTR",
            "Custody_Tarrif_List",
            "Depreciation_schedule_report",
            "ind_cust_bill",
            "OutStanding_Benefits_Client",
            "OutStanding_Benefits_Security",
            "RECEIPT_PRINTING",
            "Shares_Receipt",
            "Shares_Receipt_Send_TO_CDC",
            "TEST_BILL",
            "Test_Custody_Bill_detail",
            "Unmatched_Client",
            "Unmatched_Isin"
        };
        if (custody) buildReports(REPORTS + "\\Custody\\", custodyReports);

        // ________________________________________________________________
        //
        // Build Human Resource
        // ________________________________________________________________
        String HRForms[] = {
            "APPRAISAL_FORM",
            "BLOOD_GROUP_FORM",
            "COURSE_FORM",
            "DEGREE_FORM",
            "EMPLOYEE_BASIC_INFO",
            "EMPLOYEE_PERKS_FORM",
            //"EMPLOYEE_PHOTO_FORM",
            "EMPLOYMENT_REQUISITION_FORM",
            "EVALUATION_DETAIL_FORM",
            "EVALUATION_GROUP_FORM",
            "EXECUTIVE_GRADE_FORM",
            "EXIT_INTERVIEW_FORM",
            "EXIT_INTERVIEW_MASTER",
            "EXIT_TYPE_FORM",
            "HR_PARAMETER_FORM",
            "INSTITUTION_FORM",
            "INSTITUTION_TYPE_FORM",
            "INTERVIEW_APPRAISAL_MASTER",
            "JOB_TITLE_FORM",
            "LOCATIONS_FORM",
            "PERFORMANCE_BONUS_FORM",
            "PERFORMANCE_EVALUATION_MASTER",
            "PERQS_DETAIL_FORM",
            "PERQS_GROUP_FORM",
            "PREVIOUS_EXPERIENCE_FORM",
            "PROFESSIONAL_LICENSE_FORM",
            "RELATIONSHIP_FORM",
            "TRAINING_MASTER"
        };
        if (hr) buildForms(FORMS + "\\HR\\", HRForms);

        String HRReports [] = {
            "Appraisal",
            "Bank_Employee",
            "Blood_Group",
            "BloodGroup_Employee",
            "Branch",
            "Branch_Employee",
            "City",
            "City_Employee",
            "Country",
            "Country1",
            "Country_Employee",
            "Course",
            "Currency",
            "Degree",
            "Department",
            "Department_Employee",
            "Employee_Basic_Info",
            "Employee_Category",
            "Employee_Type",
            "EmployeeCategory_Employee",
            "EmployeeType_Employee",
            "Evaluation_Detail",
            "Evaluation_Group",
            "Executive_Grade",
            "ExecutiveGrade_Employee",
            "Exit_Interview",
            "Institution",
            "Institution_Type",
            "Job_title",
            "JobTitle_Employee",
            "Language",
            "Location_Employee",
            "locations",
            "perqs_group",
            "professional_license",
            "Relationship",
            "Relationship_Employee",
            "Religion",
            "Religion_Employee"
        };
        if (hr) buildReports(REPORTS + "\\HR\\", HRReports);

        String HRGraphReports[] = {
            "Age_Group_BAR",
            "Education_Bar",
            "Gender_Col",
            "Gender_Pie",
            "Marital_Status_Col",
            "Marital_Status_Pie",
            "Service_in_Years_Col",
            "Service_in_Years_Group_Col"
        };
        if (hr) buildReports(REPORTS + "\\HR\\Graphs\\", HRGraphReports);


        // ________________________________________________________________
        //
        // Build LIBRARY Information
        // ________________________________________________________________
        String libraryForms[] = {
            "AUTHORS_FORM",
            "ITEM_CATEGORY_FORM",
            "ITEM_DETAILS_FORM",
            "ITEM_ISSUE_FORM",
            "ITEM_RECEIVED_FORM",
            "ITEM_SUB_CATEGORY_FORM",
            "LIB_TYPE_FORM",
            "LIBRARY_PARAMETER_FORM"
        };
        if (library) buildForms(FORMS + "\\Library\\", libraryForms);

        String libraryReports[] = {
            "Auhtor_List",
            "BOOK_LIST_GROUP_BY_AUTHOR",
            "BOOK_LIST_GROUP_BY_CATEGORY",
            "BOOK_LIST_GROUP_BY_PUBLISHER",
            "BOOK_LIST_GROUP_BY_TITLE",
            "BOOK_LIST_GROUP_BY_TYPE",
            "Category_List",
            "Item_Type_List"
        };
        if (library) buildReports(REPORTS + "\\Library\\", libraryReports);


        // ________________________________________________________________
        //
        // Build Mailing and Label
        // ________________________________________________________________
        String mailingForms[] = {
            "MAILING_CONTACT_FORM",
            "MAILING_DESIGNATION_FORM",
            "MAILING_GROUP_FORM",
            "MAILING_PARAMETER_FORM",
            "MAILING_PLACE_FORM"
        };
        if (mailing) buildForms(FORMS + "\\MAILING\\", mailingForms);

        String mailingReports[] = {
            "rep_mailing_labels",
            "rep_mailing_labels_DESIG",
            "rep_mailing_labels_gp",
            "rep_mailing_labels_no_group",
            "rep_mailing_labels_pg"
        };
        if (mailing) buildReports(REPORTS + "\\MAILING\\", mailingReports);


        // ________________________________________________________________
        //
        // Build Money Market
        // ________________________________________________________________
        String mmForms[] = {
            "MM_BILL",
            "MM_BILL_CANCELLATION",
            "MM_CONTRACT",
            "MM_MONTHLY_TARGET",
            "MM_Parameter_FORM",
            "MM_PIB_BIDS",
            "MM_SHARES_CONTRACT",
            "MM_TB_BIDS"
        };
        if (moneyMarket) buildForms(FORMS + "\\MoneyMarket\\", mmForms);
        String mmReports[] = {
		"CLIENTS_REPO_TENOR",
		//"MM_BILL",
		//"MM_BILL_CANCELLATION",
		"MM_BROKERAGE_ACHIVED",
		"MM_CALL_CONTRACT",
		//"MM_SHARES_CONTRACT",
		"MM_CLEAN_CONTRACT",
		"MM_Clients_list",
		"MM_COI_CONTRACT",
		"MM_DETAIL_BROKERAGE_BILL",
		"MM_DETAIL_BROKERAGE_BILL_SCHEME_WISE",
		"MM_PERIODIC_MATURITY",
		"MM_PIB_AUCTION_DETAIL_S_WISE",
		"MM_REPO_AGAINST_CONTRACT",
		"MM_REPO_BOND_BILL",
		"MM_REPO_CONTRACT_FIB",
		"MM_REPO_PIB",
		"MM_REPO_TBILL",
		"MM_REPO_TFC",
		"MM_TARGET_CLIENTS_LIST",
		"MM_TB_AUCTION_DETAIL_S_WISE",
		"mm_total_monthly_brok",
		"MM_TRADE_WISE_BROK_DETAIL",
		"OUTRIGHT_BOND",
		"OUTRIGHT_FIB",
		"OUTRIGHT_PIB",
		"OUTRIGHT_TBILL",
		"OUTRIGHT_TFC",
		"PIB_summary",
		"TBill_summary",
        };
        if (moneyMarket) buildReports(REPORTS + "\\MoneyMarket\\", mmReports);


        // ________________________________________________________________
        //
        // Build Fixed Income Securities
        // ________________________________________________________________
        String fisForms[] = {
            "CALCULATION_FORM",
            "FIS_ANNEXURE_FORM",
            "FIS_BILL",
            "FIS_BILL_CANCELLATION",
            "FIS_BROKERAGE_TYPE",
            "FIS_CONTRACT_FORM",
            "FIS_GL_INTERFACE_FORM",
            "FIS_MM_SYSTEM",
            "FIS_OPENING_BALANCE",
            "FIS_OTHER_CONTRACT_FORM",
            "FIS_PARAMETER_FORM",
            "SCHEME_FORM",
            "SCHEME_ISSUE_FORM",
            "SCHEME_ISSUE_TERM_STRUCTURE",
            "SCHEME_TYPE_FORM",
            "WALK_IN_CLIENT_FORM"
        };
        if (fis) buildForms(FORMS + "\\FIS\\", fisForms);

        String fisReports[] = {
            "ANNEXURE_DETAIL",
            "Clients_information",
            "FIB_WAPDA_BILL",
            "FIB_WAPDA_COST",
            "FIB_WAPDA_PROCEED",
            "FIS_BATCH_RELATED",
            "FIS_CAPITALGAINLOSS_SUM",
            "FIS_CAPITALGAINLOSSDETAIL",
            "FIS_Client_Register",
            "FIS_DIMINUTION_REPORT",
            "FIS_Inventory",
            "FIS_Register",
            "FIS_REPO_BILL",
            "Issue_Wise_Borrowing_Cost",
            "ISSUE_WISE_PERIODIC_NET",
            "Month_wise_repo_cost",
            "OD_COST",
            "OPEN_POSITION",
            "PERIODIC_GROSS_PROFIT",
            "PERIODIC_GROSS_PROFIT_SUMMARY",
            "TBILLS_COST",
            "TBILLS_PROCEED",
            "TERM_STRUCTURE_REPORT",
            "TEST_CONTRACT",
            "TFC_DETAIL_BILL",
            "TFC_DETAIL_COST",
            "TFC_DETAIL_PROCEED",
            "TFC_Profit_Loss",
            "TFC_Profit_Loss_Other",
            "TFC_SHORT_BILL",
            "TFC_SHORT_COST",
            "TFC_SHORT_PROCEED",
            "TREASURY_BILLS"
        };
        if (fis) buildReports(REPORTS + "\\FIS\\", fisReports);


        // ________________________________________________________________
        //
        // Build Phone Bill System
        // ________________________________________________________________
        String phoneForms[] = {
            "PHONE_BILLS_FORM",
            "PHONE_PARAMETER_FORM",
            "PHONES_FORM"
        };
        if (phone) buildForms(FORMS + "\\PhoneBill\\", phoneForms);
        String phoneReports[] = {
            "rep_amount_list_phone_bill_D",
            "rep_amount_list_phone_bill_P",
            "rep_detail_phone_bill_DLP",
            "rep_detail_phone_bill_LDP",
            "rep_summary_phone_bill_DLP",
            "rep_summary_phone_bill_LDP",
            "rep_year_wise_phone_bill_DP"
       };
       if (phone) buildReports(REPORTS + "\\PhoneBill\\", phoneReports);


        // ________________________________________________________________
        //
        // Build Tax Assessment
        // ________________________________________________________________
        String taxForms[] = {
            "TAX_ASSESSEE_INFO_FORM",
            "TAX_ASSESSEMENT_PARAMETER_FORM",
            "TAX_CHALAN_PRINTING_FORM",
            "TAX_DEDUCTION_PAYMENT_BOOKS",
            "TAX_VENDOR_TYPE_FORM"
        };
        if (tax) buildForms(FORMS + "\\TaxAssessment\\", taxForms);
        String taxReports [] = {
            "TAX_PAYMENT_RECEIPT",
            "TAX_Statement",
            "TAX_SUMMARY_CHALAN"

        };
        if (tax) buildReports(REPORTS + "\\TaxAssessment\\", taxReports);

        // ________________________________________________________________
        //
        // Build Payroll
        // ________________________________________________________________
        String payRollForms[] = {
            "ADVANCE_FORM",
            "ADVANCE_TYPE_FORM",
            "ALLOWENCES_TYPES_FORM",
            "ARREAR_FORM",
            "ARREAR_TYPE_FORM",
            "ATTENDANCE_REGISTER_FORM",
            "ATTENDANCE_STATUS_FORM",
            "BONUS_DISBURSEMENT_FORM",
            "BONUS_FORM",
            "BONUS_TYPE_FORM",
            "DEDUCTION_FORM",
            "DEDUCTION_TYPE_FORM",
            "EMPLOYEE_REST_DAY_FORM",
            "INCREMENT_FORM",
            "LEAVE_BALANCE_FORM",
            "LEAVE_DETAIL_FORM",
            "LEAVE_ENCASHMENT_FORM",
            "LEAVE_TYPE_FORM",
            "LFA_BALANCE_FORM",
            "LFA_PAYMENT_FORM",
            "LOAN_FORM",
            "LOAN_ISSUE_FORM",
            "LOAN_PAYMENT_FORM",
            "LOAN_TYPE_FORM",
            "MEDICAL_LIMIT_FORM",
            "MEDICAL_REIMBERSEMENT_FORM",
            "OTHER_PAYMENTS_FORM",
            "PAYROLL_PARAMETER_FORM",
            "PAYROLL_SYSTEM",
            "PF_BALANCE_FORM",
            "PF_DETAIL_FORM",
            "PF_PROFIT_FORM",
            "PROMOTION_FORM",
            "RESN_TERM_FORM",
            "REST_DAYS_SCHEDULER_FORM",
            "SALARY_CALCULATION_FORM",
            "SALARY_STRUCTURE_MF",
            "SHIFT_FORM"
        };
        if (payroll) buildForms(FORMS + "\\PayRoll\\", payRollForms);

        String payrollReports[] = {
            "Advance_Type_List",
            "Allowances_Type_List",
            "Arrear_Type_List",
            "Attendance_Register_branchWise",
            "Attendance_Register_DeptWise",
            "Attendance_Status_List",
            "Bank_Wise_List",
            "Bonus",
            "Bonus_Type_List",
            "Deduction_Type_List",
            "Department_Salary_Sheet",
            "Department_Summary",
            "Dept_Leave_record",
            "Employee_Rest_Day_List",
            "EMPLOYEE_WISE_SALARY_STRUCTURE_LIST",
            "EOBI_List",
            "EOBI_Slips",
            "GRATUITY_PAID",
            "GRATUITY_PRVISION",
            "GRATUITY_SUMMARY",
            "GRATUITY2",
            "InComing_Employees",
            "Increment",
            "leave_detail",
            "leave_encashment_day_wise",
            "Leave_Record",
            "Leave_Type_List",
            "LFA_PAID",
            "LFA_Provision",
            "LFA_REPORT_FP",
            "Loan_Deductions",
            "Loan_Type_List",
            "Medical_Payment_Individual",
            "Medical_Payment_Summary",
            "Medical_Summary",
            "Medical_VALUATION",
            "Outgoing_Employees",
            "payroll_probitionary",
            "PAYROLL_PROVISION",
            "PF_DETAIL",
            "PF_SUMMARY",
            "REMUNERATION",
            "REMUNERATION_WITH_LEC",
            "Resigned_Employees",
            "Salary_Sheet",
            "SALARY_STRUCTURE_LIST",
            "Shift_List",
            "Tax",
            "Terminated_Employees"
        };
        if (payroll) buildReports(REPORTS + "\\PayRoll\\", payrollReports);

        // ________________________________________________________________
        //
        // Build Stock and Fuel
        // ________________________________________________________________
        String stockFuelForms[] = {
            "APPROVAL_FORM",
            "CONSUMABLE_ITEM_PURCHASE",
            "CONSUMPTION_FORM",
            "EQUIPMENT_FORM",
            "EQUIPMENT_ISSUE_FORM",
            "EQUIPMENT_RETURN_FORM",
            "EQUIPMENT_TYPE_FORM",
            "FIXED_ITEM_PURCHASE",
            "FUEL_CONSUMPTION_FORM",
            "MAINTENANCE_FORM",
            "STOCK_PARAMETER_FORM",
            "SUPPLIER_FORM",
            "SUPPLIER_TYPE_FORM"
        };
        if (stockfuel) buildForms(FORMS + "\\StockFuel\\", stockFuelForms);
        String stockFuelReports[] = {
            "consumption_register",
            "department_wise_items_issued_detail",
            "Equipment_List",
            "Equipment_Type_List",
            "fuel_consumption",
            "item_purchase_detail",
            "items_issued_detail",
            "maintenance_register",
            "mintenance_summary",
            "over_fuel_consumption",
            "purchase_processing",
            "stock_control_system",
            "stock_summary_fp",
            "Supl_Type_List",
            "Supplier_List",
            "Supplier_Type_List",
            "Supply_Type_List",
            "vehicle_list"
        };
        if (stockfuel) buildReports(REPORTS + "\\StockFuel\\", stockFuelReports);

        // ________________________________________________________________
        //
        // Build FOREX
        // ________________________________________________________________
        String forexForms[] = {
            "FOREX_BILL_CANCELLATION",
            "FOREX_BILLING",
            "FOREX_CONTRACT",
            "FOREX_PARAMETER_FORM",
            "FOREX_SETTLEMENT_BANK",
            "FOREX_SYSTEM",
            "TAKEN_UP_FORM"
        };
        if (forex) buildForms(FORMS + "\\forex\\", forexForms);
        String forexReports [] = {
            "Bill_detail",
            "Bill_generation_detail",
            "bill_generation_summury",
            "client_summary",
            "Clt_List",
            "DActivity(takenup)",
            "DActivity",
            "F_bill_summury",
            "F_contract",
            "F_contract1",
            "Holidays",
            "periodic_cancel",
            "Periodic_cont_list",
            "periodic_maturityWise"
        };
        if (forex) buildReports(REPORTS + "\\forex\\", forexReports);


        String listingReports [] = {
            "Holidays_List"
        };
        if (listing) buildReports(REPORTS + "\\listing\\", listingReports);

        String listingReportsAMS [] = {
            "user_rights_list",
            "user_roles_list"
        };
        if (listing) buildReports(REPORTS + "\\listing\\ams\\", listingReportsAMS);

        String listingReportsClient [] = {
            "Client_Business_List",
            "Client_Document_List",
            "Client_Group_List",
            "Client_List",
            "Client_Occupation_LIst",
            "Client_Type_List",
            "Custodian_List"
        };
        if (listing) buildReports(REPORTS + "\\listing\\client\\", listingReportsClient);

        String listingReportsExchange [] = {
            "Clearing_Calendar_List",
            "Clearing_Type_List",
            "Market_Type_List",
            "Member_List",
            "Sector_List",
            "Security_List",
            "Security_Type_List",
            "Stock_Exchange_List",
            "Stock_Exchange_Security_List",
            "Trade_Type_List"
        };
        if (listing) buildReports(REPORTS + "\\listing\\exchange\\", listingReportsExchange);

        String listingReportsFISMM [] = {
            "FIS_BROKERAGE_TYPE_LIST",
            "SCHEME_LIST",
            "SCHEME_TYPE_LIST"
        };
        if (listing) buildReports(REPORTS + "\\listing\\fis and mm\\", listingReportsFISMM);

        String listingReportsHouse [] = {
            "AGENT_LIST",
            "BANK_LIST",
            "BRANCH_LIST",
            "BUSINESS_AREA_LIST",
            "DEPARTMENT_LIST",
            "TRADER_LIST"
        };
        if (listing) buildReports(REPORTS + "\\listing\\house\\", listingReportsHouse);

        String listingReportsRegional [] = {
            "CITY_LIST",
            "COUNTRY_LIST",
            "CURRENCY_LIST",
            "LANGUAGE_LIST",
            "RELIGION_LIST"
        };
        if (listing) buildReports(REPORTS + "\\listing\\Regional\\", listingReportsRegional);
    }

    /**
    * Build Library files
    */
    public static void buildPackages()
    {
        String start = COMPILER + " Module=" + PACKAGES + "\\";
        String end   = " UserId=" + CONNECT_STRING + " Window_State=Minimize Batch=y Module_type=LIBRARY";

        /************************************/
        /* TO DO - Add more libraries */
        /************************************/
        String libraries[] = {
                            "AMS",
                            "Commands",
                            "EquityTradeEntry",
                            "Triggers",
                            "Util",
                            "picklist"
                            };

        for (int x = 0; x < libraries.length; x++)
        {
            System.out.println("Compiling Library: " + PACKAGES + "\\" + libraries[x]);
            if (runCommand(start + libraries[x] + ".pll" + end) != 0)
            {
                printFile(PACKAGES + "\\" + libraries[x] + ".err");
                System.out.println("ERROR: Failed to generate " + libraries[x] + ", terminating compilation....");
            }
        }
    }
    /************************************************************************************/



    /**
    * Build Framework
    */
    public static void buildFramework()
    {
        // generate Menu
        String start = COMPILER + " Module=" + FRAMEWORK + "\\";
        String end   = " UserId=" + CONNECT_STRING + " Window_State=Minimize Batch=y Module_type=MENU";
        System.out.println("Compiling Menu");
        if (runCommand(start + "main_menu.mmb" + end) != 0)
        {
            printFile(FRAMEWORK + "\\main_menu.err");
            System.out.println("ERROR: Failed to generate Main Menu, terminating compilation....");
        }

        // Generate other framework files
        end   = " UserId=" + CONNECT_STRING + " Window_State=Minimize Batch=y Module_type=FORM";
        String files[] = {
                        "ABOUT_FORM",
                        "BASE",
                        "CHANGE_PASSWORD",
                        "LOCK_SCREEN",
                        "LOGIN",
                        "MAIN_FORM"
                      };

        for (int x = 0; x < files.length; x++)
        {
            System.out.println("Compiling Framework File: " +  FRAMEWORK + "\\" + files[x]);
            if (runCommand(start + files[x] + ".fmb" + end) != 0)
            {
                printFile(FRAMEWORK + "\\" + files[x] + ".err");
                System.out.println("ERROR: Failed to generate " + files[x] + ", terminating compilation....");
            }
        }
    }
    /************************************************************************************/

    /**
     *
     */
     public static void buildForms(String directory, String forms[])
     {
        String start = COMPILER + " Module=" + directory;
        String end   = " UserId=" + CONNECT_STRING + " Window_State=Minimize Batch=y Module_type=FORM";

        for (int x = 0; x < forms.length; x++)
        {
            System.out.println("Compiling Form: " + directory + forms[x]);
            if (runCommand(start + forms[x] + ".fmb" + end) != 0)
            {
                printFile(directory + forms[x] + ".err");
                System.out.println("ERROR: Failed to generate " + forms[x] + ", terminating compilation....");
            }
        }
     }
    /************************************************************************************/


    /**
     *
     */
     public static void buildReports(String directory, String reports[])
     {
        String start = CONVERTOR + " UserId=" + CONNECT_STRING + " STYPE=RDFFILE" + " SOURCE=" + directory;
        String end   = " DTYPE=REPFILE OVERWRITE=YES Batch=YES LOGFILE=reporterror.log";

        for (int x = 0; x < reports.length; x++)
        {
            System.out.println("Compiling Report:" + directory + reports[x]);
            if (runCommand(start + reports[x] + ".rdf" + end) != 0)
            {
                //printFile(directory + reports[x] + ".err");
                System.out.println("ERROR: Failed to generate " + reports[x] + ", terminating compilation....");
            }
        }
     }
    /************************************************************************************/


    /**
     *
     */
    public static void deleteOldBinaries()
    {
        // delete .err (LOG files)
        try
        {
            Runtime.getRuntime().exec("del " + ROOT + "\\*.err /s");
            Runtime.getRuntime().exec("del " + FORMS + "\\*.fmx");
            Runtime.getRuntime().exec("del " + FORMS + "\\*.mmx");
            Runtime.getRuntime().exec("del " + PACKAGES + "\\*.plx");
            Runtime.getRuntime().exec("del " + FORMS + "\\*.fmx");
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
    }
    /************************************************************************************/


    public static int runCommand(String cmd)
    {
        //System.out.println(cmd);
        try
        {
            Process process = Runtime.getRuntime().exec(cmd);
            process.waitFor();
            return process.exitValue();
        }
        catch (Exception e)
        {
            e.printStackTrace();
            return -1;
        }
    }
    /************************************************************************************/

    public static void printFile(String fileName)
    {
        BufferedReader in = null;
        try
        {
            in = new BufferedReader(new FileReader(fileName));
        }
        catch (FileNotFoundException e)
        {
            return;
        }
        catch (Exception e)
        {
            e.printStackTrace();
            return;
        }
        String line = null;
        while (true)
        {
            try
            {
                line = in.readLine();
            }
            catch (IOException e)
            {
                e.printStackTrace();
            }
            if (line == null || line.equals(""))
            {
                break;
            }
            else
            {
                System.out.println(line);
            }
        }
    }
    /************************************************************************************/

}
