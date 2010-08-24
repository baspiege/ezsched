package sched.data;

import javax.jdo.PersistenceManager;
import javax.servlet.http.HttpServletRequest;

import sched.data.model.ItemToDelete;
import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.MemCacheUtils;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Delete a shift template of a store.
 *
 * Check if a user is an admin.
 *
 * @author Brian Spiegel
 */
public class ShiftTemplateDelete
{
    /**
     * Delete a shift template.
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

        // Get fields
        long shiftTemplateId=((Long)aRequest.getAttribute("shiftTemplateId")).longValue();

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            // Get shift template.
            ShiftTemplate shiftTemplate=ShiftTemplateUtils.getShiftTemplateFromStore(aRequest,pm,storeId,shiftTemplateId);
            if (shiftTemplate==null)
            {
                RequestUtils.addEditUsingKey(aRequest,EditMessages.SHIFT_TEMPLATE_NOT_FOUND_FOR_STORE);
                return;
            }

            // Delete shift template.
            pm.deletePersistent(shiftTemplate);

            // Clear request and cache.
            RequestUtils.setShiftTemplates(aRequest,null);
            MemCacheUtils.setShiftTemplates(aRequest,null);

            // Mark shift template to be deleted (corresponding items)
            ItemToDelete itemToDelete=new ItemToDelete(ItemToDelete.SHIFT_TEMPLATE, storeId , shiftTemplateId);
            pm.makePersistent(itemToDelete);
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
