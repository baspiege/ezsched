package sched.data;

import java.util.ArrayList;
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
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Get user shifts for a single user.
 *
 * @author Brian Spiegel
 */
public class UserShiftGetAllForSingleUser
{
    /**
     * Get user shifts.
     *
     * @param aRequest The request
     * @param aRoles roles
     * @param aShiftTemaplates shift templates
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates)
    {
        // Get store Id
        Store currentStore=RequestUtils.getCurrentStore(aRequest);
        if (currentStore==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_STORE_NOT_SET);
            return;
        }
        long storeId=currentStore.getKey().getId();

        // Get user Id
        long userId=((Long)aRequest.getAttribute("userId")).longValue();

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Get user.
            User user=UserUtils.getUserFromStore(aRequest,pm,storeId,userId);
            if (user==null)
            {
                RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_NOT_FOUND_FOR_STORE);
                return;
            }

            // Get user shifts
            Query query=null;
            try
            {
                // Get user shifts.
                query = pm.newQuery(UserShift.class);
                query.setFilter("(storeId == storeIdParam) && (userId == userIdParam)");
                query.declareParameters("long storeIdParam, long userIdParam");
                query.setOrdering("startDate ASC");

                List<UserShift> results = (List<UserShift>) query.execute(storeId, userId);

                // Transfer collection to new list
                List<UserShift> copyUserShifts=new ArrayList<UserShift>();
                for (UserShift userShift: results)
                {
                    long roleId=userShift.getRoleId();
                    long shiftTemplateId=userShift.getShiftTemplateId();

                    // Check that role and shift template exists
                    if (RoleUtils.isValidRole(aRoles,userShift.getRoleId())
                    && ShiftTemplateUtils.isValidShiftTemplate(aShiftTemplates,userShift.getShiftTemplateId()))
                    {
                        copyUserShifts.add(pm.detachCopy(userShift));
                    }
                }

                // Set into request
                aRequest.setAttribute("userShifts", copyUserShifts);
            }
            finally
            {
                if (query!=null)
                {
                    query.closeAll();
                }
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
