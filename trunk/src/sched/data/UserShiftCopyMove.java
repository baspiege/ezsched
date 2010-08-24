package sched.data;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Collections;
import java.util.ArrayList;
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
 * Copy and move a list of user shifts.
 *
 * @author Brian Spiegel
 */
public class UserShiftCopyMove
{
    /**
     * Copy and move a list of user shifts.
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
        List<Long> userShiftIds=(List<Long>)aRequest.getAttribute("s");

        // Days to move
        int daysToMove=1;
        Long daysToMoveLong=null;
        daysToMoveLong=(Long)aRequest.getAttribute("daysToMove");
        if (daysToMoveLong==null)
        {
            daysToMove=1;
        }
        else
        {
            daysToMove=daysToMoveLong.intValue();
        }

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            List<UserShift> userShifts=new ArrayList<UserShift>();

            for (Long userShiftId: userShiftIds)
            {
                // Get shift and add to list
                UserShift userShift=UserShiftUtils.getUserShiftFromStore(aRequest,pm,storeId,userShiftId.longValue(),aRoles,aShiftTemplates,aUsers);

                if (userShift!=null)
                {
                    userShifts.add(userShift);
                }
            }

            // Order by start time descending
            Collections.sort(userShifts,new UserShiftSortByStartDate());

            for (UserShift userShift: userShifts)
            {
                // Check if user has access to the user shift.
                if (!ValidationUtils.checkUpdateAccessToUserShift(aRequest, currentUser, userShift, aRoles))
                {
                    // Try next shift.
                    continue;
                }

                // Set start
                Calendar startCalendar=DateUtils.getCalendar(aRequest);
                startCalendar.setTime(userShift.getStartDate());
                startCalendar.add(Calendar.DATE, daysToMove);

                Date endDate=DateUtils.getEndDate(startCalendar.getTime(),userShift.getDuration());

                // Get existing shifts
                List existingShifts=UserShiftUtils.getShifts(aRequest,pm,storeId,userShift.getUserId(),startCalendar.getTime(),endDate);

                // Get user.
                User user=null;
                if (aUsers.containsKey(new Long(userShift.getUserId())))
                {
                    user=aUsers.get(new Long(userShift.getUserId()));
                }
                // Shouldn't happen, but just in case.
                if (user==null)
                {
                    RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_NOT_FOUND_FOR_STORE);
                    continue;
                }

                // Display name
                String displayName=DisplayUtils.formatName(user.getFirstName(),user.getLastName(),false);

                boolean exists=UserShiftUtils.checkIfShiftExists(aRequest,existingShifts,startCalendar.getTime(),endDate,displayDateFormat, -1, displayName);

                // Add
                if (!exists)
                {
                    // Create new shift
                    UserShift newUserShift=new UserShift(storeId, userShift.getUserId(), startCalendar.getTime(), userShift.getDuration(), currentUser.getKey().getId(), new Date());
                    newUserShift.setRoleId(userShift.getRoleId());
                    newUserShift.setShiftTemplateId(userShift.getShiftTemplateId());
                    newUserShift.setNote(userShift.getNote());

                    // Save
                    pm.makePersistent(newUserShift);
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
