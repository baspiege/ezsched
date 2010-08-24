package sched.data;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;
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
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;
import sched.utils.ValidationUtils;

/**
 * Process a user shift switch request to a store.
 *
 * @author Brian Spiegel
 */
public class UserShiftRequestSwitchProcess
{
    /**
     * Process a user shift switch request.
     *
     * @param aRequest The request
     * @param aRoles roles
     * @param aShiftTemaplates shift templates
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
         
            // If complete, return
            if (userShiftRequestSwitch.getStatus()==UserShiftRequestSwitch.PROCESSED)
            {
                RequestUtils.addEditUsingKey(aRequest,EditMessages.SWITCH_REQUEST_PROCESSED);            
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

            // Check 1
            if (userShiftEditing1==null)
            {
                RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_SHIFT_NOT_FOUND_FOR_STORE);
                return;
            }			

            // Check 2            
            if (userShiftEditing2==null)
            {
                RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_SHIFT_NOT_FOUND_FOR_STORE);
                return;
            }
            
            if (RequestUtils.hasEdits(aRequest))
            {
                return;
            }

            // Locale
            Locale locale=SessionUtils.getLocale(aRequest);        

            // Date display        
            SimpleDateFormat displayDateFormat=new SimpleDateFormat("yyyy MMM dd EEE h:mm aa", locale);
            
            // Check if user shift 2 works in user 1 shifts
            checkIfShiftConflicts(aRequest, pm, storeId, aUsers, userShiftEditing1, userShiftEditing2, displayDateFormat);
            
            // Check if user shift 1 works in user 2 shifts            
            checkIfShiftConflicts(aRequest, pm, storeId, aUsers, userShiftEditing2, userShiftEditing1, displayDateFormat);           
            
            if (RequestUtils.hasEdits(aRequest))
            {
                return;
            }
            
            long userId1=userShiftEditing1.getUserId();
            long userId2=userShiftEditing2.getUserId();
            
            // Update shift 1
            userShiftEditing1.setUserId(userId2);
            userShiftEditing1.setLastUpdateUserId(currentUser.getKey().getId());
            userShiftEditing1.setLastUpdateTime(new Date());					

            // Update shift 2
            userShiftEditing2.setUserId(userId1);
            userShiftEditing2.setLastUpdateUserId(currentUser.getKey().getId());
            userShiftEditing2.setLastUpdateTime(new Date());            
            
            // Set as processed
            //userShiftRequestSwitch.setStatus(UserShiftRequestSwitch.PROCESSED);

            // Delete switch request.
            pm.deletePersistent(userShiftRequestSwitch);
            
            // Get switch requests
            new UserShiftRequestSwitchGetAll().execute(aRequest,aRoles, aShiftTemplates, aUsers);
            Map<Long,UserShiftRequestSwitch> aUserShiftRequestSwitchMap=(Map<Long,UserShiftRequestSwitch>)aRequest.getAttribute("userShiftRequestSwitchs");            
            
            // Remove user shifts from all switch requests. 
            // False to remove.
            UserShiftRequestSwitchUtils.updateUserShiftInSwitchRequests(aRequest, pm, aUserShiftRequestSwitchMap, userShiftEditing1.getKey().getId(), false);
            UserShiftRequestSwitchUtils.updateUserShiftInSwitchRequests(aRequest, pm, aUserShiftRequestSwitchMap, userShiftEditing2.getKey().getId(), false);
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

    /**
     * Process a user shift switch request.
     *
     * @param aRequest The request
     * @param aPm Persistence Manager
     * @param aStoreId store Id
     * @param aUser users
     * @param aUserShift1 user shift 1
     * @param aUserShift2 user shift 2     
     * @param aDisplayDateFormat date format for edit message
     * @return a boolean indicating if the shift conflicts
     *
     * @since 1.0
     */
    public boolean checkIfShiftConflicts(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, Map<Long,User> aUsers, UserShift aUserShift1, UserShift aUserShift2, SimpleDateFormat aDisplayDateFormat)
    {
        Calendar startDateCalendar=DateUtils.getCalendar(aRequest);
        startDateCalendar.setTime(aUserShift2.getStartDate());
        startDateCalendar.add(Calendar.DATE, -1);
        
        Date existingEndDate=DateUtils.getEndDate(aUserShift2.getStartDate(),aUserShift2.getDuration());
                     
        // Get existing shifts for user 1
        List existingShifts=UserShiftUtils.getShifts(aRequest,aPm,aStoreId,aUserShift1.getUserId(),startDateCalendar.getTime(),existingEndDate);            

        // Get user 1.
        User user=null;
        if (aUsers.containsKey(new Long(aUserShift1.getUserId())))
        {
            user=aUsers.get(new Long(aUserShift1.getUserId()));
        }
        if (user==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_NOT_FOUND_FOR_STORE);
            return true;
        }        
        
        // Display name
        String displayName=DisplayUtils.formatName(user.getFirstName(),user.getLastName(),false);

        boolean exists=UserShiftUtils.checkIfShiftExists(aRequest,existingShifts,aUserShift2.getStartDate(),existingEndDate,aDisplayDateFormat, aUserShift1.getKey().getId(), displayName);

        return exists;
    }
}
