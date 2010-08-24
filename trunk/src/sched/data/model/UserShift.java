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
 * User shift has the start date, duration, shift template Id, and role Id.
 * Duration is in minutes.
 * 
 * @author Brian Spiegel
 */
public class UserShift implements Serializable {

    private static final long serialVersionUID = 1L;
 
    @PrimaryKey 
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY) 
    private Key key;
 
    @Persistent 
    private int duration; 

    @Persistent 
    private String note; 

    @Persistent 
    private long roleId;

    @Persistent 
    private long shiftTemplateId; 

    @Persistent 
    private long storeId;
 
    @Persistent 
    private Date startDate;

    @Persistent 
    private long userId;
    
    @Persistent 
    private long lastUpdateUserId;
    
    @Persistent 
    private Date lastUpdateTime;	
 
    /**
     * Constructor.
     * 
     */ 
    public UserShift(long aStoreId, long aUserId, Date aStartDate, int aDuration, long aLastUpdateUserId, Date aLastUpdateTime)
    { 
        storeId = aStoreId;
        userId = aUserId;
        startDate = aStartDate; 
        duration = aDuration; 
        lastUpdateUserId=aLastUpdateUserId;
        lastUpdateTime=aLastUpdateTime;
    } 
 
    // Accessors for the fields.  JDO doesn't use these, but the application does. 
 
    public int getDuration()
    { 
        return duration; 
    }

    public Key getKey()
    { 
        return key; 
    }

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

    public long getRoleId()
    { 
        return roleId; 
    }

    public long getShiftTemplateId()
    { 
        return shiftTemplateId; 
    }
 
    public Date getStartDate()
    { 
        return startDate; 
    }

    public long getStoreId()
    { 
        return storeId; 
    }

    public long getUserId()
    { 
        return userId; 
    }
    
    public void setDuration(int aDuration)
    { 
        duration=aDuration; 
    }	

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

    public void setRoleId(long aRoleId)
    { 
        roleId=aRoleId; 
    }

    public void setShiftTemplateId(long aShiftTemplateId)
    { 
        shiftTemplateId=aShiftTemplateId; 
    }
    
    public void setStartDate(Date aStartDate)
    { 
        startDate=aStartDate; 
    }
    
    public void setUserId(long aUserId)
    { 
        userId=aUserId; 
    }
}