create or replace trigger "AU_TRG_RMS_CUST_CLIENTS_LOAN"
  before update or delete on RMS_CUST_CLIENTS_LOAN
  for each ROW

declare
  -- local variables here
  nextversion_no AUDIT_RMS_CUST_CLIENTS_LOAN.version_no%TYPE;

begin
  SELECT nvl(MAX(version_no), 0) + 1
    INTO nextversion_no
    FROM AUDIT_RMS_CUST_CLIENTS_LOAN RCL
   WHERE RCL.RMS_CUST_LOAN_ID = :old.RMS_CUST_LOAN_ID;

  INSERT INTO AUDIT_RMS_CUST_CLIENTS_LOAN
    (rms_cust_loan_id,
     loan_date,
     client_code,
     isin,
     loan_volume,
     settlement_date,
     approved_by,
     executed,
     post,
     log_id,
     version_no,
     rejected)
  VALUES
    (:Old.rms_cust_loan_id,
     :Old.loan_date,
     :Old.client_code,
     :Old.isin,
     :Old.loan_volume,
     :Old.settlement_date,
     :Old.approved_by,
     :Old.executed,
     :Old.post,
     :Old.log_id,
     nextversion_no,
     :Old.Rejected);
end AU_TRG_RMS_CUST_CLIENTS_LOAN;
/
