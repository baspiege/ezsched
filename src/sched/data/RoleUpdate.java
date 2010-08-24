package sched.data;

import java.util.List;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.Role;
import sched.data.model.Store;
import sched.data.model.User;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.MemCacheUtils;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Update a role in a store.
 *
 * Check that the desc is not already being used.
 *
 * @author Brian Spiegel
 */
public class RoleUpdate
{
    /**
     * Update a role.
     *
     * @param aRequest The request
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest)
    {
        // Get store Id
        Store currentStore=RequestUtils.getCurrentStore(aRequest);
        if (currentStore==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_STORE_NOT_SET);
            return;
        }
        long storeId=currentStore.getKey().getId();

        // Check if admin
        User currentUser=RequestUtils.getCurrentUser(aRequest);
        if (currentUser==null)
        {
            // Should be caught by SessionUtils.isLoggedOn, but just in case.
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_USER_NOT_FOUND);
            return;
        }
        else if (!currentUser.getIsAdmin())
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ADMIN_ACCESS_REQUIRED);
            return;
        }

        long roleId=((Long)aRequest.getAttribute("roleId")).longValue();

        // Get fields
        String desc=(String)aRequest.getAttribute("desc");
        boolean allUserUpdateAccess=((Boolean)aRequest.getAttribute("allUserUpdateAccess")).booleanValue();

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Get role.
            Role role=RoleUtils.getRoleFromStore(aRequest,pm,storeId,roleId);
            if (role==null)
            {
                RequestUtils.addEditUsingKey(aRequest,EditMessages.ROLE_NOT_FOUND_FOR_STORE);
                return;
            }

            // Check if desc exists
            if (!RequestUtils.hasEdits(aRequest))
            {
                RoleUtils.checkIfDescExists(aRequest, pm, storeId, desc, roleId);
            }

            if (!RequestUtils.hasEdits(aRequest))
            {
                // Updae role.
                role.setDesc(desc);
                role.setAllUserUpdateAccess(allUserUpdateAccess);

                // Clear request and cache.
                RequestUtils.setRoles(aRequest,null);
                MemCacheUtils.setRoles(aRequest,null);
            }
        }
        catch (Exception e)
        {
            System.err.println(this.getClass().getName() + ": " + e);
            e.printStackTrace();
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ERROR_PROCESSING_REQUEST);
        }
        finally
        {
            if (pm!=null)
            {
                pm.close();
            }
        }
    }
}
