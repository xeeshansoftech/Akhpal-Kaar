CREATE OR REPLACE FUNCTION send_sms(message  IN  VARCHAR2) RETURN VARCHAR2 AS
    service_             SYS.UTL_DBWS.service;
    call_                SYS.UTL_DBWS.CALL;
    service_qname        SYS.UTL_DBWS.qname;
    port_qname           SYS.UTL_DBWS.qname;
    xoperation_qname     SYS.UTL_DBWS.qname;
    xstring_type_qname   SYS.UTL_DBWS.qname;
    response             SYS.XMLTYPE;
    request              SYS.XMLTYPE;
BEGIN
--sys.utl_dbws.set_http_proxy('www-proxy:8080');
    service_qname    := SYS.UTL_DBWS.to_qname(NULL, 'SMSWebService');
    service_         := SYS.UTL_DBWS.create_service(service_qname);
    call_            := SYS.UTL_DBWS.create_call(service_);
    SYS.UTL_DBWS.set_target_endpoint_address(call_,'http://ahmed/SMSWebService/Service.asmx');
    SYS.UTL_DBWS.set_property(call_, 'SOAPACTION_USE', 'TRUE');
    SYS.UTL_DBWS.set_property(call_,'SOAPACTION_URI','http://localhost/SMSWebService');
    SYS.UTL_DBWS.set_property(call_, 'OPERATION_STYLE', 'document');
    request          :=SYS.XMLTYPE('<SMSWebService xmlns="http://localhost/"> <msg>'||message||'</msg> <Category>Excuses-10</Category> </SMSWebService>');
    response := SYS.UTL_DBWS.invoke(call_, request);
RETURN response.EXTRACT('//SMSWebServiceResult/child::text()','xmlns="http://localhost/"').getstringval();
END;
