package ChequePrinting;
//aa
/**
 * <p>Title: </p>
 *
 * <p>Description: </p>
 *
 * <p>Copyright: Copyright (c) 2011</p>
 *
 * <p>Company: </p>
 *
 * @author saima.Javeed
 * @version 1.0
 */
public class Cheque {

    protected String date;
    protected String pay;
    protected String RupeesLineone;
    protected String RupeesLinetwo;
    protected double RupeesNum;
    protected String ForStatement;
    protected String chq_format;
    protected String format_name;
    protected String idCardNumber;


    public Cheque(String date, String Pay, String RupeesLineone,
                  String RupeesLinetwo, double RupeesNum, String ForStatement,
                  String chq_format, String format_name,String idCardNumber) {
        setDate(date);
        setPay(Pay);
        setRupeesLineone(RupeesLineone);
        setRupeesLinetwo(RupeesLinetwo);
        setRupeesNum(RupeesNum);
        setForStatement(ForStatement);
        setChqFormat(chq_format);
        setFormatName(format_name);
        setIdCardNum(idCardNumber);
    }
    public void setFormatName(String format_name) {
        this.format_name = format_name;
    }

    public String getFormatName() {
        return format_name;
    }

    public void setIdCardNum(String idCardNumber) {
        this.idCardNumber = idCardNumber;
    }

    public String getIdCardNum() {
        return idCardNumber;
    }
    public void setChqFormat(String chq_format) {
        this.chq_format = chq_format;
    }

    public String getchqFormat() {
        return chq_format;
    }

    public void setForStatement(String ForStatement) {
        this.ForStatement = ForStatement;
    }

    public String getForStatement() {
        return ForStatement;
    }

    public void setRupeesNum(double RupeesNum) {
        this.RupeesNum = RupeesNum;
    }

    public double getRupeesNum() {
        return RupeesNum;
    }

    public void setRupeesLinetwo(String RupeesLinetwo) {
        this.RupeesLinetwo = RupeesLinetwo;
    }

    public String getRupeesLinetwo() {
        return RupeesLinetwo;
    }


    public void setRupeesLineone(String RupeesLineone) {
        this.RupeesLineone = RupeesLineone;
    }

    public String getRupeesLineone() {
        return RupeesLineone;
    }

    public void setPay(String pay) {
        this.pay = pay;
    }

    public String getPay() {
        return pay;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getDate() {
        return date;
    }


}
