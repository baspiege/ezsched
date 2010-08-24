package sched.data;

import com.google.appengine.api.users.UserService;
import com.google.appengine.api.users.UserServiceFactory;

import java.security.Principal;
import javax.jdo.PersistenceManager;
import javax.servlet.http.HttpServletRequest;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.utils.DateUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Add a store.
 *
 * @author Brian Spiegel
 */
public class StoreAdd
{
    /**
     * Create, save, and select store.  Add this user to the store.
     *
     * @param aRequest The request
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest)
    {
        // Create new store
        String storeName=(String)aRequest.getAttribute("storeName");
        String timeZone=(String)aRequest.getAttribute("timeZone");

        // Check time zone
        if (!DateUtils.isTimeZoneValid(timeZone))
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.TIME_ZONE_NOT_VALID);
            return;
        }

        Store store=new Store(storeName,timeZone);

        PersistenceManager pm=null;
        try
        {
            // Get user info.
            // request.getUserPrincipal is not used because nickname is needed.
            com.google.appengine.api.users.User currentUser = UserServiceFactory.getUserService().getCurrentUser();

            // Save store
            pm=PMF.get().getPersistenceManager();
            pm.makePersistent(store);

            // Create user and save.
            long storeId=store.getKey().getId();
            User user=new User(storeId, currentUser.getNickname(), "");
            user.setEmailAddress(currentUser.getEmail());
            user.setDefaultRoleId(Role.NO_ROLE); // No roles will be available yet.
            user.setDefaultShiftTemplateId(ShiftTemplate.NO_SHIFT); // No shift templates will be available yet.
            user.setIsAdmin(true);
            pm.makePersistent(user);

            // Select store
            Store storeDetached=(Store)pm.detachCopy(store);
            RequestUtils.setCurrentStore(aRequest,storeDetached);
            SessionUtils.setCurrentStoreId(aRequest,new Long(storeDetached.getKey().getId()));

            // Save current user
            aRequest.setAttribute(RequestUtils.CURRENT_USER,pm.detachCopy(user));
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
