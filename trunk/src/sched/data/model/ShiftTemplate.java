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
 * Shift template has the desc, start time in minutes from 12:00AM, duration in minutes.
 *
 * @author Brian Spiegel
 */
public class ShiftTemplate implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final long NO_SHIFT = -1;
    public static final long ALL_SHIFTS = -2;

    @PrimaryKey
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY)
    private Key key;

    @Persistent
    private long storeId;

    @Persistent
    private String desc;

    @Persistent
    private String descLowerCase;

    @Persistent
    private int startTime;

    @Persistent
    private int duration;

    /**
     * Constructor.
     *
     */
    public ShiftTemplate(long aStoreId, int aStartTime, int aDuration, String aDesc)
    {
        storeId = aStoreId;
        startTime = aStartTime;
        duration = aDuration;

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

    public int getDuration()
    {
        return duration;
    }

    public Key getKey()
    {
        return key;
    }

    public int getStartTime()
    {
        return startTime;
    }

    public long getStoreId()
    {
        return storeId;
    }

    public void setDesc(String aDesc)
    {
        desc = aDesc;
        if (desc!=null)
        {
            descLowerCase = aDesc.toLowerCase();
        }
    }

    public void setDuration(int aDuration)
    {
        duration=aDuration;
    }

    public void setStartTime(int aStartTime)
    {
        startTime=aStartTime;
    }
}
