package sched.data;

import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.ResourceBundle;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;

import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.data.model.User;
import sched.utils.DisplayUtils;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Shift Template utils.
 *
 * @author Brian Spiegel
 */
public class ShiftTemplateUtils
{
    /**
     * Check if desc already exists.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aDesc desc
     * @param aShiftTemplateIdToSkip optional shiftTemplate Id to skip.  If none, use -1.
     *
     * @since 1.0
     */
    public static void checkIfDescExists(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, String aDesc, long aShiftTemplateIdToSkip)
    {
        Query query=null;
        try
        {
            query = aPm.newQuery(ShiftTemplate.class);
            query.setFilter("(storeId == storeIdParam) && (descLowerCase == descLowerCaseParam)");
            query.declareParameters("long storeIdParam, String descLowerCaseParam");
            query.setRange(0,2);  // Get 2 because current will be there still.

            List<ShiftTemplate> results = (List<ShiftTemplate>) query.execute(aStoreId, aDesc.toLowerCase());

            for (ShiftTemplate shiftTemplate : results)
            {
                if (aShiftTemplateIdToSkip!=shiftTemplate.getKey().getId())
                {
                    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(aRequest));
                    String editMessage=bundle.getString("shiftTemplateExistsEdit") + shiftTemplate.getDesc();
                    RequestUtils.addEdit(aRequest,editMessage);
                }
            }
        }
        catch (Exception e)
        {
            System.err.println(ShiftTemplateUtils.class.getName() + ": " + e);
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
    }

    /**
     * Get the shiftTemplate for a store.
     *
     * @param aRequest The request
     * @param aPm PersistenceManager
     * @param aStoreId store Id
     * @param aShiftTemplateId shiftTemplate Id
     * @return a shiftTemplate or null if not found
     *
     * @since 1.0
     */
    public static ShiftTemplate getShiftTemplateFromStore(HttpServletRequest aRequest, PersistenceManager aPm, long aStoreId, long aShiftTemplateId)
    {
        ShiftTemplate shiftTemplate=null;

        Query query=null;
        try
        {
            // Get shiftTemplate.
            // Do not use getObjectById as the ShiftTemplate Id could have been changed by the shiftTemplate.
            // Use a query to get by shiftTemplate Id and store Id to verify the shiftTemplate Id is in the
            // current store.
            query = aPm.newQuery(ShiftTemplate.class);
            query.setFilter("(storeId == storeIdParam) && (key == shiftTemplateIdParam)");
            query.declareParameters("long storeIdParam, long shiftTemplateIdParam");
            query.setRange(0,1);

            List<ShiftTemplate> results = (List<ShiftTemplate>) query.execute(aStoreId, aShiftTemplateId);

            if (!results.isEmpty())
            {
                shiftTemplate=(ShiftTemplate)results.get(0);
            }
        }
        finally
        {
            if (query!=null)
            {
                query.closeAll();
            }
        }

        return shiftTemplate;
    }

    /**
     * Is the shift template valid?
     *
     * @param aShiftTemaplates shift templates
     * @param aShiftTemplateId shift template Id
     * @return if shift is valid
     *
     * @since 1.0
     */
    public static boolean isValidShiftTemplate(Map<Long,ShiftTemplate> aShiftTemplates, long aShiftTemplateId)
    {
        return (aShiftTemplates.containsKey(new Long(aShiftTemplateId)) || aShiftTemplateId==ShiftTemplate.NO_SHIFT);
    }
}
