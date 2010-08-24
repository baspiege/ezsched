package sched.data;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.ArrayList;
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
import sched.data.UserShiftRequestSwitchUtils;
import sched.utils.DateUtils;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;
import sched.utils.ValidationUtils;

/**
 * Add or edit a shift for a user.
 *
 * @author Brian Spiegel
 */
public class UserShiftAddUpdate
{
    /**
     * Add or edit a shift for a user.
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

        // Get user shift Id. If present, then editing.
        boolean isEditing=false;
        Long userShiftId=(Long)aRequest.getAttribute("userShiftId");
        if (userShiftId!=null)
        {
            isEditing=true;
        }

        // User Id
        long userId=0;

        // Get from form
        if (currentUser.getIsAdmin())
        {
            // User will be checked in the store below with the method getUserFromStore.
            userId=((Long)aRequest.getAttribute("userId")).longValue();
        }
        // Use the current user's Id
        else
        {
            userId=currentUser.getKey().getId();
        }

        // Role Id
        Long roleId=(Long)aRequest.getAttribute("roleId");
        if (roleId==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ROLE_NOT_FOUND_FOR_STORE);
            return;
        }

        // Check if role exists
        // Using the map roles because it's already present.
        // Otherwise, RoleUtils.getRoleFromStore could be used.
        if (aRoles==null || !RoleUtils.isValidRole(aRoles,roleId))
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ROLE_NOT_FOUND_FOR_STORE);
            return;
        }

        // Check if user has access to the role.
        ValidationUtils.checkUpdateAccessToRole(aRequest, currentUser, roleId.longValue(), aRoles);
        if (RequestUtils.hasEdits(aRequest))
        {
            return;
        }

        // Shift Template Id
        Long shiftTemplateId=(Long)aRequest.getAttribute("shiftTemplateId");
        if (shiftTemplateId==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.SHIFT_TEMPLATE_NOT_FOUND_FOR_STORE);
            return;
        }

        // Check if shift template exists
        if (aShiftTemplates==null || !ShiftTemplateUtils.isValidShiftTemplate(aShiftTemplates,shiftTemplateId))
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.SHIFT_TEMPLATE_NOT_FOUND_FOR_STORE);
            return;
        }

        // Get shift template
        ShiftTemplate shiftTemplate=null;
        boolean noShiftTemplate=false;
        if (aShiftTemplates.containsKey(shiftTemplateId))
        {
            shiftTemplate=(ShiftTemplate)aShiftTemplates.get(shiftTemplateId);
        }
        else
        {
            noShiftTemplate=true;
        }

        // Overrides
        boolean usesCustomStartTime=((Boolean)aRequest.getAttribute("usesCustomStartTime")).booleanValue();
        boolean usesCustomDuration=((Boolean)aRequest.getAttribute("usesCustomDuration")).booleanValue();

        // Start
        Long startYear=(Long)aRequest.getAttribute("startYear");
        Long startMonth=(Long)aRequest.getAttribute("startMonth");
        Long startDay=(Long)aRequest.getAttribute("startDay");
        Long startHour=null;
        Long startMinute=null;
        String startAmPm=null;

        // Start Time
        if (usesCustomStartTime || noShiftTemplate)
        {
            // Get from form
            startHour=(Long)aRequest.getAttribute("startHour");
            startMinute=(Long)aRequest.getAttribute("startMinute");
            startAmPm=(String)aRequest.getAttribute("startAmPm");
        }
        else
        {
            // Get from shift template
            int startTime=shiftTemplate.getStartTime();
            if (startTime==0)
            {
                startHour=new Long(0);
                startMinute=new Long(0);
            }
            else
            {
                startHour=new Long(startTime/60);
                startMinute=new Long(startTime%60);
            }
            startAmPm=DateUtils.NO_AM_PM;
        }

        // Duration in minutes
        int durationMin=0;
        Long durationHour=null;
        Long durationMinute=null;

        // Duration
        if (usesCustomDuration || noShiftTemplate)
        {
            // Get duration from form
            durationHour=(Long)aRequest.getAttribute("durationHour");
            durationMinute=(Long)aRequest.getAttribute("durationMinute");

            // Calculate
            durationMin=durationHour.intValue()*60 + durationMinute.intValue();
        }
        else
        {
            // Get duration from shift template
            durationMin=shiftTemplate.getDuration();
            if (durationMin!=0)
            {
                durationHour=new Long(durationMin/60);
                durationMinute=new Long(durationMin%60);
            }
        }

        // Check duration
        ValidationUtils.checkDuration(aRequest, durationMin);

        // Repeats
        int repetitions=1;
        int daysBetweenRepetitions=1;

        // Repeats are only for adds.
        if (!isEditing)
        {
            Long repetitionsLong=null;
            repetitionsLong=(Long)aRequest.getAttribute("shiftRepetition");
            if (repetitionsLong==null)
            {
                repetitions=1;
            }
            else
            {
                repetitions=repetitionsLong.intValue();
            }

            Long daysBetweenRepetitionsLong=null;
            daysBetweenRepetitionsLong=(Long)aRequest.getAttribute("shiftDaysBetweenRepetitions");
            if (daysBetweenRepetitionsLong==null)
            {
                daysBetweenRepetitions=1;
            }
            else
            {
                daysBetweenRepetitions=daysBetweenRepetitionsLong.intValue();
            }
        }

        // Start date
        Calendar startCalendar=DateUtils.getCalendar(aRequest, startYear, startMonth, startDay, startHour, startMinute, startAmPm);
        Date startDate=startCalendar.getTime();

        // End Date
        Date endDate=DateUtils.getEndDate(startDate,durationMin);

        // Note
        String note=(String)aRequest.getAttribute("note");

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

            // If edits, return.
            if (RequestUtils.hasEdits(aRequest))
            {
                return;
            }

            // Additions
            List<UserShift> additions=new ArrayList<UserShift>();

            aRequest.setAttribute("userShifts",additions);

            // If edits, return.
            if (RequestUtils.hasEdits(aRequest))
            {
                return;
            }

            // Get existing shifts
            Calendar endDateForAllRepetitions=DateUtils.getCalendar(aRequest);

            endDateForAllRepetitions.setTime(endDate);
            endDateForAllRepetitions.add(Calendar.DATE, (repetitions-1) * daysBetweenRepetitions);

            /* Orig
            endDateForAllRepetitions.setTime(startCalendar.getTime());
            endDateForAllRepetitions.add(Calendar.DATE, repetitions * daysBetweenRepetitions);
            */

            List existingShifts=UserShiftUtils.getShifts(aRequest,pm,storeId,userId,startDate,endDateForAllRepetitions.getTime());

            // Display name
            String displayName=DisplayUtils.formatName(user.getFirstName(),user.getLastName(),false);

            // Editing
            if (isEditing)
            {
                UserShift userShiftEditing=UserShiftUtils.getUserShiftFromStore(aRequest,pm,storeId,userShiftId,aRoles,aShiftTemplates,aUsers);
                if (userShiftEditing==null)
                {
                    RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_SHIFT_NOT_FOUND_FOR_STORE);
                    return;
                }

                // Check if user has access to the user shift.
                ValidationUtils.checkUpdateAccessToUserShift(aRequest, currentUser, userShiftEditing, aRoles);
                if (RequestUtils.hasEdits(aRequest))
                {
                    return;
                }

                boolean exists=UserShiftUtils.checkIfShiftExists(aRequest,existingShifts,startDate,endDate,displayDateFormat, userShiftEditing.getKey().getId(), displayName);

                // Update
                if (!exists)
                {
                    long existingUserId=userShiftEditing.getUserId();

                    userShiftEditing.setUserId(userId);
                    userShiftEditing.setStartDate(startDate);
                    userShiftEditing.setDuration(durationMin);
                    userShiftEditing.setRoleId(roleId.longValue());
                    userShiftEditing.setShiftTemplateId(shiftTemplateId);
                    userShiftEditing.setNote(note);
                    userShiftEditing.setLastUpdateUserId(currentUser.getKey().getId());
                    userShiftEditing.setLastUpdateTime(new Date());

                    // Get switch requests
                    new UserShiftRequestSwitchGetAll().execute(aRequest,aRoles, aShiftTemplates, aUsers);
                    Map<Long,UserShiftRequestSwitch> aUserShiftRequestSwitchMap=(Map<Long,UserShiftRequestSwitch>)aRequest.getAttribute("userShiftRequestSwitchs");

                    // Remove user shifts from all switch requests.
                    if (existingUserId!=userShiftEditing.getUserId())
                    {
                        // False to remove
                        UserShiftRequestSwitchUtils.updateUserShiftInSwitchRequests(aRequest, pm, aUserShiftRequestSwitchMap, userShiftEditing.getKey().getId(), false);
                    }
                    else
                    {
                        // True for 'remove approval only'
                        UserShiftRequestSwitchUtils.updateUserShiftInSwitchRequests(aRequest, pm, aUserShiftRequestSwitchMap, userShiftEditing.getKey().getId(), true);
                    }
                }
            }
            // Adding
            // Repeats only for adds
            else
            {
                long currentUserId=currentUser.getKey().getId();

                for(int i=0; i<repetitions; i++)
                {
                    boolean exists=UserShiftUtils.checkIfShiftExists(aRequest,existingShifts,startDate,endDate,displayDateFormat, -1, displayName);

                    // Add
                    if (!exists)
                    {
                        UserShift userShift=new UserShift(storeId,userId,startDate,durationMin,currentUserId,new Date());
                        userShift.setRoleId(roleId.longValue());
                        userShift.setShiftTemplateId(shiftTemplateId);
                        userShift.setNote(note);

                        // Save
                        pm.makePersistent(userShift);

                        // Display list
                        additions.add(pm.detachCopy(userShift));
                    }

                    // Increment start date and end date.
                    startCalendar.add(Calendar.DATE, daysBetweenRepetitions);
                    startDate=startCalendar.getTime();

                    // End Date
                    endDate=DateUtils.getEndDate(startDate,durationMin);
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
