<%-- This JSP creates a list of role select options. --%>
<%@ page language="java"%>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));

    boolean displayAllRoles=((Boolean)request.getAttribute("displayAllRoles")).booleanValue();

    boolean isAdmin=false;
    User currentUser=RequestUtils.getCurrentUser(request);
    if (currentUser!=null)
    {
        // If admin
        if (currentUser.getIsAdmin())
        {
            isAdmin=true;
        }
    }

    Map<Long,Role> roles=RequestUtils.getRoles(request);
    if (roles!=null && !roles.isEmpty())
    {
        Long roleIdSelect=(Long)request.getAttribute("roleId");
        if (roleIdSelect==null)
        {
            roleIdSelect=new Long(Role.ALL_ROLES);
        }

        Iterator iter = roles.entrySet()
                .iterator();

        while (iter.hasNext())
        {
            Entry entry = (Entry)iter.next();
            Long roleId=(Long)entry.getKey();
            Role role=(Role)entry.getValue();

            if (displayAllRoles || isAdmin || role.getAllUserUpdateAccess())
            {
                out.write("<option");

                // Selected
                if (roleIdSelect.equals(roleId))
                {
                    out.write(" selected=\"true\"");
                }

                out.write(" value=\"");
                out.write( roleId.toString() );
                out.write("\">");
                out.write( HtmlUtils.escapeChars(role.getDesc()) );
                out.write("</option>");
            }
        }

        if (displayAllRoles || isAdmin)
        {
            out.write("<option value=\"" + Role.NO_ROLE + "\"");

            // No Role Selected
            if (roleIdSelect.equals(new Long(Role.NO_ROLE)))
            {
                out.write(" selected=\"true\"");
            }

            out.write("\">" + bundle.getString("noRoleLabel")+ "</option>");
        }
    }
    else
    {
        out.write("<option value=\"" + Role.NO_ROLE + "\">" + bundle.getString("noRolesAddedLabel") + "</option>");
    }
%>