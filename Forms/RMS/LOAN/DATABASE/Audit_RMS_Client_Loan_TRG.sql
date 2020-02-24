create or replace trigger "AUDIT_TRG_RMS_CLIENTS_LOAN"
  before update or delete on RMS_CLIENTS_LOAN
  for each ROW

declare
  -- local variables here
  nextversion_no AUDIT_RMS_CLIENTS_LOAN.version_no%TYPE;

begin
  SELECT nvl(MAX(version_no), 0) + 1
    INTO nextversion_no
    FROM AUDIT_RMS_CLIENTS_LOAN RCL
   WHERE RCL.RMS_LOAN_ID = :old.RMS_LOAN_ID;

  INSERT INTO AUDIT_RMS_CLIENTS_LOAN
    (rms_loan_id,
     loan_date,
     client_code,
     loan_amount,
     approved_by,
     executed,
     post,
     log_id,
     version_no)
  VALUES
    (:Old.rms_loan_id,
     :Old.loan_date,
     :Old.client_code,
     :Old.loan_amount,
     :Old.approved_by,
     :Old.executed,
     :Old.post,
     :Old.log_id,
     nextversion_no);
end AUDIT_TRG_RMS_CLIENTS_LOAN;
