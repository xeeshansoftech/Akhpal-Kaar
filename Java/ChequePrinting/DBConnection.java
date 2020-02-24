package ChequePrinting;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.LinkedList;
import java.util.StringTokenizer;
import java.util.Vector;

/**
 * <p>
 * Title:
 * </p>
 * 
 * <p>
 * Description:
 * </p>
 * 
 * <p>
 * Copyright: Copyright (c) 2011
 * </p>
 * 
 * <p>
 * Company:
 * </p>
 * 
 * @author saima.Javeed
 * @version 1.0
 */
public class DBConnection {
    // Integer it;

    Statement st;
    Connection con;
    CallableStatement cs;
    String Lineone, Linetwo;
    String chq_format, format_name;
    Vector vc, vc2, vtemp, line, Pgst;
    ResultSet rs, rsf, rschar, rsline, stuppage;
    String URL, Line, QueryOne, chequename, words;
    PreparedStatement ps, dbps, dbpsf, dbchar, psline, pagestup;
    static Integer width, hight;
    static Integer x, y, w, h;
    double Rs;
    Vector tmp;
    Date dte;
    DateFormat fm;
    Integer char_per_line;
    Double RupeesNum;
    SimpleDateFormat formatter;
    String date, Pay, Wordingg, RupeesLineone, RupeesLinetwo, ForStatement, IdNum = "";

//	public static void main(String[] args) {
//		new DBConnection("192.168.0.2", "1521", "p5", "zafar", "zafar");
//	}
    public DBConnection() {
    }

    public DBConnection(String SID, String UserName, String Password) {

        String URL;
        try {
            // If the above connection gives exception then try connecting via SQL*Plus TNS Name...
            // For BMA Securities...
            URL = "jdbc:oracle:oci8:@" + SID;
//            System.out.println("OCI8: "+ URL + "," + UserName + ","+ Password);
            Class.forName("oracle.jdbc.driver.OracleDriver");
            con = DriverManager.getConnection(URL, UserName, Password);
        } catch (Exception e) {
            // First try connecting to database directly using server ip, host and port...  
            e.printStackTrace();
            System.out.println("Error while connecting through oci8. Now trying thin client ...");
        }
    }

    public DBConnection(String IP, String Port, String SID, String UserName, String Password) {

        String URL;
        try {
//            System.out.println("Error while connecting through oci8. Now trying thin client ...");
            URL = "jdbc:oracle:thin:@" + IP + ":" + Port + ":" + SID;
//            System.out.println("URL = " + URL + "," + UserName + "," + Password);
            Class.forName("oracle.jdbc.driver.OracleDriver");
            con = DriverManager.getConnection(URL, UserName, Password);
        } catch (Exception exc) {
            System.out.println("exception " + exc);
        }

    }

    public void getchequeDim(String report) {
        try {
            ps = con.prepareStatement("select ch.cheque_pixwidth,ch.cheque_pixhieght from cheque_cooridnates ch where ch.chequename= ?");
            ps.setString(1, report);
            rs = ps.executeQuery();
            while (rs.next()) {
                width = new Integer(rs.getString("cheque_pixwidth"));
                hight = new Integer(rs.getString("cheque_pixhieght"));
                // System.out.println(width.intValue()+" "+hight.intValue());
            }
        } catch (Exception e2) {
            System.out.println(e2);
        }
    }

    public Vector RupeesString(String words, int limit) {
        vc2 = new Vector();
        String temp;
        int newLimit = 0;
        StringTokenizer tk = new StringTokenizer(words, " ");
        int wordLength = tk.countTokens();
        if (wordLength <= limit) {
            vc2.add(0, words);
        } else if (wordLength > limit) {

            temp = tk.nextToken();
            for (int i = 1; i < limit; i++) {
                temp = temp + " " + tk.nextToken();
            }
            vc2.add(0, temp);
            temp = null;
            newLimit = wordLength - limit;
            temp = tk.nextToken();
            for (int j = 1; j < newLimit; j++) {
                temp = temp + " " + tk.nextToken();
            }
            vc2.add(1, temp);
        }
        return vc2;
    }

    /*
     * public Vector RupeesString(String str, int alp) { String token; vc2 = new
     * Vector(); StringTokenizer tk = new StringTokenizer(str, " "); token =
     * tk.nextToken(); for (int i = 2; i <= alp; i++) { if (tk.hasMoreTokens())
     * token = token + " " + tk.nextToken(); } if (str.substring(0,
     * token.length()).length() != 0) vc2.add(0, str.substring(0,
     * token.length())); if (str.length() > token.length()) vc2.add(1,
     * str.substring(0, token.length())); return vc2; }
     */
    public int get_charactersperline(String report) {
        int it = 0;
        try {
            String query = "select crp.RUPEESLINEWRAPCHAR from cheque_cooridnates crp where crp.chequename = ? ";
            dbchar = con.prepareStatement(query);
            dbchar.setString(1, report.trim());
            rschar = dbchar.executeQuery();
            if (rschar.next()) {
                it = new Integer(rschar.getInt("rupeeslinewrapchar"));
            }
        } catch (Exception e2) {
            e2.printStackTrace();
            System.out.println(e2 + "  From Date Exception");
        }
        return it;
    }

    public Cheque[] get_Cheque_objects(int CallID) {
        // vc = new Vector();
        LinkedList list = new LinkedList();
        int wrapper = 0;
        try {
            System.out.println("Call ID" + CallID);
            dbpsf = con.prepareStatement("select prt.gl_form_date,prt.cheque_description,prt.amount,prt.wordings,prt.forcheque,prt.chq_format,prt.format_name,prt.id_card_number from cheque_print prt where prt.call_id = " + CallID);
            
            // dbpsf =
            // con.prepareStatement("select prt.gl_form_date,prt.cheque_description,prt.amount,prt.wordings,prt.forcheque,prt.chq_format,prt.format_name from cheque_print prt");
            rsf = dbpsf.executeQuery();
            while (rsf.next()) {
                dte = rsf.getDate("gl_form_date");
                formatter = new SimpleDateFormat("dd-MM-yyyy");
                String dateString = formatter.format(dte);
                Pay = rsf.getString("cheque_description");
                RupeesNum = new Double(rsf.getDouble("amount"));
                Rs = RupeesNum.doubleValue();
                words = rsf.getString("wordings"); // Sets Line One and Line Two
                // at Cheques .....
                chq_format = rsf.getString("chq_format");
                if (chq_format == null) {
                    chq_format = "L";
//                    System.out.println("L");
                }
                PrintCheque.Landscape_Portrait = chq_format.toUpperCase();
                format_name = rsf.getString("format_name");
                if (format_name == null) {
                    format_name = "ABL WITHOUT DATE";
                }
                PrintCheque.chequename = format_name;
                // PrintCheque.chequename = "ABL WITHOUT DATE";
                char_per_line = get_charactersperline(PrintCheque.chequename);
//                System.out.println("Words " + words);
//                System.out.println("Chars Per Line " + char_per_line);
                tmp = RupeesString(words, char_per_line.intValue());
                // tmp =
                // RupeesString("FOUR MILLION TWO THOUSAND FIVE HUNDERERD FIFTY FIVE ONLY",
                // Chars.intValue());
                ForStatement = rsf.getString("forcheque");
                IdNum = rsf.getString("id_card_number");
                if (IdNum == null || IdNum == "")
                    IdNum="";
                int s = tmp.size();
                // System.out.println("TMP SIZE ="+s + "value"+ tmp.get(0) +
                // tmp.get(1) );
                if (s == 1) {
                    list.addLast(new Cheque(dateString, Pay, (String) tmp.elementAt(0), null, Rs, ForStatement, chq_format, format_name, IdNum));
                } else if (s > 1) {
                    list.addLast(new Cheque(dateString, Pay, (String) tmp.elementAt(0), (String) tmp.elementAt(1), Rs, ForStatement, chq_format, format_name, IdNum));
                    // vc.add(new Frame1(dateString, Pay, (String)
                    // tmp.elementAt(0),(String) tmp.elementAt(1), Rs,
                    // ForStatement,chq_format,format_name));
                }
            } // End of While loop.
            if (list.size() == 0) {
                return null;
            }
            Cheque data[] = new Cheque[list.size()];
            for (int x = 0; x < data.length; x++) {
                data[x] = (Cheque) list.removeFirst();
            }
            return data;

        } catch (Exception e2) {
            e2.printStackTrace();
            System.out.println(e2.getMessage() + " Exception from get_cheque_objects ....");
            return null;
        }

    }

    public PageSetUp[] PageSetUp(String report) {
        LinkedList list = new LinkedList();
        Double chequepagewidth, chequepagehight, chequepagetopmargin, chequepagebottommargin, chequepageleftmargin, chequepagerightmargin, forvisible, idvisible;
        try {
            pagestup = con.prepareStatement("select crd.chequepagewidth,crd.chequepagehight,crd.chequepagetopmargin,crd.chequepagebottommargin,crd.chequepageleftmargin,crd.chequepagerightmargin,crd.forvisible,crd.idvisible from cheque_cooridnates crd where crd.chequename = ? ");
            pagestup.setString(1, report);
            stuppage = pagestup.executeQuery();

            while (stuppage.next()) {

                chequepagewidth = new Double(stuppage.getString("chequepagewidth"));
                chequepagehight = new Double(stuppage.getString("chequepagehight"));
                chequepagetopmargin = new Double(stuppage.getString("chequepagetopmargin"));
                chequepagebottommargin = new Double(stuppage.getString("chequepagebottommargin"));
                chequepageleftmargin = new Double(stuppage.getString("chequepageleftmargin"));
                chequepagerightmargin = new Double(stuppage.getString("chequepagerightmargin"));
                try {
                    forvisible = new Double(stuppage.getString("forvisible"));
                } catch (Exception e) {
                    forvisible = 0.0;
                }
                try {
                    idvisible = new Double(stuppage.getString("idvisible"));
                } catch (Exception e) {
                    idvisible = 0.0;
                }

                list.addLast(new PageSetUp(chequepagewidth, chequepagehight, chequepagetopmargin, chequepagebottommargin, chequepageleftmargin, chequepagerightmargin, forvisible, idvisible));

            }
            if (list.size() == 0) {
                return null;
            }
            PageSetUp data[] = new PageSetUp[list.size()];
            for (int x = 0; x < data.length; x++) {
                data[x] = (PageSetUp) list.removeFirst();
            }
            return data;

        } catch (Exception e2) {
            e2.printStackTrace();
            System.out.println(e2 + " PageSetUp.... Method :");
            return null;
        }

    }

    public void getcontentsloc(String comp, String report) {
        if (comp == "dte") {
            try {
                ps = con.prepareStatement("select cor.datex,cor.datey,cor.datewidth,cor.datehight from cheque_cooridnates cor where cor.chequename = ? ");
                ps.setString(1, report);
                rs = ps.executeQuery();
                while (rs.next()) {
                    x = new Integer(rs.getString("datex"));
                    y = new Integer(rs.getString("datey"));
                    w = new Integer(rs.getString("datewidth"));
                    h = new Integer(rs.getString("datehight"));
                }
            } catch (Exception e2) {
                System.out.println(e2 + "  From Date Exception");
            }
        } else if (comp == "pay") {
            try {
                ps = con.prepareStatement("select cor.payx,cor.payy,cor.paywidth,cor.payhight from cheque_cooridnates cor where cor.chequename = ? ");
                ps.setString(1, report);
                rs = ps.executeQuery();
                while (rs.next()) {
                    x = new Integer(rs.getString("payx"));
                    y = new Integer(rs.getString("payy"));
                    w = new Integer(rs.getString("paywidth"));
                    h = new Integer(rs.getString("payhight"));
                }
            } catch (Exception e2) {
                System.out.println(e2 + "  From Pay Exception");
            }
        } else if (comp == "rupeesone") {
            try {
                ps = con.prepareStatement("select cor.rupeeslineonex,cor.rupeeslineoney,cor.rupeeslineonewidth,cor.rupeeslineonehight from cheque_cooridnates cor where cor.chequename = ? ");
                ps.setString(1, report);
                rs = ps.executeQuery();
                while (rs.next()) {
                    x = new Integer(rs.getString("rupeeslineonex"));
                    y = new Integer(rs.getString("rupeeslineoney"));
                    w = new Integer(rs.getString("rupeeslineonewidth"));
                    h = new Integer(rs.getString("rupeeslineonehight"));
                }
            } catch (Exception e2) {
                System.out.println(e2 + "  From Rupess Line One Exception");
            }
        } else if (comp == "rupeestwo") {
            try {
                ps = con.prepareStatement("select cor.rupeeslinetwox,cor.rupeeslinetwoy,cor.rupeeslinetwowidth,cor.rupeeslinetwohight from cheque_cooridnates cor where cor.chequename = ? ");
                ps.setString(1, report);
                rs = ps.executeQuery();
                while (rs.next()) {
                    x = new Integer(rs.getString("rupeeslinetwox"));
                    y = new Integer(rs.getString("rupeeslinetwoy"));
                    w = new Integer(rs.getString("rupeeslinetwowidth"));
                    h = new Integer(rs.getString("rupeeslinetwohight"));
                }
            } catch (Exception e2) {
                System.out.println(e2 + "  From Rupess Line Two Exception");
            }
        } else if (comp == "idCardNum") {
            try {
                ps = con.prepareStatement("select cor.idx,cor.idy,cor.idwidth,cor.idhight from cheque_cooridnates cor where cor.chequename = ? ");
                ps.setString(1, report);
                rs = ps.executeQuery();
                if (rs.next()) {
                    x = new Integer(rs.getString("idx"));
                    y = new Integer(rs.getString("idy"));
                    w = new Integer(rs.getString("idwidth"));
                    h = new Integer(rs.getString("idhight"));
                }
            } catch (Exception e2) {
                System.out.println(e2 + "  From id Card Number Exception");
            }

        } else if (comp == "rs") {
            try {
                ps = con.prepareStatement("select cor.rupeesnumx,cor.rupeesnumy,cor.rupeesnumwidth,cor.rupeesnumight from cheque_cooridnates cor where cor.chequename = ? ");
                ps.setString(1, report);
                rs = ps.executeQuery();
                while (rs.next()) {
                    x = new Integer(rs.getString("rupeesnumx"));
                    y = new Integer(rs.getString("rupeesnumy"));
                    w = new Integer(rs.getString("rupeesnumwidth"));
                    h = new Integer(rs.getString("rupeesnumight"));
                }
            } catch (Exception e2) {
                System.out.println(e2 + "For RupeesNum exception");
            }
        } else if (comp == "sign") {
            try {
                ps = con.prepareStatement("select cor.forx,cor.fory,cor.forwidth,cor.forhight from cheque_cooridnates cor where cor.chequename = ? ");
                ps.setString(1, report);
                rs = ps.executeQuery();
                while (rs.next()) {
                    x = new Integer(rs.getString("FORX"));
                    y = new Integer(rs.getString("FORY"));
                    w = new Integer(rs.getString("FORWIDTH"));
                    h = new Integer(rs.getString("FORHIGHT"));
                }
                // System.out.println(x.intValue()+" "+y.intValue()+" "+w.intValue()+" "+h.intValue());
            } catch (Exception e2) {
                System.out.println(e2 + " From Sign Exception");
            }
        }
    }

    public Vector set_line_cord(String report) {
        Integer linevisible, lineonexi, lineoneyi, lineonexf, lineoneyf, linetwoxi, linetwoyi, linetwoxf, linetwoyf, wordxi, wordyi;
        try {
            psline = con.prepareStatement("select payessvisible,payeeesaclinetopxi,payeeesaclinetopyi,payeeesaclinetopxf,payeeesaclinetopyf,payeeesaclinebotxi,payeeesaclinebotyi,payeeesaclinebotxf,payeeesaclinebotyf,payees_word_xpos,payees_word_ypos from cheque_cooridnates where chequename= ? ");
            psline.setString(1, report);
            rsline = psline.executeQuery();

            while (rsline.next()) {

                linevisible = new Integer(rsline.getString("payessvisible"));
                lineonexi = new Integer(rsline.getString("payeeesaclinetopxi"));
                lineoneyi = new Integer(rsline.getString("payeeesaclinetopyi"));
                lineonexf = new Integer(rsline.getString("payeeesaclinetopxf"));
                lineoneyf = new Integer(rsline.getString("payeeesaclinetopyf"));
                linetwoxi = new Integer(rsline.getString("payeeesaclinebotxi"));
                linetwoyi = new Integer(rsline.getString("payeeesaclinebotyi"));
                linetwoxf = new Integer(rsline.getString("payeeesaclinebotxf"));
                linetwoyf = new Integer(rsline.getString("payeeesaclinebotyf"));
                wordxi = new Integer(rsline.getString("payees_word_xpos"));
                wordyi = new Integer(rsline.getString("payees_word_ypos"));

                line = new Vector();
                line.add(new LineCordniates(linevisible, lineonexi, lineoneyi, lineonexf, lineoneyf, linetwoxi, linetwoyi, linetwoxf, linetwoyf, wordxi, wordyi));
                return line;
            }
        } catch (Exception e2) {
            System.out.println(e2 + " Set_Line_Cord.... Method :");
        }
        return line;
    }

    public class LineCordniates {

        int linevisible, lineonexi, lineoneyi, lineonexf, lineoneyf, linetwoxi, linetwoyi, linetwoxf, linetwoyf, wordxi, wordyi;

        public LineCordniates(Integer linevisible, Integer lineonexi, Integer lineoneyi, Integer lineonexf, Integer lineoneyf, Integer linetwoxi, Integer linetwoyi, Integer linetwoxf,
                Integer linetwoyf, Integer wordxi, Integer wordyi) {

            this.linevisible = linevisible.intValue();
            this.lineonexi = lineonexi.intValue();
            this.lineoneyi = lineoneyi.intValue();
            this.lineonexf = lineonexf.intValue();
            this.lineoneyf = lineoneyf.intValue();
            this.linetwoxi = linetwoxi.intValue();
            this.linetwoyi = linetwoyi.intValue();
            this.linetwoxf = linetwoxf.intValue();
            this.linetwoyf = linetwoyf.intValue();
            this.wordxi = wordxi.intValue();
            this.wordyi = wordyi.intValue();
        }
    }
}
