package sched.data;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import javax.jdo.PersistenceManager;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.utils.DateUtils;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;
import sched.utils.ValidationUtils;

/**
 * Move a shift.
 *
 * @author Brian Spiegel
 */
public class UserShiftMove
{
    /**
     * Move a user shift.
     *
     * @param aRequest The request
     * @param aRoles roles
     * @param aShiftTemaplates shift templates
     * @param aUsers users
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

        // Get current user
        User currentUser=RequestUtils.getCurrentUser(aRequest);
        if (currentUser==null)
        {
            // Should be caught by SessionUtils.isLoggedOn, but just in case.
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_USER_NOT_FOUND);
            return;
        }

        // Locale
        Locale locale=SessionUtils.getLocale(aRequest);

        // Date display
        SimpleDateFormat displayDateFormat=new SimpleDateFormat("yyyy MMM dd EEE h:mm aa", locale);
        displayDateFormat.setTimeZone(currentStore.getTimeZone());

        // Get shift
        Long userShiftId=(Long)aRequest.getAttribute("shiftId");
        if (userShiftId==null)
        {
            return;
        }

        Long userId=(Long)aRequest.getAttribute("userIdMove");
        if (userId==null)
        {
            return;
        }

        // Get user.
        User user=null;
        if (aUsers.containsKey(userId))
        {
            user=aUsers.get(userId);
        }
        // Shouldn't happen, but just in case.
        if (user==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_NOT_FOUND_FOR_STORE);
            return;
        }

        // Get date
        Long startYear=(Long)aRequest.getAttribute("startYearMove");
        Long startMonth=(Long)aRequest.getAttribute("startMonthMove");
        Long startDay=(Long)aRequest.getAttribute("startDayMove");

        if (startYear==null || startMonth==null || startDay==null)
        {
            return;
        }

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Get shift and add to list
            UserShift userShift=UserShiftUtils.getUserShiftFromStore(aRequest,pm,storeId,userShiftId.longValue(),aRoles,aShiftTemplates,aUsers);
            if (userShift==null)
            {
                return;
            }

            // Check if user has access to the user shift.
            if (!ValidationUtils.checkUpdateAccessToUserShift(aRequest, currentUser, userShift, aRoles))
            {
                return;
            }

            // If not admin, current user has to be new user Id
            if (!currentUser.getIsAdmin() && currentUser.getKey().getId()!=userId)
            {
                // RequestUtils.addEditUsingKey(aRequest,EditMessages.ADMIN_ACCESS_REQUIRED);
                return;
            }

            // Set start
            Calendar startCalendar=DateUtils.getCalendar(aRequest);
            startCalendar.setTime(userShift.getStartDate());
            startCalendar.set(Calendar.YEAR, startYear.intValue());
            startCalendar.set(Calendar.MONTH, startMonth.intValue()-1);
            startCalendar.set(Calendar.DATE, startDay.intValue());

            Date endDate=DateUtils.getEndDate(startCalendar.getTime(),userShift.getDuration());

            // Get existing shifts
            List existingShifts=UserShiftUtils.getShifts(aRequest,pm,storeId,userId,startCalendar.getTime(),endDate);

            // Display name
            String displayName=DisplayUtils.formatName(user.getFirstName(),user.getLastName(),false);

            boolean exists=UserShiftUtils.checkIfShiftExists(aRequest,existingShifts,startCalendar.getTime(),endDate,displayDateFormat, -1, displayName);

            // Update
            if (!exists && !RequestUtils.hasEdits(aRequest))
            {
                userShift.setUserId(userId);
                userShift.setStartDate(startCalendar.getTime());
                userShift.setLastUpdateUserId(currentUser.getKey().getId());
                userShift.setLastUpdateTime(new Date());
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
