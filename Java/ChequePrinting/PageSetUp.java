package ChequePrinting;

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

public class PageSetUp {
	double chequepagewidth, chequepagehight, chequepagetopmargin, chequepagebottommargin, chequepageleftmargin, chequepagerightmargin, forvisible, idVisible;

	public PageSetUp(Double chequepagewidth, Double chequepagehight, Double chequepagetopmargin, Double chequepagebottommargin, Double chequepageleftmargin, Double chequepagerightmargin, Double forvisible, Double idVisible) {

		setChequePageWidth(chequepagewidth.doubleValue());
		setChequePageHight(chequepagehight.doubleValue());
		setChequePageTopMargin(chequepagetopmargin.doubleValue());
		setChequePageBottomMargin(chequepagebottommargin.doubleValue());
		setChequePageLeftMargin(chequepageleftmargin.doubleValue());
		setChequePageRightMargin(chequepagerightmargin.doubleValue());
		setForVisible(forvisible.doubleValue());
		setIDVisible(idVisible.doubleValue());
	}

	public void setChequePageWidth(double chequepagewidth) {
		this.chequepagewidth = chequepagewidth;
	}

	public double getChequePageWidth() {
		return chequepagewidth;
	}

	public void setChequePageHight(double chequepagehight) {
		this.chequepagehight = chequepagehight;
	}

	public double getChequePageHight() {
		return chequepagehight;
	}

	public void setChequePageTopMargin(double chequepagetopmargin) {
		this.chequepagetopmargin = chequepagetopmargin;
	}

	public double getChequePageTopMargin() {
		return chequepagetopmargin;
	}

	public void setChequePageBottomMargin(double chequepagebottommargin) {
		this.chequepagebottommargin = chequepagebottommargin;
	}

	public double getChequePageBottomMargin() {
		return chequepagebottommargin;
	}

	public void setChequePageLeftMargin(double chequepageleftmargin) {
		this.chequepageleftmargin = chequepageleftmargin;
	}

	public double getChequePageLeftMargin() {
		return chequepageleftmargin;
	}

	public void setChequePageRightMargin(double chequepagerightmargin) {
		this.chequepagerightmargin = chequepagerightmargin;
	}

	public double getChequePageRightMargin() {
		return chequepagerightmargin;
	}

	public void setForVisible(double forvisible) {
		this.forvisible = forvisible;
	}

	public double getForVisible() {
		return forvisible;
	}

	public void setIDVisible(double idVisible) {
		this.idVisible = idVisible;
	}

	public double getIDVisible() {
		return idVisible;
	}

}
