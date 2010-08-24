package sched.data;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.utils.DateUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Get a single user shift.
 *
 * @author Brian Spiegel
 */
public class UserShiftGetSingle
{
    /**
     * Get a single user shift.
     *
     * @param aRequest The request
     * @param aRoles roles
     * @param aShiftTemaplates shift templates
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates, Map<Long,User> aUsers)
    {
        // Get store Id
        Store currentStore=RequestUtils.getCurrentStore(aRequest);
        if (currentStore==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_STORE_NOT_SET);
            return;
        }
        long storeId=currentStore.getKey().getId();

        // Use Shift Id
        long userShiftId=((Long)aRequest.getAttribute("userShiftId")).longValue();

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            UserShift userShift=UserShiftUtils.getUserShiftFromStore(aRequest,pm,storeId,userShiftId,aRoles,aShiftTemplates,aUsers);
            if (userShift==null)
            {
                RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_SHIFT_NOT_FOUND_FOR_STORE);
                return;
            }

			// For now, pass user back in "userShiftUtils_user" entry.
			User user=(User)aRequest.getAttribute("userShiftUtils_user");
			if (user!=null)
			{
			     aRequest.setAttribute("user", pm.detachCopy(user));
			}
			// Shouldn't happen, but just in case.
			else
			{
				userShift=null;
			}

            aRequest.setAttribute("userShift", pm.detachCopy(userShift));
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
