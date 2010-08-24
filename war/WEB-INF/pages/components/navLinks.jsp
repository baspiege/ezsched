<%-- This JSP creates the navigation links for a logged on user. --%>
<%@ page language="java"%>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.data.RoleUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%
    // Get UserService for log off URL.
    UserService userServiceNavLabel = UserServiceFactory.getUserService();

    boolean showAdd=false;
    boolean isAdmin=false;
	boolean isUserForStore=false;
    User currentUser=RequestUtils.getCurrentUser(request);
    if (currentUser!=null)
    {
		isUserForStore=true;

        // If admin
        if (currentUser.getIsAdmin())
        {
            showAdd=true;
            isAdmin=true;
        }
        // Check roles
        else
        {
			Map<Long,Role> roles=RequestUtils.getRoles(request);
            showAdd=RoleUtils.isRoleThatAllUsersCanUpdate(roles);
        }
    }

%>
<div style="float:left;">
<p>
<%
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));

	if (isUserForStore)
	{
        // Trades
        out.write("<a href=\"userShiftRequestSwitch.jsp\">");
        out.write(bundle.getString("tradesLabel"));
        out.write("</a> | ");

        // Schedule
        out.write("<a href=\"sched.jsp\">");
        out.write(bundle.getString("scheduleLabel"));
        out.write("</a>");
	}
    if (showAdd)
    {
        // Add Shift
        out.write(" | <a href=\"userShift.jsp\">");
        out.write(bundle.getString("addShiftLabel"));
        out.write("</a>");
    }
    if (isAdmin)
    {
        // Shift Tempaltes
        out.write(" | <a href=\"shiftTemplate.jsp\">");
        out.write(bundle.getString("shiftTemplatesLabel"));

        // Role
        out.write("</a> | <a href=\"role.jsp\">");
        out.write(bundle.getString("rolesLabel"));
        out.write("</a>");
    }
	if (isUserForStore)
	{
		out.write(" | <a href=\"user.jsp\">");

		if (isAdmin)
		{
			out.write(bundle.getString("usersLabel"));
		}
		else
		{
			out.write(bundle.getString("userLabel"));
		}

		// Put | here as there will always be Stores after this link.
		out.write("</a> | ");
	}

    // Set query string.  Use opposite (en vs es).
    String locale=SessionUtils.getLocaleString(request);
    String queryString="";
    if (locale==null || locale.equals("en"))
    {
        queryString="es";
    }
    else
    {
       queryString="en";
    }

%>
<a href="store.jsp"><%= bundle.getString("storesLabel")%></a></p>
</div>
<div style="float:right;">
<p><a href="lang.jsp?locale=<%= queryString %>"><%= bundle.getString("langLabel")%></a> | <a href="about.jsp"><%= bundle.getString("aboutLabel")%></a></a> | <a href="help.jsp"><%= bundle.getString("helpLabel")%></a> | <a href="contactUs.jsp"><%= bundle.getString("contactUsLabel")%></a> | <a href="<%=userServiceNavLabel.createLogoutURL(RequestUtils.getLogonUri(request,true))%>"><%= bundle.getString("logOffLabel")%></a></p>
</div>
<div style="clear:both;"/>