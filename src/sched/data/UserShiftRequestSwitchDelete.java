package sched.data;

import java.util.Date;
import java.util.List;
import java.util.Map;
import javax.jdo.PersistenceManager;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.data.model.UserShiftRequestSwitch;
import sched.utils.DateUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;
import sched.utils.ValidationUtils;

/**
 * Delete a user shift switch request to a store.
 *
 * @author Brian Spiegel
 */
public class UserShiftRequestSwitchDelete
{
    /**
     * Delete a user shift switch request.
	 *
     * @param aRequest The request
     * @param aRoles roles
     * @param aShiftTemaplates shift templates
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates,Map<Long,User> aUsers, Map<Long,UserShift> aUserShifts)
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

		Long switchId=(Long)aRequest.getAttribute("userShiftRequestSwitchId");

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Get switch
            UserShiftRequestSwitch userShiftRequestSwitch=UserShiftRequestSwitchUtils.getUserShiftRequestSwitchFromStore(aRequest, pm, storeId, switchId);
            if (userShiftRequestSwitch==null)
            {
                return;
            }

            /* TODO Delete..
            UserShift userShiftEditing1=null;
            UserShift userShiftEditing2=null;

            // Get shift 1
            if (userShiftRequestSwitch.getUserShiftId1()!=0)
            {
                userShiftEditing1=UserShiftUtils.getUserShift(aRequest,pm,storeId,userShiftRequestSwitch.getUserShiftId1(),aUserShifts,aRoles,aShiftTemplates,aUsers);
            }

            // Get shift 2
            if (userShiftRequestSwitch.getUserShiftId2()!=0)
            {
                userShiftEditing2=UserShiftUtils.getUserShift(aRequest,pm,storeId,userShiftRequestSwitch.getUserShiftId2(),aUserShifts,aRoles,aShiftTemplates,aUsers);
            }
            */

            if (RequestUtils.hasEdits(aRequest))
            {
                return;
            }

            // Delete switch request.
            pm.deletePersistent(userShiftRequestSwitch);
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
