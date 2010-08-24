package sched.utils;

import java.util.Locale;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import sched.data.model.Store;
import sched.data.StoreGetSingle;

/**
 * Session utilities.
 *
 * @author Brian Spiegel
 */
public class SessionUtils
{
    public static String CURRENT_STORE_ID="currentStoreId";
    public static String LOGGED_ON="loggedOn";
    public static String LOCALE="locale";

    // This is user Id being displayed on the schedule page, not the user logged in.
    public static String USER_ID_DISPLAYED_ON_SCHEDULE="userIdDisplayedOnSchedule";

    // This is role Id being displayed on the schedule page.
    public static String ROLE_ID_DISPLAYED_ON_SCHEDULE="roleIdDisplayedOnSchedule";

    // This is shift template Id being displayed on the schedule page.
    public static String SHIFT_TEMPLATE_ID_DISPLAYED_ON_SCHEDULE="shiftTemplateIdDisplayedOnSchedule";

    /**
    * Get a field from the session as a Long object.
    *
    * @param aRequest request
    */
    public static Long getFieldAsLong(HttpServletRequest aRequest, String aFieldName)
    {
        Long valueLong=null;
        HttpSession session=aRequest.getSession();
        if (session.getAttribute(aFieldName)!=null)
        {
            valueLong=(Long)session.getAttribute(aFieldName);
        }
        return valueLong;
    }

    /**
     * Get a long field, fiest checking request.
     * First check request, then session, then use default.
     *
     * @param aRequest request
     * @param aSessionName session name
     * @param aRequestName request name
     * @param aDescriptionName description
     * @param aDefaultValue	default value
     *
     * @return the value being used
     */
    public static Long getFieldAsLongCheckingRequest(HttpServletRequest aRequest, String aSessionName, String aRequestName, String aDescription, Long aDefaultValue)
    {
        // If not forwarded, check request.  Else check session.  Else reset.
        Long valueLong=null;
        if (!RequestUtils.isForwarded(aRequest))
        {
            valueLong=RequestUtils.getNumericInput(aRequest,aRequestName,aDescription,false);
        }

        // Try session
        if (valueLong==null)
        {
            valueLong=SessionUtils.getFieldAsLong(aRequest, aSessionName);

            if (valueLong!=null)
            {
                aRequest.setAttribute(aRequestName,valueLong);
            }
        }

        // Default value
        if (valueLong==null)
        {
            valueLong=aDefaultValue;
            aRequest.setAttribute(aRequestName,valueLong);
        }

        return valueLong;
    }

    /**
    * Get the locale being used.
    *
    * @param aRequest request
    */
    public static Locale getLocale(HttpServletRequest aRequest)
    {
        Locale locale=null;
        HttpSession session=aRequest.getSession();
        String localeString=(String)session.getAttribute(LOCALE);

        if (localeString!=null)
        {
            locale=new Locale(localeString);
        }
        else
        {
            locale=Locale.getDefault();
        }

        return locale;
    }

    /**
    * Get the locale being used.
    *
    * @param aRequest request
    */
    public static String getLocaleString(HttpServletRequest aRequest)
    {
        HttpSession session=aRequest.getSession();
        return (String)session.getAttribute(LOCALE);
    }

    /**
    * Get the role Id being displayed on the schedule.
    *
    * @param aRequest request
    */
    public static Long getRoleIdDisplayedOnSchedule(HttpServletRequest aRequest)
    {
        HttpSession session=aRequest.getSession();
        return (Long)session.getAttribute(ROLE_ID_DISPLAYED_ON_SCHEDULE);
    }

    /**
    * Get the shift template Id being displayed on the schedule.
    *
    * @param aRequest request
    */
    public static Long getShiftTemplateIdDisplayedOnSchedule(HttpServletRequest aRequest)
    {
        HttpSession session=aRequest.getSession();
        return (Long)session.getAttribute(SHIFT_TEMPLATE_ID_DISPLAYED_ON_SCHEDULE);
    }

    /**
    * Get the user Id being displayed on the schedule.
    *
    * @param aRequest request
    */
    public static Long getUserIdDisplayedOnSchedule(HttpServletRequest aRequest)
    {
        HttpSession session=aRequest.getSession();
        return (Long)session.getAttribute(USER_ID_DISPLAYED_ON_SCHEDULE);
    }

    /**
    * Check if logged on.
    *
    * @param aRequest request
    * @return a boolean indicating if the user is logged on
    */
    public static boolean isLoggedOn(HttpServletRequest aRequest)
    {
        Boolean isLoggedOn=(Boolean)aRequest.getSession().getAttribute(LOGGED_ON);

        if (isLoggedOn==null || !isLoggedOn.booleanValue())
        {
            return false;
        }

        return true;
    }

    /**
    * Set the current store Id in the session.  Don't put the store object into
    * session because it might change during a user's session.
    *
    * @param aRequest Servlet Request
    * @param aStore a store
    */
    public static void setCurrentStoreId(HttpServletRequest aRequest, Long aStoreId)
    {
        aRequest.getSession().setAttribute(CURRENT_STORE_ID,aStoreId);
    }

    /**
    * Set the currentStore from the session to the request.  The request needs
    * to be used because the session can change on multiple requests.
    *
    * @param aRequest request
    */
    public static void setCurrentStoreIntoRequest(HttpServletRequest aRequest)
    {
        // If not already set, set it.  Don't overwrite if not null as the store
        // can't change during a request.
        if (aRequest.getAttribute(RequestUtils.CURRENT_STORE)==null)
        {
            // Get store Id from session
            Long currentStoreId=(Long)aRequest.getSession().getAttribute(CURRENT_STORE_ID);
            if (currentStoreId==null)
            {
                return;
            }

            // Try cache.
            Store store=MemCacheUtils.getStore(aRequest);
            if (store!=null)
            {
                // Set into request.
                aRequest.setAttribute(RequestUtils.CURRENT_STORE,store);
            }
            else
            {
                // Get from the datastore which sets into the request.
                // And put into the cache.
                aRequest.setAttribute("storeId", currentStoreId);
                new StoreGetSingle().execute(aRequest);
                store=(Store)aRequest.getAttribute("store");

                // Put into request
                aRequest.setAttribute(RequestUtils.CURRENT_STORE, store);
            }
        }
    }

    /**
    * Set the locale.
    *
    * @param aRequest request
    */
    public static void setLocale(HttpServletRequest aRequest, String aLocale)
    {
        aRequest.getSession().setAttribute(LOCALE, aLocale);
    }

    /**
    * Set the role Id being displayed on the schedule.
    *
    * @param aRequest request
    */
    public static void setRoleIdDisplayedOnSchedule(HttpServletRequest aRequest, Long aId)
    {
        aRequest.getSession().setAttribute(ROLE_ID_DISPLAYED_ON_SCHEDULE, aId);
    }

    /**
    * Set the shift template Id being displayed on the schedule.
    *
    * @param aRequest request
    */
    public static void setShiftTemplateIdDisplayedOnSchedule(HttpServletRequest aRequest, Long aId)
    {
        aRequest.getSession().setAttribute(SHIFT_TEMPLATE_ID_DISPLAYED_ON_SCHEDULE, aId);
    }

    /**
    * Set the user Id being displayed on the schedule.
    *
    * @param aRequest request
    */
    public static void setUserIdDisplayedOnSchedule(HttpServletRequest aRequest, Long aId)
    {
        aRequest.getSession().setAttribute(USER_ID_DISPLAYED_ON_SCHEDULE, aId);
    }
}
