package sched.data.model;

import com.google.appengine.api.datastore.Key; 

import java.io.Serializable;  
import java.util.Date;

import javax.jdo.annotations.IdGeneratorStrategy; 
import javax.jdo.annotations.IdentityType; 
import javax.jdo.annotations.PersistenceCapable; 
import javax.jdo.annotations.Persistent; 
import javax.jdo.annotations.PrimaryKey; 
 
@PersistenceCapable(identityType = IdentityType.APPLICATION, detachable="true")

/**
 * User shift request to switch.
 * 
 * @author Brian Spiegel
 */
public class UserShiftRequestSwitch implements Serializable {

    private static final long serialVersionUID = 1L;
    
    public static final int NOT_APPROVED = 1;        
    public static final int APPROVED = 2;        
        
    public static final int STARTED = 1;         
    public static final int PROCESSED = 2;
     
    @PrimaryKey 
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY) 
    private Key key;
 
    // TODO - Remove if not needed
     //@Persistent 
    //private long lastUpdateUserId;

    // TODO - Remove if not needed
    //@Persistent 
    //private Date lastUpdateTime;
    
    // TODO - Remove if not needed
    //@Persistent 
    //private String note; 
    
    @Persistent 
    private int status;  

    @Persistent
    private long storeId;    

    /*
    @Persistent
    private long userId1;
    
    @Persistent
    private long userId2;   
    */

    @Persistent
    private long userShiftId1;
    
    @Persistent 
    private long userShiftId2;    
    
    @Persistent 
    private int userStatus1;
    
    @Persistent 
    private int userStatus2;
    
    /**
     * Constructor.
     * 
     */ 
    public UserShiftRequestSwitch(long aStoreId, long aLastUpdateUserId, Date aLastUpdateTime, int aStatus)
    { 
        storeId = aStoreId;
        //lastUpdateUserId=aLastUpdateUserId;
        //lastUpdateTime=aLastUpdateTime;
        status=aStatus;
    }
 
    // Accessors for the fields.  JDO doesn't use these, but the application does. 
 
    public Key getKey()
    { 
        return key; 
    }

    /*
    public long getLastUpdateUserId()
    { 
        return lastUpdateUserId; 
    }	
    
    public Date getLastUpdateTime()
    { 
        return lastUpdateTime; 
    }	

    public String getNote()
    { 
        return note; 
    }
    */
    
    public int getStatus()
    { 
        return status; 
    }    

    public long getStoreId()
    { 
        return storeId; 
    }
    
    public long getUserShiftId1()
    { 
        return userShiftId1; 
    }    
    
    public long getUserShiftId2()
    { 
        return userShiftId2; 
    }        
    
    public int getUserStatus1()
    { 
        return userStatus1; 
    }    
    
    public int getUserStatus2()
    { 
        return userStatus2; 
    }    
    
    /*
    public void setLastUpdateUserId(long aUserId)
    { 
        lastUpdateUserId=aUserId; 
    }	
    
    public void setLastUpdateTime(Date aDate)
    { 
        lastUpdateTime=aDate; 
    }	
    
    public void setNote(String aNote)
    { 
        note=aNote; 
    }
    */
    
    public void setStatus(int aStatus)
    { 
        status=aStatus; 
    }    
    
    public void setUserShiftId1(long aUserShiftId1)
    { 
        userShiftId1=aUserShiftId1; 
    }	    
    
    public void setUserShiftId2(long aUserShiftId2)
    { 
        userShiftId2=aUserShiftId2; 
    }	       

    public void setUserStatus1(int aStatus1)
    { 
        userStatus1=aStatus1; 
    }        
    
    public void setUserStatus2(int aStatus2)
    { 
        userStatus2=aStatus2; 
    }        
}