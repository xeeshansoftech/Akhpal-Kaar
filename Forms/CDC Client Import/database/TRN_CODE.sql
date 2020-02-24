insert into trn_code (trn_code, description, menu_label,Module_code, post, log_id) values('T875','CLIENT CDC IMPORT FORM',NULL,'T',1,0)    
/
insert into trn_code (trn_code, description, menu_label,Module_code, post, log_id) values('T876','CLIENT CDC OPEN FORM',NULL,'T',1,0)    
/
 
begin
  run();
end;
/

commit;

