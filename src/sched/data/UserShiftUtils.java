package sched.data;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
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
import sched.data.model.UserShiftRequestSwitch;
import sched.utils.DateUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * User shift utils.
 *
 * @author Brian Spiegel
 */
public class UserShiftUtils
{

    /**
     * Check if shift already exists.
     *
     * @param aRequest The request
     * @param aUserShifts existing shifts
     * @param aStartDate start date
     * @param aEndDate end date
     * @param aDisplayDateFormat date format
     * @param aUserShiftIdToSkip optional role Id to skip.  If none, use -1.	 
     * @param aName name for edit message
     * @return a boolean indicating if a shift already exists during the given start and end date
     *
     * @since 1.0
     */
    public static boolean checkIfShiftExists(HttpServletRequest aRequest, List<UserShift> aUserShifts, Date aStartDate, Date aEndDate, SimpleDateFormat aDisplayDateFormat, long aUserShiftIdToSkip, String aName)
    {
        boolean exists=false;

        for (UserShift userShift : aUserShifts)
        {
            // Existing end date
            Date existingStartDate=userShift.getStartDate();
            Date existingEndDate=DateUtils.getEndDate(userShift.getStartDate(),userShift.getDuration());

            // Role and shift templates
            Map<Long,Role> roles=(Map<Long,Role>)aRequest.getAttribute("roles");
            Map<Long,ShiftTemplate> shiftTemplates=(Map<Long,ShiftTemplate>)aRequest.getAttribute("shiftTemplates");            

            /*
                1.) Verify user shift Id is being skipped or not.
                2.) Verify role and shift template are valid.
                3.) If an existing start time is greater or equal than the proposed start time and
                    that existing start time is less than the proposed end time.
                4.) If an existing start time is less than a proposed start time and the
                    corresponding existing end time is greater than the proposed start time.    
            */
            if (
                aUserShiftIdToSkip!=userShift.getKey().getId() &&
                RoleUtils.isValidRole(roles,userShift.getRoleId()) &&                
                ShiftTemplateUtils.isValidShiftTemplate(shiftTemplates,userShift.getShiftTemplateId()) &&
                ( (existingStartDate.compareTo(aStartDate)>=0 && existingStartDate.compareTo(aEndDate)<0)
                || (existingStartDate.compareTo(aStartDate)<0 && existingEndDate.compareTo(aStartDate)>0)))
            {
                exists=true;
                
                ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(aRequest));
                String editMessage=bundle.getString("shiftExistsEdit") + aName + ", " + aDisplayDateFormat.format(userShift.getStartDate()) + " - " + aDisplayDateFormat.format(existingEndDate);
                RequestUtils.addEdit(aRequest,editMessage);                                
            }
        }

        return exists;
    }

    /**
     * Get existing shifts.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aUserId user Id
     * @param aStartDate start date
     * @param aEndDate end date
     * @return a list of UserShifts
     * @since 1.0
     */
    public static List<UserShift> getShifts(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, long aUserId, Date aStartDate, Date aEndDate)
    {
        List<UserShift> results=null;

        Query query=null;
        try
        {
            // Get all shifts for this user
            query = aPm.newQuery(UserShift.class); 
            query.setFilter("(storeId == storeIdParam) && (userId == userIdParam) && (startDate > startDateParam) && (startDate < endDateParam)"); 
            query.declareParameters("long storeIdParam, long userIdParam, java.util.Date startDateParam, java.util.Date endDateParam");

            Calendar startCalendar=DateUtils.getCalendar(aRequest);
            startCalendar.setTime(aStartDate);
            startCalendar.add(Calendar.HOUR_OF_DAY, -24);
            Date startDate=startCalendar.getTime();

            Object[] inputs={aStoreId, aUserId, startDate, aEndDate};
            results = (List<UserShift>) query.executeWithArray(inputs); 
        }
        catch (Exception e)
        {
            System.err.println(UserShiftUtils.class.getName() + ": " + e);
            e.printStackTrace();
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ERROR_PROCESSING_REQUEST);
        }
        finally
        {
            if (query!=null)
            {   
                query.closeAll(); 
            }
        }

        return results;
    }
    
    /**
     * Get the user shift for a store.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aUserShiftId user shift Id
     * @param aRoles roles
     * @param aShiftTemaplates shift templates	 
     * @return a user shift or null if not found
     *
     * @since 1.0
     */
    public static UserShift getUserShiftFromStore(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, long aUserShiftId, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates, Map<Long,User> aUsers)
    {
        UserShift userShift=null;

        Query query=null;
        try
        {
            // Get user shifts.
            query = aPm.newQuery(UserShift.class); 
            query.setFilter("(storeId == storeIdParam) && (key == userShiftIdParam)"); 
            query.declareParameters("long storeIdParam, long userShiftIdParam");
            query.setRange(0,1);

            List<UserShift> results = (List<UserShift>) query.execute(aStoreId, aUserShiftId); 

            if (!results.isEmpty())
            {
                UserShift currUserShift=(UserShift)results.get(0);

                long roleId=currUserShift.getRoleId();
                long shiftTemplateId=currUserShift.getShiftTemplateId();

                // Check that user exists.
                if (aUsers.containsKey(new Long(currUserShift.getUserId())))
                {      
                    User user=aUsers.get(new Long(currUserShift.getUserId()));
                
                    // Check that role and shift template exists
                    if (RoleUtils.isValidRole(aRoles,roleId)
                    && ShiftTemplateUtils.isValidShiftTemplate(aShiftTemplates,shiftTemplateId))                
                    {
                        aRequest.setAttribute("userShiftUtils_user", user);
                        userShift=currUserShift;
                    }
                }
            }
        }
        finally
        {
            if (query!=null)
            {   
                query.closeAll(); 
            }
        }

        return userShift;
    }
    
    /**
     * Get user shift.  First check the user shift map.
     * If it's not in the map, get it from the datastore and put it in the map.
     *
     * This differs from getUserShift above.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aUserShiftId user shift Id
     * @param aUserShifts user shifts
     * @param aRoles roles
     * @param aShiftTemaplates shift templates	 
     * @return a user shift or null if not found
     *
     * @since 1.0
     */
    public static UserShift getUserShift(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, long aUserShiftRequestId, Map<Long,UserShift> aUserShifts, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates, Map<Long,User> aUsers)
    {    
        UserShift userShift=null;
    
        // If user shifts doesn't contains the shift, get it from the datastore.
        if (!aUserShifts.containsKey(new Long(aUserShiftRequestId)))
        {
            // Get shift
            userShift=UserShiftUtils.getUserShiftFromStore(aRequest,aPm,aStoreId,aUserShiftRequestId,aRoles,aShiftTemplates, aUsers);
            
            // If exists, put in map.
            if (userShift!=null)
            {
                aUserShifts.put(new Long(userShift.getKey().getId()), aPm.detachCopy(userShift));
            }
        }
        // Else, return the shift from the map.
        else
        {
            userShift=aUserShifts.get(new Long(aUserShiftRequestId));
        }
        
        return userShift;
    }    
}
