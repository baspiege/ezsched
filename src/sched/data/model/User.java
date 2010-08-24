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
 * User which has name, email address, and admin indicator.  For sorting,
 * Strings have lower case versions.
 * 
 * @author Brian Spiegel
 */
public class User implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final long ALL_USERS = -2;
 
    @PrimaryKey 
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY) 
    private Key key;

    @Persistent 
    private long storeId;
 
    @Persistent 
    private String firstName; 

    @Persistent 
    private String firstNameLowerCase; 
 
    @Persistent 
    private String lastName; 

    @Persistent 
    private String lastNameLowerCase; 

    @Persistent 
    private String emailAddress; 

    @Persistent 
    private String emailAddressLowerCase; 

    @Persistent 
    private boolean isAdmin=false; 

    @Persistent 
    private long defaultRoleId;
    
    @Persistent 
    private long defaultShiftTemplateId;	
 
    /**
     * Constructor.
     * 
     */ 
    public User(long aStoreId, String aFirstName, String aLastName)
    { 
        storeId = aStoreId;

        firstName = aFirstName;
        if (firstName!=null)
        {
            firstNameLowerCase = aFirstName.toLowerCase();
        }

        lastName = aLastName; 
        if (lastName!=null)
        {
            lastNameLowerCase = aLastName.toLowerCase(); 
        }
    } 
 
    // Accessors for the fields.  JDO doesn't use these, but the application does. 

    public long getDefaultRoleId()
    { 
        return defaultRoleId; 
    }
    
    public long getDefaultShiftTemplateId()
    { 
        return defaultShiftTemplateId; 
    }	

    public String getEmailAddress()
    { 
        return emailAddress; 
    }
 
    public String getFirstName()
    { 
        return firstName; 
    }

    public boolean getIsAdmin()
    { 
        return isAdmin; 
    }

    public Key getKey()
    { 
        return key; 
    }

    public String getLastName()
    { 
        return lastName; 
    }

    public long getStoreId()
    { 
        return storeId; 
    }

    public void setDefaultRoleId(long aDefaultRoleId)
    { 
        defaultRoleId=aDefaultRoleId; 
    }
    
    public void setDefaultShiftTemplateId(long aDefaultShiftTemplateId)
    { 
        defaultShiftTemplateId=aDefaultShiftTemplateId; 
    }	

    public void setEmailAddress(String aEmailAddress)
    { 
        emailAddress=aEmailAddress; 

        if (emailAddress!=null)
        {
            emailAddressLowerCase=aEmailAddress.toLowerCase();
        }
    }

    public void setFirstName(String aFirstName)
    { 
        firstName = aFirstName;
        if (firstName!=null)
        {
            firstNameLowerCase = aFirstName.toLowerCase();
        }
    }

    public void setIsAdmin(boolean aIsAdmin)
    { 
        isAdmin=aIsAdmin; 
    }

    public void setLastName(String aLastName)
    { 
        lastName = aLastName;
        if (lastName!=null)
        {
            lastNameLowerCase = aLastName.toLowerCase();
        }
    }

}