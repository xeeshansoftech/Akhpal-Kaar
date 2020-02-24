create or replace package Periodic_Reports is

  -- Author  : ASIM
  -- Created : 13-12-2005 10:47:22 AM
  -- Purpose : Using Aggregation Data Ware Housing Concepts

type type_coluu is table of varchar2(100);
type coloomn is table of varchar2(100);
type f_coloomn is table of varchar2(10000);
type columnn is table of periodic.column_name%type;

procedure tr_tb;
procedure col_where;
procedure trunc_periodic;
procedure trunc_agg_string;
procedure trunc_header_columns;
procedure deletion(repname varchar2);
function listbox_str return varchar2;
function select_string return varchar2;
function col_where_clause return varchar2;
function agg_level(csn number) return number;
procedure getvalue(repnme varchar2,tbnme varchar2);
function columns_string (cse number) return varchar2;
procedure insertvalue(repnme varchar2,tbnme varchar2);
function qualifier(col_name varchar2) return varchar2;

end Periodic_Reports;
/
create or replace package body Periodic_Reports is

-- Calculates Aggregation Level Vide Bit Positions.

 function agg_level (csn number) return number is

  type position is table of number;
  pos position;
  cnt number :=0;
  cmt number :=0;
  col_names columnn;
  agg_level number :=1;
  tmp varchar2(50);
  begin

  pos := position (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);

    if csn = 1 then
     select count(*) into cnt from periodic p;
     if cnt <> 0 then
      select p.column_name bulk collect into col_names from periodic p;
     end if;
     elsif csn = 2 then
       col_names := columnn('','');
       select g.roll_one into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(1) := tmp;
       end if;
       select g.roll_two into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(2) := tmp;
       end if;
     elsif csn = 21 then
       col_names := columnn('','','');
       select g.roll_one into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(1) := tmp;
       end if;
       select g.roll_two into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(2) := tmp;
       end if;
       select g.roll_three into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(3) := tmp;
       end if;
     elsif csn = 22 then
       col_names := columnn('','','','');
       select g.roll_one into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(1) := tmp;
       end if;
       select g.roll_two into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(2) := tmp;
       end if;
       select g.roll_three into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(3) := tmp;
       end if;
       select g.roll_four into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(4) := tmp;
       end if;
     elsif csn = 23 then
       col_names := columnn('','','','','');
       select g.roll_one into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(1) := tmp;
       end if;
       select g.roll_two into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(2) := tmp;
       end if;
       select g.roll_three into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(3) := tmp;
       end if;
       select g.roll_four into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(4) := tmp;
       end if;
       select g.roll_five into tmp from agg_string g;
       if length (tmp) <> 0 then
        col_names(5) := tmp;
       end if;
    elsif csn = 3 then
     col_names := columnn('');
     select g.roll_one into tmp from agg_string g;
     if length (tmp) <> 0 then
      col_names(1) := tmp;
     end if;
    elsif csn = 99 then
     col_names := columnn('','','','','','','','','','','','','','','','','','','');
     col_names(19) :=0;
     col_names(18) :=0;col_names(17) :=0;col_names(16) :=0;
     col_names(15) :=0;col_names(14) :=0;col_names(13) :=0;
     col_names(12) :=0;col_names(11) :=0;col_names(10) :=0;col_names(9) :=0;
     col_names(8) :=0;col_names(7) :=0;col_names(6) :=0;col_names(5) :=0;
     col_names(4) :=0;col_names(3) :=0;col_names(2) :=0;col_names(1) :=0;
     agg_level :=1;
     end if;
    cmt :=col_names.last;
    if cmt <> 0 then
     for s in 1..col_names.last loop
     --dbms_output.put_line (col_names(s));
     if Lower(col_names(s)) ='client_code' then
      pos(19):=0;
     elsif Lower(col_names(s)) ='client_name' then
      pos(18):=0;
     elsif Lower(col_names(s)) ='client_type' then
      pos(17):=0;
     elsif Lower(col_names(s)) ='client_group' then
      pos(16):=0;
     elsif Lower(col_names(s)) ='security_symbol' then
      pos(15):=0;
     elsif Lower(col_names(s)) ='isin' then
      pos(14):=0;
     elsif Lower(col_names(s)) ='exchange_name' then
      pos(13):=0;
     elsif Lower(col_names(s)) ='security_name' then
      pos(12):=0;
     elsif Lower(col_names(s)) ='clearing_type' then
      pos(11):=0;
     elsif Lower(col_names(s)) ='market_type' then
      pos(10):=0;
     elsif Lower(col_names(s)) ='trade_type' then
      pos(9):=0;
     elsif Lower(col_names(s)) ='settlement_date' then
      pos(8):=0;
     elsif Lower(col_names(s)) ='trade_date' then
      pos(7):=0;
     elsif Lower(col_names(s)) ='trade_number' then
      pos(6):=0;
     elsif Lower(col_names(s)) ='bill_number' then
      pos(5):=0;
     elsif Lower(col_names(s)) ='buy_or_sell' then
      pos(4):=0;
     elsif Lower(col_names(s)) ='share_rate' then
      pos(3):=0;
     elsif Lower(col_names(s)) ='se_trade' then
      pos(2):=0;
     elsif Lower(col_names(s)) ='trader_code' then
      pos(1):=0;
     elsif Lower(col_names(s)) ='trader_name' then
      agg_level :=0;

     end if;
  end loop;
  -- Calculation of Aggregation Level vide Arugument Columns.
  for c in 1..pos.last loop
   if pos(c)=1  then
    agg_level :=agg_level + power(2,c);
    dbms_output.put_line(agg_level);
   end if;
  end loop;
  return agg_level;
  end if;

  return 0;
  end agg_level;


 function select_string return varchar2 is

 col columnn;
 cnt number :=0;
 str varchar2(30000);
 stra varchar2(1000); strb varchar2(1000); strc varchar2(1000);
 str1 varchar2(50) :='null client_code, ' ;str2 varchar2(50) :='null client_name, ';str3 varchar2(50) :='null client_type, ' ;str4 varchar2(50)  :='null client_group, ';
 str5 varchar2(50) :='null security_symbol, ' ;str6 varchar2(50) :='null isin, ';str7 varchar2(50) :='null exchange_name, ' ;str8 varchar2(50)  :='null security_name, ';
 str9 varchar2(50) :='null clearing_type, ' ;str10 varchar2(50):='null market_type, ';str11 varchar2(50):='null trade_type, ' ;str12 varchar2(50) :='null settlement_date, ';
 str13 varchar2(50):='null trade_date, ' ;str14 varchar2(50):='null trade_number, ';str15 varchar2(50):='null bill_number, ' ;str16 varchar2(50) :='null buy_or_sell, ';
 str17 varchar2(50):='null buy_volume, ' ;str18 varchar2(50):='null sell_volume, ';str19 varchar2(50):='null volume, ' ;str20 varchar2(50) :='share_rate, ';
 str21 varchar2(50):='null buy_amount, ' ;str22 varchar2(50):='null sell_amount, ';str23 varchar2(50):='null amount, ' ;str24 varchar2(50) :='brokerage, ';
 str25 varchar2(50):='null cvt, ' ;str26 varchar2(50):='null wht_sell, ';str27 varchar2(50):='null wht_cot, ' ;str28 varchar2(50) :='null wht,';
 str29 varchar2(50):='null ptr,' ;str30 varchar2(50):='null se_trade,';str31 varchar2(50):='null trader_code,' ;str32 varchar2(50) :='null trader_name,';
 str33  varchar2(50) :='gid_1';
 begin

 select p.column_name bulk collect into col from periodic p where p.valid='Y' order by p.seq_no;
 cnt := col.last;
 if cnt <> 0 then
  for n in 1..cnt loop

   if lower(col(n))= 'client_code' then str1 := 'client_code, ';
     elsif lower(col(n))= 'client_name' then str2 := 'client_name, ';
     elsif lower(col(n))= 'client_type' then str3 := 'client_type, ';
     elsif lower(col(n))= 'client_group'then str4 := 'client_group, ';
     elsif lower(col(n))= 'security_symbol' then str5 := 'security_symbol, ';
     elsif lower(col(n))= 'isin' then str6 := 'isin, ';
     elsif lower(col(n))= 'exchange_name' then str7 := 'exchange_name, ';
     elsif lower(col(n))= 'security_name'then str8 := 'security_name, ';
     elsif lower(col(n))= 'clearing_type' then str9 := 'clearing_type, ';
     elsif lower(col(n))= 'market_type' then str10 := 'market_type, ';
     elsif lower(col(n))= 'trade_type' then str11 := 'trade_type, ';
     elsif lower(col(n))= 'settlement_date' then str12 := 'to_char(settlement_date,''dd-mm-yyyy''), ';
     elsif lower(col(n))= 'trade_date' then str13 := 'to_char(trade_date,''dd-mm-yyyy''), ';
     elsif lower(col(n))= 'trade_number'  then str14 := 'trade_number, ';
     elsif lower(col(n))= 'bill_number' then str15 := 'bill_number, ';
     elsif lower(col(n))= 'buy_or_sell' then str16 := 'buy_or_sell, ';
     elsif lower(col(n))= 'buy_volume' then str17 := 'buy_volume, ';
     elsif lower(col(n))= 'sell_volume' then str18 := 'sell_volume, ';
     elsif lower(col(n))= 'volume' then str19 := 'volume, ';
     elsif lower(col(n))= 'share_rate' then str20 := 'share_rate, ';
     elsif lower(col(n))= 'buy_amount' then str21 := 'buy_amount, ';
     elsif lower(col(n))= 'sell_amount' then str22 := 'sell_amount, ';
     elsif lower(col(n))= 'amount' then str23 := 'amount, ';
     elsif lower(col(n))= 'brokerage' then str24 := 'brokerage, ';
     elsif lower(col(n))= 'cvt' then str25 := 'cvt, ';
     elsif lower(col(n))= 'wht_sell' then str26 := 'wht_sell, ';
     elsif lower(col(n))= 'wht_cot' then str27 := 'wht_cot, ';
     elsif lower(col(n))= 'wht' then str28 := 'wht, ';
     elsif lower(col(n))= 'ptr' then str29 := 'ptr, ';
     elsif lower(col(n))= 'se_trade' then str30 := 'se_trade, ';
     elsif lower(col(n))= 'trader_code' then str31 := 'trader_code, ';
     elsif lower(col(n))= 'trader_name'then str32 := 'trader_name, ';

   end if;
  end loop;
  stra := str1||str2||str3||str4||str5||str6||str7||str8||str9||str10;
  --dbms_output.put_line(stra);
  strb := str11||str12||str13||str14||str15||str16||str17||str18||str19||str20;
  --dbms_output.put_line(strb);
  strc := str21||str22||str23||str24||str25||str26||str27||str28||str29||str30||str31||str32||str33;
  --dbms_output.put_line(strc);
  str := stra||strb||strc;
  return str;
  else
  return null;
 end if; -- end of cnt loop.
 end;


 -- Returns the String for Columns,Groups for Reference to Report.
 function columns_string(cse number) return varchar2 is

 cnt number :=0;
 cmt number :=0;
 col_value varchar2(100);
 clause    varchar2(500);
 cnt_tb_count number :=0;
 col_string   varchar2(1000);
 excep_detail varchar2(1000);
 col columnn;
 temp varchar2(50);
 begin

 select count(*) into cnt from periodic p;
 select count(*) into cmt from agg_string q;
 if cnt <> 0 and cmt <> 0 then

 if    cse =1 then
  select p.column_value bulk collect into col from periodic p where p.column_value is not null and p.valid='Y' order by p.seq_no;
 elsif cse =2 then
  col := columnn ('','');
  select ag.roll_one into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(1) := col_value;
  select ag.roll_two into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(2) := col_value;
 elsif cse =21 then
  col := columnn ('','','');
  select ag.roll_one into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(1) := col_value;
  select ag.roll_two into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(2) := col_value;
  select ag.roll_three into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(3) := col_value;
 elsif cse =22 then
  col := columnn ('','','','');
  select ag.roll_one into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(1) := col_value;
  select ag.roll_two into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(2) := col_value;
  select ag.roll_three into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(3) := col_value;
  select ag.roll_four into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(4) := col_value;
 elsif cse =23 then
  col := columnn ('','','','','');
  select ag.roll_one into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(1) := col_value;
  select ag.roll_two into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(2) := col_value;
  select ag.roll_three into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(3) := col_value;
  select ag.roll_four into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(4) := col_value;
  select ag.roll_five into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(5) := col_value;
 elsif cse =3 then
  col := columnn ('');
  select ag.roll_one into temp from agg_string ag;
  select cl.column_value into col_value from periodic_columns cl where cl.column_name = temp;
  col(1) := col_value;
 end if;

 cnt_tb_count := col.last;
   if (cnt_tb_count <> 0 ) then
    for u in 1..cnt_tb_count loop
     if u <> cnt_tb_count then
      clause      := qualifier(col(u))||',';
      col_string  :=col_string||clause;
     else
      clause      := qualifier(col(u));
      col_string  := col_string||clause;
     end if;
    end loop;
    return '('||col_string||')';
   else
    return null;
   end if;
 else
 return null;
 end if;
 exception
 when others then
 excep_detail :=SQLERRM;
 dbms_output.put_line(excep_detail);
 end;


function qualifier(col_name varchar2) return varchar2 is
 qua_string varchar2(100);
 colname    varchar2(50);
begin

colname :=Lower(col_name);
if colname = 'trade_number' then
 qua_string :='trd.'||'trade_number';
elsif colname = 'trade_date' then
 qua_string :='trd.'||'trade_date';
elsif colname = 'client_code' then
 qua_string :='trd.'||'client_code';
elsif colname = 'title' then
 qua_string :='clnt_type.'||'title';
elsif colname = 'description' then
 qua_string :='cl_typ.'||'description';
elsif colname = 'settlement_date' then
 qua_string :='cl_cld.'||'settlement_date';
elsif colname = 'isin' then
 qua_string :='trd.'||'isin';
elsif colname = 'symbol' then
 qua_string :='sec.'||'symbol';
elsif colname = 'buy_or_sell' then
 qua_string :='trd.'||'buy_or_sell';
elsif colname = 'trade_type' then
 qua_string :='trd.'||'trade_type';
elsif colname = 'bill_number' then
 qua_string :='trd.'||'bill_number';
elsif colname = 'se_trade' then
 qua_string :='trd.'||'se_trade';
elsif colname = 'trader_code' then
 qua_string :='ord.'||'trader_code';
elsif colname = 'market_type' then
 qua_string :='ord.'||'market_type';
elsif colname = 'rate' then
 qua_string :='trd.'||'rate';
elsif colname = 'clients_short_name' then
 qua_string :='clnt.'||'clients_short_name';
elsif colname = 'group_code' then
 qua_string :='clnt_grp.'||'group_code';
elsif colname = 'security_short_name' then
 qua_string :='sec.'||'security_short_name';
elsif colname = 'short_name' then
 qua_string :='stk.'||'short_name';
elsif colname = '(emp.first_name||emp.last_name)' then
 qua_string :='(emp.first_name||emp.last_name)';

end if;
 return qua_string;
end;


 procedure col_where is

 cl coloomn;
 typ type_coluu;
 clause varchar2(100);
 item   varchar2(100);
 str    varchar2(20000);
 nm number :=0;

 begin

  select count(*) into nm from coluu;
  if nm <> 0 then
   nm :=0;
   select p.nme bulk collect into cl from coluu p where p.item is not null and p.nme is not null;
   select p.item bulk collect into typ from coluu p where p.item is not null and p.nme is not null;
   nm := cl.last;
   item := typ(1);
   for cnt in 1..nm loop
    if cnt <> nm then
     clause := ''''||cl(cnt)||''''||',';
     str    := str||clause;
     else
     clause := ''''||cl(cnt)||'''';
     str    := str||clause;
     end if;
    end loop;
  end if;
  insert into where_clause values(item||' '||'in ('||str||')');
  commit;
 end;


 function col_where_clause return varchar2 is
 -- uses temporary table i.e.create global temporary table where_clause (str varchar2(100)) on commit preserve rows
 n number :=0;
 f_col f_coloomn;
 str varchar2(32767);
 begin

 select count(*) into n from where_clause;
 if n <> 0 then
  select cl.str bulk collect into f_col from where_clause cl;
  n :=0;
  n :=f_col.last;
  if n=1 then
   str := f_col(1);
   elsif n=2 then
   str := f_col(1)||' '||'and'||' '||f_col(2);
   elsif n=3 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3);
   elsif n=4 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4);
   elsif n=5 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5);
   elsif n=6 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5)||' '||'and'||' '||f_col(6);
   elsif n=7 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5)||' '||'and'||' '||f_col(6)||' '||'and'||' '||f_col(7);
   elsif n=8 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5)||' '||'and'||' '||f_col(6)||' '||'and'||' '||f_col(7)||' '||'and'||' '||f_col(8);
   elsif n=9 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5)||' '||'and'||' '||f_col(6)||' '||'and'||' '||f_col(7)||' '||'and'||' '||f_col(8)||' '||'and'||' '||f_col(9);
   elsif n=10 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5)||' '||'and'||' '||f_col(6)||' '||'and'||' '||f_col(7)||' '||'and'||' '||f_col(8)||' '||'and'||' '||f_col(9)||' '||'and'||' '||f_col(10);
   elsif n=11 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5)||' '||'and'||' '||f_col(6)||' '||'and'||' '||f_col(7)||' '||'and'||' '||f_col(8)||' '||'and'||' '||f_col(9)||' '||'and'||' '||f_col(10)||' '||'and'||' '||f_col(11);
   elsif n=12 then
   str := f_col(1)||' '||'and'||' '||f_col(2)||' '||'and'||' '||f_col(3)||' '||'and'||' '||f_col(4)||' '||'and'||' '||f_col(5)||' '||'and'||' '||f_col(6)||' '||'and'||' '||f_col(7)||' '||'and'||' '||f_col(8)||' '||'and'||' '||f_col(9)||' '||'and'||' '||f_col(10)||' '||'and'||' '||f_col(11)||' '||'and'||' '||f_col(12);
  end if;
  return str;
 else
  return '1=1';
 end if;

 end;


 procedure tr_tb is

 begin
 execute immediate 'truncate table where_clause';
 end;

 procedure trunc_periodic is

 begin
 execute immediate 'truncate table periodic';
 end;

 procedure trunc_agg_string is

 begin
 execute immediate 'truncate table agg_string';
 end;

 procedure trunc_header_columns is
 begin
 execute immediate 'truncate table header_columns';
 end;

 procedure deletion (repname varchar2) is
 cnt number :=0;
 begin
  select count(*) into cnt from table(select s.col from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.col from periodic_save w where w.rep_name=repname);
   commit;
  end if;
  select count(*) into cnt from table(select s.cle from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.cle from periodic_save w where w.rep_name=repname);
   commit;
  end if;
  select count(*) into cnt from table(select s.trd from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.trd from periodic_save w where w.rep_name=repname);
   commit;
  end if;
  select count(*) into cnt from table(select s.mkt from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.mkt from periodic_save w where w.rep_name=repname);
   commit;
  end if;
  select count(*) into cnt from table(select s.stk from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.stk from periodic_save w where w.rep_name=repname);
   commit;
  end if;
  select count(*) into cnt from table(select s.tcd from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.tcd from periodic_save w where w.rep_name=repname);
   commit;
  end if;
  select count(*) into cnt from table(select s.ctp from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.ctp from periodic_save w where w.rep_name=repname);
   commit;
  end if;
  select count(*) into cnt from table(select s.cli from periodic_save s where s.rep_name=repname);
  if cnt <> 0 then
   delete from table(select w.cli from periodic_save w where w.rep_name=repname);
   commit;
  end if;

 end;

 procedure insertvalue(repnme varchar2,tbnme varchar2) is

 type names is table of varchar2(50);
 tb names;
 cnt number :=0;
 begin

 select count(*) into cnt from periodic_save where rep_name=repnme;
 -- Initalizing the Object-Relation Data Base. User has to retrieve the
 -- Data where values are not null.
 if cnt = 0 then
  insert into periodic_save values (repnme,colnames_tb(colnames('')),clearing_tb(clearing('')),tradetype_tb(tradetype('')),markettype_tb(markettype('')),stockexchange_tb(stockexchange('')),tradercode_tb(tradercode('')),clienttype_tb(clienttype('')),null,null,null,null,clients_tb(clients('','')),null,null);
  commit;
 end if;

 select count(*) into cnt from where_clause;
 if cnt <> 0 then
  select c.str bulk collect into tb from where_clause c;
 end if;

 if tbnme='column' and cnt <> 0 then
  for i in 1..tb.last loop
   insert into table(select s.col from periodic_save s where s.rep_name=repnme) values (tb(i));
  end loop;
  elsif tbnme='clearing' and cnt <> 0 then
  for i in 1..tb.last loop
   insert into table(select s.cle from periodic_save s where s.rep_name=repnme) values (tb(i));
  end loop;
  elsif tbnme='tradetype' and cnt <> 0 then
  for i in 1..tb.last loop
   insert into table(select s.trd from periodic_save s where s.rep_name=repnme) values (tb(i));
  end loop;
  elsif tbnme='markettype' and cnt <> 0 then
  for i in 1..tb.last loop
   insert into table(select s.mkt from periodic_save s where s.rep_name=repnme) values (tb(i));
  end loop;
  elsif tbnme='stocktype' and cnt <> 0 then
  for i in 1..tb.last loop
   insert into table(select s.stk from periodic_save s where s.rep_name=repnme) values (tb(i));
  end loop;
  elsif tbnme='tradercode' and cnt <> 0 then
  for i in 1..tb.last loop
   insert into table(select s.tcd from periodic_save s where s.rep_name=repnme) values (tb(i));
  end loop;
  elsif tbnme='clienttype' and cnt <> 0 then
  for i in 1..tb.last loop
   insert into table(select s.ctp from periodic_save s where s.rep_name=repnme) values (tb(i));
  end loop;
  elsif tbnme='clientrange' and cnt <> 0 then
   insert into table(select s.cli from periodic_save s where s.rep_name=repnme) values (tb(1),'');
   insert into table(select s.cli from periodic_save s where s.rep_name=repnme) values (tb(2),'');
  elsif tbnme='isin' and cnt <> 0 then
  for i in 1..tb.last loop
   update periodic_save s set s.sec=tb(i) where s.rep_name=repnme;
  end loop;
  elsif tbnme='billed' and cnt <> 0 then
  for i in 1..tb.last loop
   update periodic_save s set s.bill=tb(i) where s.rep_name=repnme;
  end loop;
  elsif tbnme='setrades' and cnt <> 0 then
  for i in 1..tb.last loop
   update periodic_save s set s.stock=tb(i) where s.rep_name=repnme;
  end loop;
  elsif tbnme='group' and cnt <> 0 then
  for i in 1..tb.last loop
   update periodic_save s set s.grpname=tb(i) where s.rep_name=repnme;
  end loop;
  elsif tbnme='fromdate' and cnt <> 0 then
  for i in 1..tb.last loop
   update periodic_save s set s.fromdate=tb(i) where s.rep_name=repnme;
  end loop;
  elsif tbnme='todate' and cnt <> 0 then
  for i in 1..tb.last loop
   update periodic_save s set s.todate=tb(i) where s.rep_name=repnme;
  end loop;

 end if;
 execute immediate 'truncate table where_clause';
 commit;
 end;


 procedure getvalue(repnme varchar2,tbnme varchar2) is

 begin
 if tbnme='column' then
  insert into where_clause select d.colname from periodic_save s,table(s.col)d where s.rep_name=repnme and d.colname is not null;
 elsif tbnme='clearing' then
  insert into where_clause select d.cler from periodic_save s,table(s.cle)d where s.rep_name=repnme and d.cler is not null;
 elsif tbnme='tradetype' then
  insert into where_clause select d.trade from periodic_save s,table(s.trd)d where s.rep_name=repnme and d.trade is not null;
 elsif tbnme='markettype' then
  insert into where_clause select d.market from periodic_save s,table(s.mkt)d where s.rep_name=repnme and d.market is not null;
 elsif tbnme='stocktype' then
  insert into where_clause select d.stock from periodic_save s,table(s.stk)d where s.rep_name=repnme and d.stock is not null;
 elsif tbnme='tradercode' then
  insert into where_clause select d.trdcode from periodic_save s,table(s.tcd)d where s.rep_name=repnme and d.trdcode is not null;
 elsif tbnme='clienttype' then
  insert into where_clause select d.client from periodic_save s,table(s.ctp)d where s.rep_name=repnme and d.client is not null;
 elsif tbnme='clientrange' then
  insert into where_clause select d.clientone from periodic_save s,table(s.cli)d where s.rep_name=repnme and d.clientone is not null;
 elsif tbnme='group' then
  insert into where_clause select s.grpname from periodic_save s where s.rep_name=repnme and s.grpname is not null;
 elsif tbnme='billed' then
  insert into where_clause select s.bill from periodic_save s where s.rep_name=repnme and s.bill is not null;
 elsif tbnme='setrades' then
  insert into where_clause select s.stock from periodic_save s where s.rep_name=repnme and s.stock is not null;
 elsif tbnme='isin' then
  insert into where_clause select s.sec from periodic_save s where s.rep_name=repnme and s.sec is not null;
 elsif tbnme='fromdate' then
  insert into where_clause select s.fromdate from periodic_save s where s.rep_name=repnme and s.fromdate is not null;
 elsif tbnme='todate' then
  insert into where_clause select s.todate from periodic_save s where s.rep_name=repnme and s.todate is not null;

 end if;
 commit;
 end;


 function listbox_str return varchar2 is

 cl coloomn;
 typ type_coluu;
 item varchar2(100);
 clause varchar2(500);
 str    varchar2(4000);
 nm number :=0;

 begin

  select count(*) into nm from coluu;
  if nm <> 0 then
   nm :=0;
   select p.nme bulk collect into cl from coluu p where p.item is not null and p.nme is not null;
   select p.item bulk collect into typ from coluu p where p.item is not null and p.nme is not null;

   nm := cl.last;
   item := typ(1);
   for u in 1..nm loop
   if u <> nm then
    clause := cl(u)||',';
    str    := str||clause;
   else
    clause := cl(u);
    str    := str||clause;
   end if;
   end loop;
  end if;
  return str;
 end;


end Periodic_Reports;
/
