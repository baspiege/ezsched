package sched.utils;

import java.util.Map;

import sched.data.model.Role;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.utils.EditMessages;

import javax.servlet.http.HttpServletRequest;

/**
 * Validation utilities.
 *
 * @author Brian Spiegel
 */
public class ValidationUtils
{
    /**
     * Check the duration
     *
     * @param aRequest The request
     *
     * @since 1.0
     */
    public static void checkDuration(HttpServletRequest aRequest, int aDurationMin)
    {
        // Check if duration is 0 or less.
        if (aDurationMin<=0)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.DURATION_MUST_BE_GREATER_THAN_ZERO);
        }
        // Check if duration is more than 24 hrs.
        else if (aDurationMin>24*60)
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.DURATION_MUST_BE_24_HOURS_OR_LESS);
        }
    }

    /**
     * Check that a user has update access to a user shift.  Create edit if no access.
     *
     * @param aRequest The request
     * @param aUser User
     * @param aUserShift User shift
     * @param aRoles roles
     * @return a boolean indicting if the user has update access to a role
     *
     * @since 1.0
     */
    public static boolean checkUpdateAccessToUserShift(HttpServletRequest aRequest, User aUser, UserShift aUserShift, Map<Long,Role> aRoles)
    {
        // If admin, has access.
        if (aUser.getIsAdmin())
        {
            return true;
        }

        // Check access for role
        boolean roleAccess=checkUpdateAccessToRole(aRequest, aUser, aUserShift.getRoleId(), aRoles);
        if (!roleAccess)
        {
            return false;
        }

        // Only admins can change user shifts of others.
        if (!aUser.getIsAdmin() && aUser.getKey().getId()!=aUserShift.getUserId())
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ADMIN_ACCESS_REQUIRED);
            return false;
        }

        return true;
    }

    /**
     * Check that a user has update access to a role.  Create edit if no access.
     *
     * @param aRequest The request
     * @param aUser User
     * @param aRoleId Role Id
     * @param aRoles roles
     * @return a boolean indicting if the user has update access to a role
     *
     * @since 1.0
     */
    public static boolean checkUpdateAccessToRole(HttpServletRequest aRequest, User aUser, long aRoleId, Map<Long,Role> aRoles)
    {
        // If admin, has access.
        if (aUser.getIsAdmin())
        {
            return true;
        }

        // Check access for role
        Role role=null;
        Long roleIdLong=new Long(aRoleId);
        if (aRoles.containsKey(roleIdLong))
        {
            role=(Role)aRoles.get(roleIdLong);
        }

        // If not an admin and roll is not found, or no access, create error.
        if (!aUser.getIsAdmin() && (role==null || !role.getAllUserUpdateAccess()))
        {
            RequestUtils.addEditUsingKey(aRequest,EditMessages.ADMIN_OR_ROLE_ACCESS_REQUIRED);
            return false;
        }

        return true;
    }
}
