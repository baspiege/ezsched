package sched.utils;

import com.google.appengine.api.memcache.MemcacheService;
import com.google.appengine.api.memcache.MemcacheServiceFactory;

import java.util.Map;
import javax.servlet.http.HttpServletRequest;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.data.model.UserShiftRequestSwitch;

/**
 * Mem cache utilities.
 *
 * @author Brian Spiegel
 */
public class MemCacheUtils
{
    public static String ROLES="roles";
    public static String SHIFT_TEMPLATES="shiftTemplates";
    public static String STORE="store";
    public static String USERS="users";
    public static String USER_SHIFT_REQUEST_SWITCH="userShiftRequestSwitchs";

    /**
    * Get the current store Id as String.
    *
    * @param aRequest Servlet Request
    * @return the current Store Id as a String
    */
    public static String getCurrentStoreIdAsString(HttpServletRequest aRequest)
    {
         // Get store Id
        Store currentStore=RequestUtils.getCurrentStore(aRequest);
        if (currentStore==null)
        {
            return null;
        }
        return new Long(currentStore.getKey().getId()).toString();
    }

    /**
    * Get the roles from cache.
    *
    * @param aRequest Servlet Request
    */
    public static Map<Long,Role> getRoles(HttpServletRequest aRequest)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);

        // Try cache.
        Map<Long,Role> roles=null;
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            roles=(Map<Long,Role>)memcache.get(storeId + ROLES);
        }

        return roles;
    }

    /**
    * Get the shift templates from cache.
    *
    * @param aRequest Servlet Request
    */
    public static Map<Long,ShiftTemplate> getShiftTemplates(HttpServletRequest aRequest)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);

        // Try cache.
        Map<Long,ShiftTemplate> shiftTemplates=null;
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            shiftTemplates=(Map<Long,ShiftTemplate>)memcache.get(storeId + SHIFT_TEMPLATES);
        }

        return shiftTemplates;
    }

    /**
    * Get the store from cache.
    *
    * @param aRequest Servlet Request
    */
    public static Store getStore(HttpServletRequest aRequest)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);

        // Try cache.
        Store store=null;
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            store=(Store)memcache.get(storeId + STORE);
        }

        return store;
    }

    /**
    * Get the users from cache.
    *
    * @param aRequest Servlet Request
    */
    public static Map<Long,User> getUsers(HttpServletRequest aRequest)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);

        // Try cache.
        Map<Long,User> users=null;
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            users=(Map<Long,User>)memcache.get(storeId + USERS);
        }

        return users;
    }

    /**
    * Get the user shift switch requests from cache.
    *
    * @param aRequest Servlet Request
    */
    /**
    public static Map<Long,UserShiftRequestSwitch> getUserShiftRequestSwitchs(HttpServletRequest aRequest)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);

        // Try cache.
        Map<Long,UserShiftRequestSwitch> userShiftRequestSwitchs=null;
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            userShiftRequestSwitchs=(Map<Long,UserShiftRequestSwitch>)memcache.get(storeId + USER_SHIFT_REQUEST_SWITCH);
        }

        return userShiftRequestSwitchs;
    }
    */

    /**
    * Set the roles into cache.
    *
    * @param aRequest Servlet Request
    * @param aRole Roles
    */
    public static void setRoles(HttpServletRequest aRequest, Map<Long,Role> aRoles)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            memcache.put(storeId + ROLES, aRoles);
        }
    }

    /**
    * Set the shift templates into cache.
    *
    * @param aRequest Servlet Request
    * @param aShiftTemplates Shift templates
    */
    public static void setShiftTemplates(HttpServletRequest aRequest, Map<Long,ShiftTemplate> aShiftTemplates)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            memcache.put(storeId + SHIFT_TEMPLATES, aShiftTemplates);
        }
    }

    /**
    * Set the store into cache.
    *
    * @param aRequest Servlet Request
    * @param aStore store
    */
    public static void setStore(HttpServletRequest aRequest, Store aStore)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            memcache.put(storeId + STORE, aStore);
        }
    }

    /**
    * Set the users into cache.
    *
    * @param aRequest Servlet Request
    * @param aUsers Users
    */
    public static void setUsers(HttpServletRequest aRequest, Map<Long,User> aUsers)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            memcache.put(storeId + USERS, aUsers);
        }
    }

    /**
    * Set the user shift switch requests into cache.
    *
    * @param aRequest Servlet Request
    * @param aUserShiftRequestSwitch UserShiftRequestSwitch
    */
    /**
    public static void setUserShiftRequestSwitchs(HttpServletRequest aRequest, Map<Long,UserShiftRequestSwitch> aUserShiftRequestSwitchs)
    {
        String storeId=getCurrentStoreIdAsString(aRequest);
        if (storeId!=null)
        {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            memcache.put(storeId + USER_SHIFT_REQUEST_SWITCH, aUserShiftRequestSwitchs);
        }
    }
    */
}
