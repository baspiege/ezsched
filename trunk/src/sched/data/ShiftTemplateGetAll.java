package sched.data;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.jdo.PersistenceManager;
import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.ShiftTemplate;
import sched.data.model.Store;
import sched.utils.EditMessages;
import sched.utils.RequestUtils;
import sched.utils.SessionUtils;

/**
 * Get all shift templates for a store.
 *
 * @author Brian Spiegel
 */
public class ShiftTemplateGetAll
{
    /**
     * Get all shift templates.
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

        PersistenceManager pm=null;
        try
        {
            pm=PMF.get().getPersistenceManager();

            Query query=null;
            try
            {
                // Get all shift templates
                query = pm.newQuery(ShiftTemplate.class);
                query.setFilter("storeId == storeIdParam");
                query.declareParameters("long storeIdParam");
                query.setOrdering("descLowerCase ASC");

                List<ShiftTemplate> results = (List<ShiftTemplate>) query.execute(storeId);

                Map shiftTemplateMap=new LinkedHashMap();
                for (ShiftTemplate shiftTemplate : results)
                {
                    shiftTemplateMap.put(new Long(shiftTemplate.getKey().getId()),pm.detachCopy(shiftTemplate));
                }
                aRequest.setAttribute("shiftTemplates", shiftTemplateMap);
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
