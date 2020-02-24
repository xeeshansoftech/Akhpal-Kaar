package ChequePrinting;

import java.awt.*;
import javax.swing.*;
import java.awt.print.*;
import javax.print.attribute.HashPrintRequestAttributeSet;
import javax.print.attribute.PrintRequestAttributeSet;
import javax.print.attribute.standard.OrientationRequested;

/**
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



public class PrintUtilities implements Printable {
    private Component componentToBePrinted;
    private static double chequeWidth, chequeHight, topMargin, bottomMargin,
            leftMargin, rightMargin;

    public static void printComponent(Component c) {
        new PrintUtilities(c).print();
    }

    public PrintUtilities(Component componentToBePrinted) {
        this.componentToBePrinted = componentToBePrinted;
    }

    public static void setParam(double Width, double Hight, double top,
                                double bottom, double left, double right) {
        chequeWidth = Width;
        chequeHight = Hight;
        topMargin = top;
        bottomMargin = bottom;
        leftMargin = left;
        rightMargin = right;
    }

    public void print() {
        PrinterJob printJob = PrinterJob.getPrinterJob();
        PrintRequestAttributeSet aset = new HashPrintRequestAttributeSet();
        PageFormat pf = printJob.defaultPage();
        Paper paper = new Paper();
        paper.setSize(chequeWidth, chequeHight);
        //System.out.println("Width n Height =" + chequeWidth + " " + chequeHight);
        /*  paper.setImageableArea(leftMargin, topMargin, chequeWidth - rightMargin,
                         chequeHight - bottomMargin);
             System.out.println ("Height"+paper.getImageableHeight()+ "Width"+ paper.getImageableWidth());*/
        pf.setPaper(paper);
        if (PrintCheque.Landscape_Portrait.equals("L")) {
            aset.add(OrientationRequested.LANDSCAPE);
//            System.out.println("Aset;;; ; LANDSCAPE " );
        } else {
            aset.add(OrientationRequested.PORTRAIT);
//            System.out.println("Aset;;; ; PORTRAIT " );
        }
        printJob.setPrintable(this, pf);
        boolean ok = printJob.printDialog(aset);
        //printJob.setPrintable(this);
        if (ok) {
            //if (printJob.printDialog())
            try {
                printJob.print(aset);
//                System.out.println("Aset;;; ; " );
            } catch (PrinterException pe) {
                System.out.println("Error printing: " + pe);
            }
        }
    }

    public int print(Graphics g, PageFormat pageFormat, int pageIndex) {
        if (pageIndex > 0) {
            return (NO_SUCH_PAGE);
        } else {
            Graphics2D g2d = (Graphics2D) g;
            g2d.translate(pageFormat.getImageableX(), pageFormat.getImageableY());
            disableDoubleBuffering(componentToBePrinted);
            componentToBePrinted.paint(g2d);
            enableDoubleBuffering(componentToBePrinted);
            return (PAGE_EXISTS);
        }
    }

    /** The speed and quality of printing suffers dramatically if
     *  any of the containers have double buffering turned on.
     *  So this turns if off globally.
     *  @see enableDoubleBuffering
     */
    public static void disableDoubleBuffering(Component c) {
        RepaintManager currentManager = RepaintManager.currentManager(c);
        currentManager.setDoubleBufferingEnabled(false);
    }

    /** Re-enables double buffering globally. */

    public static void enableDoubleBuffering(Component c) {
        RepaintManager currentManager = RepaintManager.currentManager(c);
        currentManager.setDoubleBufferingEnabled(true);
    }
}
