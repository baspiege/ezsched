package sched.data;

import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.ResourceBundle;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;

import sched.data.model.Role;
import sched.data.model.Store;
import sched.data.model.User;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Role utils.
 *
 * @author Brian Spiegel
 */
public class RoleUtils
{
    /**
     * Check if desc already exists.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aDesc desc
     * @param aRoleIdToSkip optional role Id to skip.  If none, use -1.
     *
     * @since 1.0
     */
    public static void checkIfDescExists(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, String aDesc, long aRoleIdToSkip)
    {
        Query query=null;
        try
        {
            query = aPm.newQuery(Role.class);
            query.setFilter("(storeId == storeIdParam) && (descLowerCase == descLowerCaseParam)");
            query.declareParameters("long storeIdParam, String descLowerCaseParam");
            query.setRange(0,2);  // Get 2 because current be there still.

            List<Role> results = (List<Role>) query.execute(aStoreId, aDesc.toLowerCase());

            for (Role role : results)
            {
                if (aRoleIdToSkip!=role.getKey().getId())
                {
                    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(aRequest));
                    String editMessage=bundle.getString("roleExistsEdit") + role.getDesc();
                    RequestUtils.addEdit(aRequest,editMessage);
                }
            }
        }
        catch (Exception e)
        {
            System.err.println(RoleUtils.class.getName() + ": " + e);
            e.printStackTrace();
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ERROR_PROCESSING_REQUEST);
        }
        finally
        {
            if (query!=null)
            {
                query.closeAll();
            }
        }
    }

    /**
     * Get the role for a store.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aRoleId role Id
     * @return a role or null if not found
     *
     * @since 1.0
     */
    public static Role getRoleFromStore(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, long aRoleId)
    {
        Role role=null;

        Query query=null;
        try
        {
            // Get role.
            // Do not use getObjectById as the Role Id could have been changed by the user.
            // Use a query to get by role Id and store Id to verify the role Id is in the
            // current store.
            query = aPm.newQuery(Role.class);
            query.setFilter("(storeId == storeIdParam) && (key == roleIdParam)");
            query.declareParameters("long storeIdParam, long roleIdParam");
            query.setRange(0,1);

            List<Role> results = (List<Role>) query.execute(aStoreId, aRoleId);

            if (!results.isEmpty())
            {
                role=(Role)results.get(0);
            }
        }
        finally
        {
            if (query!=null)
            {
                query.closeAll();
            }
        }

        return role;
    }

    /**
    * Is there a role that all users can updated?
    *
    * @param aRequest Servlet Request
    * @param aEditMessage edit message
    */
    public static boolean isRoleThatAllUsersCanUpdate(Map<Long,Role> aRoles)
    {
        boolean bRoleExists=false;

        if (aRoles!=null)
        {
            Iterator iter = aRoles.entrySet().iterator();
            while (iter.hasNext())
            {
                Entry entry = (Entry)iter.next();
                Role role=(Role)entry.getValue();

                if (role.getAllUserUpdateAccess())
                {
                    bRoleExists=true;
                    break;
                }
            }
        }

        return bRoleExists;
    }


    /**
     * Is the role valid?
     *
     * @param aRoles roles
     * @param aRoleId role Id
     * @return if shift is valid
     *
     * @since 1.0
     */
    public static boolean isValidRole(Map<Long,Role> aRoles, long aRoleId)
    {
        return (aRoles.containsKey(new Long(aRoleId)) || aRoleId==Role.NO_ROLE);
    }
}
