package sched.data;

import java.util.Map;
import javax.jdo.PersistenceManager;
import javax.servlet.http.HttpServletRequest;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;
import sched.utils.ValidationUtils;

/**
 * Delete a user shift of a store.
 *
 * @author Brian Spiegel
 */
public class UserShiftDelete
{
    /**
     * Delete a user shift.
	 *
     * @param aRequest The request
     * @param aRoles roles
     * @param aShiftTemaplates shift templates
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates,Map<Long,User> aUsers)
    {
        // Get store Id
        Store currentStore=RequestUtils.getCurrentStore(aRequest);
        if (currentStore==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_STORE_NOT_SET);
            return;
        }
        long storeId=currentStore.getKey().getId();

        // Get current user
        User currentUser=RequestUtils.getCurrentUser(aRequest);
        if (currentUser==null)
        {
            // Should be caught by SessionUtils.isLoggedOn, but just in case.
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_USER_NOT_FOUND);
            return;
        }

        // Get user shift Id.
        Long userShiftId=(Long)aRequest.getAttribute("userShiftId");

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

			// Get user shift
			UserShift userShift=UserShiftUtils.getUserShiftFromStore(aRequest,pm,storeId,userShiftId,aRoles,aShiftTemplates,aUsers);
			if (userShift==null)
			{
				RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_SHIFT_NOT_FOUND_FOR_STORE);
				return;
			}

			// Check if user has access to the user shift.
			ValidationUtils.checkUpdateAccessToUserShift(aRequest, currentUser, userShift, aRoles);
			if (RequestUtils.hasEdits(aRequest))
			{
				return;
			}

            // Delete user shift.
            pm.deletePersistent(userShift);
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
