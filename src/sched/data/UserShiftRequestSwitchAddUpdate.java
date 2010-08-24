package sched.data;

import java.util.Date;
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
import sched.data.model.UserShiftRequestSwitch;
import sched.utils.DateUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;
import sched.utils.ValidationUtils;

/**
 * Add or update a user shift switch request to a store.
 *
 * @author Brian Spiegel
 */
public class UserShiftRequestSwitchAddUpdate
{

    public static final int ADD_NEW = 1;
    public static final int ADD_EXISTING = 2;
    public static final int USER1_APPROVES = 3;
    public static final int USER2_APPROVES = 4;
    public static final int USER1_NOT_APPROVES = 5;
    public static final int USER2_NOT_APPROVES = 6;
    public static final int REMOVE_USER_SHIFT1 = 7;
    public static final int REMOVE_USER_SHIFT2 = 8;

    /**
     * Add or update a user shift switch request.
     *
     * @param aRequest The request
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates, Map<Long,User> aUsers,  Map<Long,UserShift> aUserShifts)
    {
        // Get store Id
        Store currentStore=RequestUtils.getCurrentStore(aRequest);
        if (currentStore==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_STORE_NOT_SET);
            return;
        }
        long storeId=currentStore.getKey().getId();

        User currentUser=RequestUtils.getCurrentUser(aRequest);
        if (currentUser==null)
        {
            // Should be caught by SessionUtils.isLoggedOn, but just in case.
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_USER_NOT_FOUND);
            return;
        }

        // Action type
        Integer actionTypeInteger=(Integer)aRequest.getAttribute("actionType");
        int actionType=-1;
        if (actionTypeInteger!=null)
        {
            actionType=actionTypeInteger.intValue();
        }

        Long userShiftId=(Long)aRequest.getAttribute("userShiftId");

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Adding new
            if (actionType==ADD_NEW)
            {
                UserShift userShiftBeingUpdated=UserShiftUtils.getUserShift(aRequest,pm,storeId,userShiftId,aUserShifts,aRoles,aShiftTemplates,aUsers);

                if (!UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftBeingUpdated))
                {
                    return;
                }

                if (!RequestUtils.hasEdits(aRequest))
                {
                    // Create switch request.
                    UserShiftRequestSwitch userShiftRequestSwitch=new UserShiftRequestSwitch(storeId, currentUser.getKey().getId(), new Date(), UserShiftRequestSwitch.STARTED);

                    if (userShiftId!=null && userShiftId.longValue()!=0)
                    {
                        userShiftRequestSwitch.setUserShiftId1(userShiftId);
                    }

                    // Save shift template.
                    pm.makePersistent(userShiftRequestSwitch);
                }
            }
            else
            {
                Long switchId=(Long)aRequest.getAttribute("userShiftRequestSwitchId");

                if (switchId==null || switchId.longValue()==0)
                {
                    return;
                }

                // Get switch
                UserShiftRequestSwitch userShiftRequestSwitch=UserShiftRequestSwitchUtils.getUserShiftRequestSwitchFromStore(aRequest, pm, storeId, switchId);
                if (userShiftRequestSwitch==null)
                {
                    return;
                }

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

                if (actionType==ADD_EXISTING)
                {
                    UserShift userShiftBeingUpdated=UserShiftUtils.getUserShift(aRequest,pm,storeId,userShiftId,aUserShifts,aRoles,aShiftTemplates,aUsers);

                    if (!UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftBeingUpdated))
                    {
                        return;
                    }

                    boolean added=false;

                    // Try 1
                    if (userShiftRequestSwitch.getUserShiftId1()==0 || userShiftEditing1==null)
                    {
                        userShiftRequestSwitch.setUserShiftId1(userShiftId);
                        added=true;

                        if (userShiftEditing1!=null && userShiftEditing1!=null)
                        {
                            userShiftRequestSwitch.setUserStatus1(UserShiftRequestSwitch.APPROVED);

                            // Set other user to not approved
                            userShiftRequestSwitch.setUserStatus2(UserShiftRequestSwitch.NOT_APPROVED);
                        }
                    }

                    // Try 2
                    if (!added)
                    {
                        if (!added && (userShiftRequestSwitch.getUserShiftId2()==0 || userShiftEditing2==null))
                        {
                            userShiftRequestSwitch.setUserShiftId2(userShiftId);

                            if (userShiftEditing1!=null && userShiftEditing1!=null)
                            {
                                userShiftRequestSwitch.setUserStatus2(UserShiftRequestSwitch.APPROVED);

                                // Set other user to not approved
                                userShiftRequestSwitch.setUserStatus1(UserShiftRequestSwitch.NOT_APPROVED);
                            }
                        }
                    }
                }
                else
                {
                    if (actionType==USER1_APPROVES)
                    {
                        // Check that current user is admin or that user current user is same as user 1
                        if (UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftEditing1))
                        {
                            userShiftRequestSwitch.setUserStatus1(UserShiftRequestSwitch.APPROVED);
                        }
                    }
                    else if (actionType==USER1_NOT_APPROVES)
                    {
                        // Check that current user is admin or that user current user is same as user 1
                        if (UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftEditing1))
                        {
                            userShiftRequestSwitch.setUserStatus1(UserShiftRequestSwitch.NOT_APPROVED);
                        }
                    }
                    else if (actionType==REMOVE_USER_SHIFT1)
                    {
                        // Check that current user is admin or that user current user is same as user 1
                        if (UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftEditing1))
                        {
                            userShiftRequestSwitch.setUserStatus1(UserShiftRequestSwitch.NOT_APPROVED);
                            userShiftRequestSwitch.setUserShiftId1(-1);
                        }
                    }
                    else if (actionType==USER2_APPROVES)
                    {
                        // Check that current user is admin or that user current user is same as user 2
                        if (UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftEditing2))
                        {
                            userShiftRequestSwitch.setUserStatus2(UserShiftRequestSwitch.APPROVED);
                        }
                    }
                    else if (actionType==USER2_NOT_APPROVES)
                    {
                        // Check that current user is admin or that user current user is same as user 2
                        if (UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftEditing2))
                        {
                            userShiftRequestSwitch.setUserStatus2(UserShiftRequestSwitch.NOT_APPROVED);
                        }
                    }
                    else if (actionType==REMOVE_USER_SHIFT2)
                    {
                        // Check that current user is admin or that user current user is same as user 2
                        if (UserShiftRequestSwitchUtils.checkUpdateAccessToUserShift(aRequest,currentUser,userShiftEditing2))
                        {
                            userShiftRequestSwitch.setUserStatus2(UserShiftRequestSwitch.NOT_APPROVED);
                            userShiftRequestSwitch.setUserShiftId2(-1);
                        }
                    }
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
