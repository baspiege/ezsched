package sched.data;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.ResourceBundle;
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
 * Get user shifts from a starting date for a given duration.
 *
 * From the given date, go back 1 day and forward the days in the display.
 *
 * @author Brian Spiegel
 */
public class UserShiftGetAll
{
    private static final String AND="&&";
    private static final String ROLE_FILTER="(roleId==roleIdParam)";
    private static final String SHIFT_TEMPLATE_FILTER="(shiftTemplateId==shiftTemplateIdParam)";
    private static final String STARTDATE_FILTER="(startDate > startDateParam) && (startDate < endDateParam)";
    private static final String STORE_FILTER="(storeId == storeIdParam)";
    private static final String USER_FILTER="(userId==userIdParam)";

    /**
     * Get user shifts.
     *
     * @param aRequest The request
     * @param aRoles roles
     * @param aShiftTemaplates shift templates
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates, Map<Long,User> aUsers, boolean aSortByUserId)
    {
        // Get store Id
        Store currentStore=RequestUtils.getCurrentStore(aRequest);
        if (currentStore==null)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.CURRENT_STORE_NOT_SET);
            return;
        }
        long storeId=currentStore.getKey().getId();

        // Get date.
        Calendar startCalendar=null;

        // If no year, use current date.
        Long startYear=(Long)aRequest.getAttribute("startYear");
        if (startYear==null)
        {
            startCalendar=DateUtils.getCalendar(aRequest);

            // Set time to start of day.
            startCalendar.set(Calendar.HOUR_OF_DAY, 0);
            startCalendar.set(Calendar.MINUTE, 0);
            startCalendar.set(Calendar.SECOND, 0);
        }
        else
        {
            Long startMonth=(Long)aRequest.getAttribute("startMonth");
            Long startDay=(Long)aRequest.getAttribute("startDay");
            startCalendar=DateUtils.getCalendar(aRequest, startYear, startMonth, startDay, new Long(0), new Long(0), DateUtils.AM);
        }

        // Get days in display
        Long displayDays=(Long)aRequest.getAttribute("displayDays");
        if (displayDays==null)
        {
            displayDays=new Long(7);
        }

        // Check next or previous
        String action=(String)aRequest.getAttribute("action");
        if (action!=null)
        {
            ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(aRequest));

            if (action.equals(bundle.getString("viewPreviousPeriodButton")))
            {
                startCalendar.add(Calendar.DATE, -1*displayDays.intValue());
            }
            else if (action.equals(bundle.getString("viewNextPeriodButton")))
            {
                startCalendar.add(Calendar.DATE, displayDays.intValue());
            }

            // Update request
            startYear = new Long( new Integer(startCalendar.get(Calendar.YEAR)) ).longValue();
            Long startMonth = new Long( new Integer(startCalendar.get(Calendar.MONTH)+1) ).longValue();
            Long startDay = new Long( new Integer(startCalendar.get(Calendar.DATE)) ).longValue();

            aRequest.setAttribute("startYear", startYear);
            aRequest.setAttribute("startMonth", startMonth);
            aRequest.setAttribute("startDay", startDay);
        }

        // Set in request
        aRequest.setAttribute("startDate",startCalendar.getTime());

        // Go back 1 day as shifts can only be 1 day long
        startCalendar.add(Calendar.DATE, -1);
        Date startDate=startCalendar.getTime();

        // Go forward 1 + days in display
        startCalendar.add(Calendar.DATE, 1 + displayDays.intValue());
        Date endDate=startCalendar.getTime();

        // User Id
        Long userId=(Long)aRequest.getAttribute("userId");
        boolean allUsers=false;
        if (userId==null || userId.longValue()==User.ALL_USERS)
        {
            allUsers=true;
        }
        // Check if user exists
        // Using the map users because it's already present.
        // Otherwise, UserUtils.getUserFromStore could be used.
        else if (aUsers==null || !aUsers.containsKey(userId))
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.USER_NOT_FOUND_FOR_STORE);
            return;
        }

        // Role Id
        Long roleId=(Long)aRequest.getAttribute("roleId");
        boolean allRoles=false;
        if (roleId==null || roleId.longValue()==Role.ALL_ROLES)
        {
            allRoles=true;
        }
        // Check if role exists
        // Using the map roles because it's already present.
        // Otherwise, RoleUtils.getRoleFromStore could be used.
        else if (aRoles==null || !RoleUtils.isValidRole(aRoles,roleId))
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ROLE_NOT_FOUND_FOR_STORE);
            return;
        }

        // Shift Template Id
        boolean allShifts=false;
        Long shiftTemplateId=(Long)aRequest.getAttribute("shiftTemplateId");
        if (shiftTemplateId==null || shiftTemplateId.longValue()==ShiftTemplate.ALL_SHIFTS)
        {
            allShifts=true;
        }
        // Check if shift template exists
        else if (aShiftTemplates==null || !ShiftTemplateUtils.isValidShiftTemplate(aShiftTemplates,shiftTemplateId))
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.SHIFT_TEMPLATE_NOT_FOUND_FOR_STORE);
            return;
        }

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Get user shifts
            Query query=null;
            try
            {

                // Get user shifts.
                query = pm.newQuery(UserShift.class);
                query.setOrdering("startDate ASC");
                List<UserShift> results = null;

                // All
                if (allUsers && allRoles && allShifts)
                {
                    query.setFilter(STORE_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }
                // Specific shift template
                else if (allUsers && allRoles)
                {
                    query.setFilter(STORE_FILTER + AND + SHIFT_TEMPLATE_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, long shiftTemplateIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, shiftTemplateId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }
                // Specific role template
                else if (allUsers && allShifts)
                {
                    query.setFilter(STORE_FILTER + AND + ROLE_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, long roleIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, roleId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }
                // Specific user template
                else if (allRoles && allShifts)
                {
                    query.setFilter(STORE_FILTER + AND + USER_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, long userIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, userId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }
                // Specific shift template and role
                else if (allUsers)
                {
                    query.setFilter(STORE_FILTER + AND + SHIFT_TEMPLATE_FILTER + AND + ROLE_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, long shiftTemplateIdParam, long roleIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, shiftTemplateId, roleId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }
                // Specific shift template and user
                else if (allRoles)
                {
                    query.setFilter(STORE_FILTER + AND + SHIFT_TEMPLATE_FILTER + AND + USER_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, long shiftTemplateIdParam, long userIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, shiftTemplateId, userId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }
                // Specific role and user
                else if (allShifts)
                {
                    query.setFilter(STORE_FILTER + AND + ROLE_FILTER + AND + USER_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, long roleIdParam, long userIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, roleId, userId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }
                // Specific all
                else
                {
                    query.setFilter(STORE_FILTER + AND + ROLE_FILTER + AND + USER_FILTER + AND + SHIFT_TEMPLATE_FILTER + AND + STARTDATE_FILTER);
                    query.declareParameters("long storeIdParam, long roleIdParam, long userIdParam, long shiftTemplateIdParam, java.util.Date startDateParam, java.util.Date endDateParam");
                    Object[] parameters = { storeId, roleId, userId, shiftTemplateId, startDate, endDate };
                    results = (List<UserShift>) query.executeWithArray(parameters);
                }

                // Transfer collection LinkedHashMap
                Map userShifts=new LinkedHashMap();

                if (results!=null)
                {
                    if (aSortByUserId)
                    {
                        // Keyed by User with value being user shifts in a list.
                        for (UserShift userShift: results)
                        {
                            if (RoleUtils.isValidRole(aRoles,userShift.getRoleId())
                            && ShiftTemplateUtils.isValidShiftTemplate(aShiftTemplates,userShift.getShiftTemplateId())
                            && UserUtils.isValidUser(aUsers,userShift.getUserId()))
                            {
                                List<UserShift> shifts=null;

                                Long userShift_userId=new Long(userShift.getUserId());

                                if (userShifts.containsKey(userShift_userId))
                                {
                                    shifts = (List<UserShift>)userShifts.get(userShift_userId);
                                }
                                else
                                {
                                    shifts = new ArrayList<UserShift>();
                                    userShifts.put(userShift_userId, shifts);
                                }

                                shifts.add(pm.detachCopy(userShift));
                            }
                        }
                    }
                    else
                    {
                        // Keyed by User with value being user shifts in a list.
                        for (UserShift userShift: results)
                        {
                            if (RoleUtils.isValidRole(aRoles,userShift.getRoleId())
                            && ShiftTemplateUtils.isValidShiftTemplate(aShiftTemplates,userShift.getShiftTemplateId())
                            && UserUtils.isValidUser(aUsers,userShift.getUserId()))
                            {
                                userShifts.put(new Long(userShift.getKey().getId()), pm.detachCopy(userShift));
                            }
                        }
                    }
                }

                // Set into request
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
