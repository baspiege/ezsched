package sched.data.model;

import com.google.appengine.api.datastore.Key; 

import java.io.Serializable;

import javax.jdo.annotations.IdGeneratorStrategy; 
import javax.jdo.annotations.IdentityType; 
import javax.jdo.annotations.PersistenceCapable; 
import javax.jdo.annotations.Persistent; 
import javax.jdo.annotations.PrimaryKey; 
 
@PersistenceCapable(identityType = IdentityType.APPLICATION, detachable="true")

/**
 * Role which has description. For sorting, Strings have lower case versions.
 * 
 * @author Brian Spiegel
 */
public class Role implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final long NO_ROLE = -1;
    public static final long ALL_ROLES = -2;

    @PrimaryKey 
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY) 
    private Key key;
 
    @Persistent 
    private String desc; 

    @Persistent 
    private String descLowerCase; 

    @Persistent 
    private long storeId;

    @Persistent 
    private boolean allUserUpdateAccess=false;
  
    /**
     * Constructor.
     * 
     */ 
    public Role(long aStoreId, String aDesc)
    { 
        storeId = aStoreId;

        desc = aDesc;
        if (desc!=null)
        {
            descLowerCase = aDesc.toLowerCase();
        }
    } 
 
    // Accessors for the fields.  JDO doesn't use these, but the application does. 
 
    public String getDesc()
    { 
        return desc; 
    }

    public Key getKey()
    { 
        return key; 
    }

    public long getStoreId()
    { 
        return storeId; 
    }

    public boolean getAllUserUpdateAccess()
    { 
        return allUserUpdateAccess; 
    }

    public void setDesc(String aDesc)
    { 
        desc = aDesc;
        if (desc!=null)
        {
            descLowerCase = aDesc.toLowerCase();
        }
    }

    public void setAllUserUpdateAccess(boolean aAllUserUpdateAccess)
    { 
        allUserUpdateAccess=aAllUserUpdateAccess; 
    }
}