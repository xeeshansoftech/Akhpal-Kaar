create or replace trigger trg_aft_ins_trn_code
after insert or update on trn_code
begin
  begin
  run;
  end;
end trg_aft_ins_trn_code;
/