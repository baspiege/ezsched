package sched.data;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.data.model.UserShiftRequestSwitch;
import sched.data.model.Store;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Get all UserShiftRequestSwitchs for a store.
 *
 * @author Brian Spiegel
 */
public class UserShiftRequestSwitchGetAll
{
    /**
     * Get all UserShiftRequestSwitchs.
     *
     * @param aRequest The request
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

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            Query query=null;

            try
            {
                // Get all UserShiftRequestSwitchs
                query = pm.newQuery(UserShiftRequestSwitch.class);
                query.setFilter("storeId == storeIdParam");
                query.declareParameters("long storeIdParam");

                // TODO - Order by time?
                //query.setOrdering("descLowerCase ASC");

                List<UserShiftRequestSwitch> results = (List<UserShiftRequestSwitch>) query.execute(storeId);

                Map<Long,UserShift> userShifts=new LinkedHashMap<Long,UserShift>();
                Map<Long,UserShiftRequestSwitch> userShiftRequestSwitchMap=new LinkedHashMap<Long,UserShiftRequestSwitch>();

                for (UserShiftRequestSwitch userShiftRequestSwitch : results)
                {
                    UserShift userShift1=null;
                    UserShift userShift2=null;

                    if (userShiftRequestSwitch.getUserShiftId1()!=0)
                    {
                        userShift1=UserShiftUtils.getUserShift(aRequest,pm,storeId,userShiftRequestSwitch.getUserShiftId1(),userShifts,aRoles,aShiftTemplates,aUsers);
                    }

                    if (userShiftRequestSwitch.getUserShiftId2()!=0)
                    {
                        userShift2=UserShiftUtils.getUserShift(aRequest,pm,storeId,userShiftRequestSwitch.getUserShiftId2(),userShifts,aRoles,aShiftTemplates,aUsers);
                    }

                    if (userShift1!=null || userShift2!=null)
                    {
                        userShiftRequestSwitchMap.put(new Long(userShiftRequestSwitch.getKey().getId()),pm.detachCopy(userShiftRequestSwitch));
                    }
                    else
                    {
                        // Delete the user shift request.
                        pm.deletePersistent(userShiftRequestSwitch);
                    }
                }
                aRequest.setAttribute("userShiftRequestSwitchs", userShiftRequestSwitchMap);
                aRequest.setAttribute("userShifts", userShifts);
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
