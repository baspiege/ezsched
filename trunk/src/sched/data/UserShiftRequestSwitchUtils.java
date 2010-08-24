package sched.data;

import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;

import sched.data.model.Store;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.data.model.UserShiftRequestSwitch;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;

/**
 * UserShiftRequestSwitch utils.
 *
 * @author Brian Spiegel
 */
public class UserShiftRequestSwitchUtils
{

    /**
     * Get the UserShiftRequestSwitch for a store.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aUserShiftRequestSwitchId userShiftRequestSwitch Id
     * @return a UserShiftRequestSwitch or null if not found
     *
     * @since 1.0
     */
    public static UserShiftRequestSwitch getUserShiftRequestSwitchFromStore(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, long aUserShiftRequestSwitchId)
    {
        UserShiftRequestSwitch userShiftRequestSwitch=null;

        Query query=null;
        try
        {
            // Get userShiftRequestSwitch.
            // Do not use getObjectById as the UserShiftRequestSwitch Id could have been changed by the user.
            // Use a query to get by userShiftRequestSwitch Id and store Id to verify the userShiftRequestSwitch Id is in the
            // current store.
            query = aPm.newQuery(UserShiftRequestSwitch.class); 
            query.setFilter("(storeId == storeIdParam) && (key == userShiftRequestSwitchIdParam)"); 
            query.declareParameters("long storeIdParam, long userShiftRequestSwitchIdParam");
            query.setRange(0,1);

            List<UserShiftRequestSwitch> results = (List<UserShiftRequestSwitch>) query.execute(aStoreId, aUserShiftRequestSwitchId); 

            if (!results.isEmpty())
            {
                userShiftRequestSwitch=(UserShiftRequestSwitch)results.get(0);
            }
        }
        finally
        {
            if (query!=null)
            {   
                query.closeAll(); 
            }
        }

        return userShiftRequestSwitch;
    }

    /**
     * Check that a user has update access to a user shift.
     *
     * @param aRequest The request
     * @param aUser User	 
     * @param aUserShift User shift
     * @return if user has access to the shift
     *
     * @since 1.0
     */
    public static boolean checkUpdateAccessToUserShift(HttpServletRequest aRequest, User aUser, UserShift aUserShift)
    {
        boolean hasAccess=false;
    
        if (aUserShift==null)
        {
            hasAccess=false;
        }
        // If admin, has access.
        else if (aUser.getIsAdmin())
        {
            hasAccess=true;
        }
        // Only admins can change user shifts of others.
        else if (aUser.getKey().getId()==aUserShift.getUserId())
        {
            hasAccess=true;			
        }
        
        if (!hasAccess)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_DOES_NOT_HAVE_ACCESS_TO_UPDATE_SHIFT);
        }
        
        return hasAccess;
    }	

    /**
     * Update user shift from switch requests.  If aApprovalOnly is true, then only remove approval.
     * Else, remove the user shift.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aUserShiftRequestSwitchMap user shift switch requests     
     * @param aUserShiftId User shift Id
     * @param aApprovalOnly Indicates to only remove approval.  If false, user shift is removed.
     *
     * @since 1.0
     */
    public static void updateUserShiftInSwitchRequests(HttpServletRequest aRequest, PersistenceManager aPm, Map<Long,UserShiftRequestSwitch> aUserShiftRequestSwitchMap, long aUserShiftId, boolean aApprovalOnly)
    {
        if (aUserShiftRequestSwitchMap!=null && !aUserShiftRequestSwitchMap.isEmpty())
        {
            // For each switch request
            Iterator iter = aUserShiftRequestSwitchMap.entrySet().iterator();
            while (iter.hasNext())
            {
                Entry entry = (Entry)iter.next();
                UserShiftRequestSwitch userShiftRequestSwitch=(UserShiftRequestSwitch)entry.getValue();
            
                // Check if 1 or 2 matches
                if (userShiftRequestSwitch.getUserShiftId1()==aUserShiftId
                 || userShiftRequestSwitch.getUserShiftId2()==aUserShiftId)
                {
                    // Get switch request (the ones in the map are detached from the data store)
                    // It's ok to use getObjectById because it's already been checked for the 
                    // store when put into the map.
                    UserShiftRequestSwitch userShiftRequestSwitchModifiable=(UserShiftRequestSwitch)aPm.getObjectById(UserShiftRequestSwitch.class,userShiftRequestSwitch.getKey().getId());
                    
                    // Check shift 1
                    if (userShiftRequestSwitchModifiable.getUserShiftId1()==aUserShiftId)
                    {
                        if (aApprovalOnly)
                        {
                            userShiftRequestSwitchModifiable.setUserStatus1(UserShiftRequestSwitch.NOT_APPROVED);
                        }
                        else
                        {
                            userShiftRequestSwitchModifiable.setUserShiftId1(-1);
                        }
                    }
                    
                    // Check shift 2
                    if (userShiftRequestSwitchModifiable.getUserShiftId2()==aUserShiftId)
                    {
                        if (aApprovalOnly)
                        {
                            userShiftRequestSwitchModifiable.setUserStatus2(UserShiftRequestSwitch.NOT_APPROVED);
                        }
                        else
                        {
                            userShiftRequestSwitchModifiable.setUserShiftId2(-1);
                        }
                    }                    
                }
            }
        }
    }
}
