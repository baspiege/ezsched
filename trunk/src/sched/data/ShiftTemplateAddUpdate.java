package sched.data;

import java.util.List;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.utils.DateUtils;
import sched.utils.EditMessages;
import sched.utils.MemCacheUtils;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;
import sched.utils.ValidationUtils;

/**
 * Add or update a shift template to a store.
 *
 * Check that the desc is not already being used.
 *
 * @author Brian Spiegel
 */
public class ShiftTemplateAddUpdate
{
    /**
     * Add or update a shift template.
     *
     * @param aRequest The request
     *
     * @since 1.0
     */
    public void execute(HttpServletRequest aRequest)
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

        // Get user shift Id. If present, then editing.
        boolean isEditing=false;
        Long shiftTemplateId=(Long)aRequest.getAttribute("shiftTemplateId");
        if (shiftTemplateId!=null)
        {
            isEditing=true;
        }

        // Get Desc
        String desc=(String)aRequest.getAttribute("desc");

        // Duration in minutes
        Long durationHour=(Long)aRequest.getAttribute("durationHour");
        Long durationMinute=(Long)aRequest.getAttribute("durationMinute");
        int durationMin=durationHour.intValue()*60 + durationMinute.intValue();

        // Check duration
        ValidationUtils.checkDuration(aRequest, durationMin);

        // Start time
        Long startHour=(Long)aRequest.getAttribute("startHour");
        Long startMinute=(Long)aRequest.getAttribute("startMinute");
        String startAmPm=(String)aRequest.getAttribute("startAmPm");
        int startTimeMin=DateUtils.getMinutes(aRequest, startHour, startMinute, startAmPm);

        // Check if time is 0 or less.
        if (startTimeMin<=0)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.START_TIME_MUST_BE_GREATER_THAN_ZERO);
        }

        // Check if time is 24 hrs or more.
        if (startTimeMin>=24*60)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.START_TIME_MUST_BE_LESS_THAN_24_HOURS);
        }
        
        // Color
        String color=(String)aRequest.getAttribute("color");

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Editing
            if (isEditing)
            {
                ShiftTemplate shiftTemplateEditing=ShiftTemplateUtils.getShiftTemplateFromStore(aRequest,pm,storeId,shiftTemplateId.longValue());
                if (shiftTemplateEditing==null)
                {
                    RequestUtils.addEditUsingKey(aRequest,EditMessages.SHIFT_TEMPLATE_NOT_FOUND_FOR_STORE);
                    return;
                }

                // Check if desc exists
                if (!RequestUtils.hasEdits(aRequest))
                {
                    ShiftTemplateUtils.checkIfDescExists(aRequest, pm, storeId, desc, shiftTemplateEditing.getKey().getId());
                }

                // Update
                if (!RequestUtils.hasEdits(aRequest))
                {
                    shiftTemplateEditing.setDesc(desc);
                    shiftTemplateEditing.setStartTime(startTimeMin);
                    shiftTemplateEditing.setDuration(durationMin);
                    shiftTemplateEditing.setColor(color);

                    // Clear request and cache.
                    RequestUtils.setShiftTemplates(aRequest,null);
                    MemCacheUtils.setShiftTemplates(aRequest,null);
                }
            }
            // Adding
            else
            {
                // Check if desc exists
                if (!RequestUtils.hasEdits(aRequest))
                {
                    ShiftTemplateUtils.checkIfDescExists(aRequest, pm, storeId, desc, -1);
                }

                if (!RequestUtils.hasEdits(aRequest))
                {
                    // Create shift template.
                    ShiftTemplate shiftTemplate=new ShiftTemplate(storeId, startTimeMin, durationMin, desc);
                    shiftTemplate.setColor(color);

                    // Save shift template.
                    pm.makePersistent(shiftTemplate);

                    // Clear request and cache.
                    RequestUtils.setShiftTemplates(aRequest,null);
                    MemCacheUtils.setShiftTemplates(aRequest,null);
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
