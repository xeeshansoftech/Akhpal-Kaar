import javax.mail.*;
import javax.mail.internet.*;
import javax.activation.DataSource;
import javax.activation.DataHandler;
import javax.activation.FileDataSource;
import java.util.Properties;
import java.util.Date;
import java.io.*;
import java.util.StringTokenizer;
import java.util.Properties;
import java.util.Enumeration;

public class SendMail
{
    /*
         0  smtp server
         1  smtp port
         2  userId
         3  password
         4  senderAddress
         5  client Info ( To|ClientCode|ClientName|Address|cc;cc;cc;cc... )
         6  subject
         7  message
         8  Attachment
         9  FileName
         10 SSL (0 for false, 1 for true)
     */
  public static void main (String arg[])
  {
    if (arg.length < 9)
    {
      //writeToFile(arg[9], " Exception In Send Mail. Wrong Number of Aurguments Passed. ");
      writeToFile(arg[9], "NOT SENT|Exception In Send Mail. Wrong Number of Aurguments Passed.|*");
      System.err.println("Exception In Send Mail. Wrong Number of Aurguments Passed. ");
      System.exit(0);
    }

    final String smtpServer = arg[0].trim();
    final String smtpPort   = arg[1].trim();
    final String userId     = arg[2].trim();
    final String password   = arg[3].trim();

    final String from       = arg[4].trim();

    String[] clientInfo    = null;
    String   to            = "";
    String   clientCode    = "";
    String   clientName    = "";
    String   clientAddress = "";
    String   cc            = "";
    String[] ccArray       = null;

    try
    {
      clientInfo = arg[5].split("\\|");
      if(clientInfo.length < 5)
      {
        //writeToFile(arg[9], " Exception In Send Mail. Invalid Client Info. ");
        writeToFile(arg[9], "NOT SENT|Exception In Send Mail. Invalid Client Info.|*");
        System.err.println("Exception In Send Mail. Invalid Client Info. ");
        System.exit(0);
      }
      to            = clientInfo[0].trim();
      clientCode    = clientInfo[1].trim();
      clientName    = clientInfo[2].trim();
      clientAddress = clientInfo[3].trim();
      cc            = clientInfo[4].trim();

      if(!cc.toUpperCase().equals("NIL"))
      {
      	ccArray = cc.split(";");
      	System.err.println("Lenght of CC Array: " + ccArray.length);
      }
    }
    catch (Exception e)
    {
      e.printStackTrace();
      writeToFile(arg[9], "NOT SENT|" + e.getMessage() + "|*");
      //writeToFile(arg[9], e.getMessage());
      //writeToFile(arg[9], captureStackTrace(e));
    }

    try
    {
      System.err.println("Sending Email To: " + to + " Client Code: " + clientCode + " Client Name: " + clientName + " Client Address: " + clientAddress + "  Client CC: " + cc);
      writeToFile(arg[9], "SENDING|" + clientCode +"|Sending Mail To:" + to + ";" + clientCode + ";" + clientName + ";" + clientAddress + ";" + cc + "|*");
      Properties props = System.getProperties();
      props.put("mail.smtp.host", smtpServer);
      props.put("mail.smtp.port", smtpPort);
      props.put("mail.smtp.auth", "true");

			try
			{
      	//Should be used when Using SSL Connection
      	if(arg[10].trim().equals("1"))
      	{
        	System.err.println("SSL Enabled!");
        	props.put("mail.smtp.socketFactory.port", smtpPort);
        	props.put("mail.smtp.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
        	props.put("mail.smtp.starttls.enable", "true");
      	}
    	}
    	catch(Exception ex)
    	{
    		System.err.println("Exception while setting SSL Paramters. " + ex.getMessage());
    	}

      Transport transport;
      Multipart multipart      = null;
      DataSource source        = null;
      BodyPart bodyAttachment  = null;
      BodyPart bodyMessage     = null;

      Session session = Session.getInstance(props, new Authenticator()
      {
        public PasswordAuthentication getPasswordAuthentication()
        {
          return new PasswordAuthentication(userId, password);
        }
      });
      transport = session.getTransport("smtp");
      transport.connect();

      MimeMessage message = new MimeMessage(session);

      message.setFrom( new InternetAddress(from));

      message.addRecipient(javax.mail.Message.RecipientType.TO, new InternetAddress(to));

      if (!cc.toUpperCase().equals("NIL"))
      {
      	for(int i=0; i<ccArray.length; i++)
      	{
        	message.addRecipient(javax.mail.Message.RecipientType.CC, new InternetAddress(ccArray[i]));
      	}
      }

      /*if (!bcc.toUpperCase().equals("NIL"))
      {
        message.addRecipient(javax.mail.Message.RecipientType.BCC, new InternetAddress(bcc));
      }*/

			message.setSentDate(new java.util.Date());
			
      message.setSubject(arg[6]);
      message.setHeader("Content-Type", "multipart/mixed");
      //message.setHeader("Content-Transfer Encoding", "BASE64");

      message.addHeader("Return-Receipt-To", from);
      message.addHeader("Delivery-Notification-To", from);
      message.addHeader("X-Mailer", "JavaMail API");

      multipart = new MimeMultipart();

      bodyMessage = new MimeBodyPart();

      //bodyMessage.setContent(readMessageContents(arg[7]), "text/html");

      bodyMessage.setContent(arg[7], "text/html");
      multipart.addBodyPart(bodyMessage);

      if (!arg[8].toUpperCase().equals("NIL"))
      {
        bodyAttachment = new MimeBodyPart();
        source = new FileDataSource(arg[8]);
        bodyAttachment.setDataHandler(new DataHandler(source));
        bodyAttachment.setHeader("Content-Transfer Encoding", "BASE64");
        bodyAttachment.setHeader("Content-Type", "application/octet-stream");
        bodyAttachment.setFileName(showName(arg[8]));
        multipart.addBodyPart(bodyAttachment);
      }
      message.setContent(multipart);
      transport.send(message);
      //Transport.send(message);
      transport.close();
      //writeToFile(arg[9], " Sent-" + clientCode);
      writeToFile(arg[9], "SENT|" + clientCode + "|Mail Sent Successfully to: " + clientCode + "|*");
      System.err.println("Sent-" + clientCode);
    }
    catch (Exception e)
    {
      e.printStackTrace();
      writeToFile(arg[9], "NOT SENT|" + e.getMessage() + "|*");
      //writeToFile(arg[9], e.getMessage());
    }
  }

  public static String readMessageContents(String fileName)
  {
    try
    {
      File paymentFile  = new File(fileName);
      byte[] byteArray = new byte[(int) paymentFile.length()];
      FileInputStream inputStream = new FileInputStream(paymentFile);
      for (int i=0; i<byteArray.length; i++)
      {
        inputStream.read(byteArray, i, 1);
      }
      inputStream.close();
      return (new String(byteArray));
    }
    catch (Exception e)
    {
      return "";
    }
  }

  /**
   * Write the value in the file
   *
   * This method creates a new file and write the passed
   * value in that file.
   *
   * @param filename The name of the file to be created.
   * @param value The text to be written in the file.
   */
  public static void writeToFile(String filename, String value)
  {
    FileWriter file = null;
    try
    {
      file = new FileWriter(filename, true);
      String str = "MSG|" + new Date().toString() + "|" + value + "\r\n";
      file.write(str, 0, str.length());
      file.flush();
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
    finally
    {
      try
      {
        file.close();
      }
      catch (Exception e)
      {
        e.printStackTrace();
      }
    }
  }


  public static String showName(String str)
  {
	String[] tokenArray = null;
	//System.getProperty( "file.separator");
	StringTokenizer st = new StringTokenizer(str, System.getProperty( "file.separator"));
	int tokenCount = st.countTokens();
	tokenArray = new String[tokenCount];
	for (int i=0; i<tokenCount; i++)
	{
	    tokenArray[i] = st.nextToken();
	}
	return tokenArray[tokenArray.length-1];
   }

  public static String captureStackTrace(Throwable exception)
  {
    StringBuffer stackTrace = new StringBuffer();
    stackTrace.append("Exception in thread \"");
    stackTrace.append(Thread.currentThread());
    stackTrace.append("\" ");
    stackTrace.append(exception);
    //stackTrace.append(exception.getMessage());
    stackTrace.append("\n");

    StackTraceElement elements[] = exception.getStackTrace();
    for (int x = 0; x < elements.length; x++)
    {
      stackTrace.append(elements[x].toString());
      stackTrace.append("\n");
    }
    return stackTrace.toString();
  }
}
