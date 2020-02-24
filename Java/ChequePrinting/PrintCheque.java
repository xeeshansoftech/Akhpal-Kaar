package ChequePrinting;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Insets;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Enumeration;
import java.util.Vector;

import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.UIManager;

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
public class PrintCheque extends JFrame {

	Cheque Fr;
	PageSetUp Ob;
	Graphics g;

	DBConnection db;

	PrintUtilities prnt;
	JPanel main = new JPanel(null);
	// JPanel main,main2;
	// DBConnection.PageSetUp Ob;
	JTextArea dte, pay, rs, sign;
	JTextField rupees, rupees2, idNum;
	static String chequename;
	static String Landscape_Portrait;
	Font font = new Font("Times New Roman", Font.PLAIN, 11);

	public PrintCheque() {
	}

	public PrintCheque(String IP, String Port, String SID, String Username, String Password, int CallID) {

	try {	
                db = new DBConnection(SID, Username, Password);
                jbInit();
	} catch(UnsatisfiedLinkError err)
        {
            try {
                System.out.print("**Exception in DB Connection** " + err);
                err.printStackTrace();
//                    ex.printStackTrace();
                    db = new DBConnection(IP, Port, SID, Username, Password);
                     
                    jbInit();
            } catch (Exception ex1) {
                Logger.getLogger(PrintCheque.class.getName()).log(Level.SEVERE, null, ex1);
            }
        }
        catch (Exception ex) {
            
            }
	}

	private void jbInit() throws Exception {
		this.getContentPane().setLayout(null);
		this.getContentPane().setBackground(Color.white);
	}

	public void Cheque_Loc() {

		db.getchequeDim(chequename);
		main.setLayout(null);
		main.setBackground(Color.white);
		this.setPreferredSize(new Dimension(DBConnection.width.intValue() + 275, DBConnection.hight.intValue() + 150));

		main.setVisible(true);
		main.validate();

		// addComponent(this,main,
		// 0,0,DBConnection.width.intValue()+100,DBConnection.hight.intValue()+50);
		this.setBounds(0, 0, DBConnection.width.intValue(), DBConnection.hight.intValue());
		main.setBounds(0, 0, DBConnection.width.intValue() + 275, DBConnection.hight.intValue() + 150);
		// main.add(new LinePanel());
		this.add(main);
		this.setLocation(50, 50);
		this.setVisible(true);
		this.pack();
		this.validate();

	}

	public void Add_Cheque_Contents_Loc() {

		dte = new JTextArea();
		pay = new JTextArea();
		rupees = new JTextField();
		rupees2 = new JTextField();
		idNum = new JTextField();
		rs = new JTextArea();
		sign = new JTextArea();

		db.getcontentsloc("dte", chequename);
		dte.setVisible(true);
		dte.setEditable(false);
		dte.setFont(font);
		dte.setBounds(DBConnection.x.intValue(), DBConnection.y.intValue(), DBConnection.w.intValue(), DBConnection.h.intValue());
		main.add(dte);

		db.getcontentsloc("pay", chequename);
		pay.setVisible(true);
		pay.setLineWrap(false);
		pay.setEditable(false);
		pay.setFont(new Font("Times New Roman", Font.PLAIN, 11));
		pay.setBounds(DBConnection.x.intValue(), DBConnection.y.intValue(), DBConnection.w.intValue(), DBConnection.h.intValue());
		main.add(pay);

		db.getcontentsloc("rupeesone", chequename);
		rupees.setVisible(true);
		rupees.setBackground(Color.white);
		rupees.setBorder(new javax.swing.border.EmptyBorder(0, 0, 0, 0));
		rupees.setFont(font);
		rupees.setMargin(new Insets(0, 0, 0, 0));
		rupees.setEditable(false);
		rupees.setBounds(DBConnection.x.intValue(), DBConnection.y.intValue(), DBConnection.w.intValue(), DBConnection.h.intValue());
		main.add(rupees);

		db.getcontentsloc("rupeestwo", chequename);
		rupees2.setVisible(true);
		rupees2.setBackground(Color.white);
		rupees2.setBorder(new javax.swing.border.EmptyBorder(0, 0, 0, 0));
		rupees2.setFont(font);
		rupees2.setMargin(new Insets(0, 0, 0, 0));
		rupees2.setEditable(false);
		rupees2.setBounds(DBConnection.x.intValue(), DBConnection.y.intValue(), DBConnection.w.intValue(), DBConnection.h.intValue());
		main.add(rupees2);

		db.getcontentsloc("idCardNum", chequename);
		idNum.setVisible(true);
		idNum.setBackground(Color.white);
		idNum.setBorder(new javax.swing.border.EmptyBorder(0, 0, 0, 0));
		idNum.setFont(font);
		idNum.setMargin(new Insets(0, 0, 0, 0));
		idNum.setEditable(false);
		idNum.setBounds(DBConnection.x.intValue(), DBConnection.y.intValue(), DBConnection.w.intValue(), DBConnection.h.intValue());
		main.add(idNum);

		db.getcontentsloc("rs", chequename);
		rs.setVisible(true);
		rs.setEditable(false);
		rs.setFont(font);
		rs.setBounds(DBConnection.x.intValue(), DBConnection.y.intValue(), DBConnection.w.intValue(), DBConnection.h.intValue());
		main.add(rs);

		db.getcontentsloc("sign", chequename);
		sign.setVisible(true);
		sign.setEditable(false);
		sign.setLineWrap(false);
		sign.setFont(font);
		sign.setBounds(DBConnection.x.intValue(), DBConnection.y.intValue(), DBConnection.w.intValue(), DBConnection.h.intValue());
		main.add(sign);
		this.validate();

	}

	public void print(int CallID) {

		System.out.println("In Print===" + CallID);
		Vector tmp;
		Cheque[] Chq_Obj = db.get_Cheque_objects(CallID);
		if (Chq_Obj != null) {
			System.out.println("Result = " + Chq_Obj.length);
			for (int i = 0; i < Chq_Obj.length; i++) {
				chequename = Chq_Obj[i].getFormatName();
				Landscape_Portrait = Chq_Obj[i].getchqFormat();

//				System.out.println("Name " + chequename + " format " + Landscape_Portrait);
				main = new DrawLine();

				Cheque_Loc();

				Add_Cheque_Contents_Loc();

				dte.setText(null);
				pay.setText(null);
				rupees.setText(null);
				rupees2.setText(null);
				idNum.setText(null);
				sign.setText(null);
				rs.setText(null);

				dte.setText(Chq_Obj[i].getDate());
				pay.setText(Chq_Obj[i].getPay());
				rupees.setText(Chq_Obj[i].getRupeesLineone());
				rupees2.setText(Chq_Obj[i].getRupeesLinetwo());
				NumberFormat formatter = new DecimalFormat("###,###,###,###.00");
				rs.setText("=" + formatter.format(Chq_Obj[i].getRupeesNum()));

				PageSetUp[] Ob = db.PageSetUp(chequename);
				if (Ob != null) {
					for (int j = 0; j < Ob.length; j++) {
						if (Ob[j].getForVisible() != 0) {
							sign.setText((String) Chq_Obj[i].getForStatement());
						}
						String CNIC = (String) Chq_Obj[i].getIdCardNum();
						if (CNIC != null) {
							idNum.setText("CNIC:" + CNIC);
						}
						PrintUtilities.setParam(Ob[j].getChequePageWidth(), Ob[j].getChequePageHight(), Ob[j].getChequePageTopMargin(), Ob[j].getChequePageBottomMargin(),
								Ob[j].getChequePageLeftMargin(), Ob[j].getChequePageRightMargin());
					}
				} else {
					System.out.println("Page (Cheque) returns null");
				}
				main.setBackground(Color.WHITE);
				this.repaint();
				PrintUtilities.printComponent(this);
				this.repaint();
				this.remove(main);

			}
		}
	}

	class DrawLine extends JPanel {
		Vector temp;
		DBConnection.LineCordniates Obj;
		int linevisible, lineonexi, lineoneyi, lineonexf, lineoneyf, linetwoxi, linetwoyi, linetwoxf, linetwoyf, wordxi, wordyi;

		public DrawLine() {
			temp = db.set_line_cord(chequename);
			for (Enumeration e = temp.elements(); e.hasMoreElements();) {
				Obj = (DBConnection.LineCordniates) e.nextElement();
			}
			this.linevisible = Obj.linevisible;
			this.lineonexi = Obj.lineonexi;
			this.lineoneyi = Obj.lineoneyi;
			this.lineonexf = Obj.lineonexf;
			this.lineoneyf = Obj.lineoneyf;
			this.linetwoxi = Obj.linetwoxi;
			this.linetwoyi = Obj.linetwoyi;
			this.linetwoxf = Obj.linetwoxf;
			this.linetwoyf = Obj.linetwoyf;
			this.wordxi = Obj.wordxi;
			this.wordyi = Obj.wordyi;
		}

		protected void paintComponent(Graphics g) {

			String s;
			Graphics2D g2d = (Graphics2D) g;
			if (this.linevisible != 0) {
				g2d.drawLine(lineonexi, lineoneyi, lineonexf, lineoneyf);

				// g2d.drawString("A/C Payees Only", wordxi, wordyi);
				// g2d.rotate(Math.toRadians(315));
				g2d.drawLine(linetwoxi, linetwoyi, linetwoxf, linetwoyf);
			}

		}
	}

	public static void main(String[] args) {
		int l = args.length;
		String[] params = { "DB Host : ", "DB Port : ", "SID : ", "DB User : ", "DB Password : ", "Call_ID : "};
//		System.out.println("parameter length " + l);

		if (l == 6) {

//			System.err.println("parameters passed are " + l);
//			for (int i = 0; i < l; i++) {
//				System.err.println(params[i] + args[i]);
//			}
			UIManager.put("swing.boldMetal", Boolean.FALSE);

			PrintCheque tst = new PrintCheque(args[0], args[1], args[2], args[3], args[4], Integer.parseInt(args[5]));

			tst.addWindowListener(new WindowAdapter() {
				public void windowClosing(WindowEvent e) {
					System.exit(0);
				}
			});
			tst.setBackground(Color.white);
			tst.setVisible(true);
                        tst.print(Integer.parseInt(args[5]));
		}
		/*
		 * else { System.err.println(" No parameters Found"); PrintCheque tst =
		 * new PrintCheque("192.168.0.2","1521", "p5","zafar", "zafar");
		 * tst.addWindowListener( new WindowAdapter() { public void
		 * windowClosing(WindowEvent e) { System.exit(0); } } );
		 * tst.setBackground(Color.white); tst.setVisible(false); tst.print();
		 * 
		 * }
		 */
	}
}
