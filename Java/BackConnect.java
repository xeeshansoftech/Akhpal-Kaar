import java.net.*; 
import java.io.*; 
import java.rmi.*;
import com.server.rmiserver.*;
import com.server.utils.*;

/**
* This is a support class for the Back Connect Application
* Any thing that cannot be done from the Oracle Forms will be coded here.
* 
* The forms application will simply call this class to perform the required 
* operation, the name and parameters of the methods are passed using command
* line paramenters, the method creates a new file on this disk with the name
* passed to it as a first paramter (i.e. methods own name) and writes the return 
* value into it.
*/
public class BackConnect
{
    /**
    * To call the getIPAddress method, pass IP_ADDRESS as an aurgument.
    */
    static final String IP_ADDRESS = "IP_ADDRESS";
    
    /**
    * To validate the product license, pass LICENSED as an aurgument.
    */
    static final String LICENSED = "LICENSED";
    
    /**
    * To get the connection string of the backconnect database
    */
    static final String CONNECTION = "CONNECTION";
    
    /**
    * Name of the file, create the RESULT file to store the results
    */
    static String RESULT = "RESULT";
    
    /**
    * The properties file of the Back Connect Application,
    * for future use only.
    */
    static String filename = "BackConnect.ini";
    
    /**
    * The RMI Security Server class name - verifies the license key
    */    
    private static final String RMI_SECURITY_SERVER="rmiserver.SecurityServer";
    
    /**
    * RMI INFO Server file name - Sends the connection string
    */
    //private static final String RMI_INFO_SERVER = "rmiserver.SystemInfoServer";
    
    /**
    * RMI Host machine name
    */
    private static String sHostName="";

    /**
    * Instance of security remote interface, verifies license key
    */
    private static com.server.rmiserver.Security objSecurity;
    
    /**
    * Instance of info server remote interface, returns connection string
    */
    private static com.server.rmiserver.SystemInfo objSystemInfo;

    /**
    * The main method of the class.
    * 
    * This is the only method that is called from
    * any External application, and the first aurgument would be
    * the method to be executed.
    */
    public static void main(String[] args)
    { 
        BackConnect bc = new BackConnect();
        
        if (args.length < 3)
        {
            System.out.println("To few arguments passed.");
            System.exit(0);
        }
        else
        {
            filename = args[0];
            RESULT   = args[1];
        }
        
        /*
        * look up the security server
        */
        sHostName = ConfigReader.readParameter(filename, "HOST_NAME=");
        //System.setProperty("java.rmi.server.hostname", sHostName);
        System.out.println(sHostName);
        try
        {
            objSecurity = (com.server.rmiserver.Security)
                            LookupRemoteObject(RMI_SECURITY_SERVER);
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
            writeToFile(RESULT,  "Unable to connect to "+sHostName+" server.");
        }

        /*
        * service the requests
        */
        if (args[2].equals(IP_ADDRESS))
        {
            writeToFile(RESULT, getIPAddress());
        }
        else if (args[2].equals(LICENSED))
        {
            writeToFile(RESULT, bc.VerifyProductLicense(args[3]));
        }
        else if (args[2].equals(CONNECTION))
        {
            writeToFile(RESULT, bc.getConnectionString());
        }
        else
        {
            writeToFile(RESULT, "Invalid Option");
        }
    } 
  
    
    /**
    * Verify the Product license
    */
    public static String VerifyProductLicense(String sKey)
    {
        try
        {
            if (objSecurity.verifyproductLicense(sKey) == true)
            {
                return "true";
            }
            else
            {
                return "false";
            }
        }
        catch(RemoteException ex)
        {
            return ex.toString();
        }
    }


    /**
    *
    */
    public static String getConnectionString()
    {
        try
        {
            String connStr = objSecurity.getConnectionString();
            return connStr;
        }
        catch (RemoteException ex)
        {
            ex.printStackTrace();
            return "\n" + ex.toString();
        }
    }
    
    /**
    * RMI Loopup Object
    */
	private static Remote LookupRemoteObject(String sObject)throws Exception
	{
        Remote remoteObject = null;
        String serverObjectName = "//" + sHostName + "/" + sObject;
        remoteObject = Naming.lookup(serverObjectName);
        return remoteObject;	
	}


    /**
    * Get the machine ip address.
    *
    * This methods returns the local machine name and its IP in
    * the form <machine_name>/<IP_address> e.g. rehan/132.147.150.2
    * 
    * @return HOST/IP
    */
    public static String getIPAddress()
    {
        try
        { 
            return (InetAddress.getLocalHost().toString());
        }
        catch (java.net.UnknownHostException e)
        { 
            return "Unknown"; 
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
        //System.out.println("Writing " + value + " in file " + filename);
        FileWriter file = null;
        try
        {
            file = new FileWriter(filename);
            String str = value + "\r\n";
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

    
    /**
    *
    */
    public static String getKeyValue(String key, String value)
    {
        return (key + '=' + value);
    }

    
} 

