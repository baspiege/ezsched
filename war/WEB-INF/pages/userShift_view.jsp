<%-- This JSP has the HTML for the user shift page. --%>
<%@ page language="java"%>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="java.util.TimeZone" %>
<%@ page import="sched.data.RoleUtils" %>
<%@ page import="sched.data.UserGetSingle" %>
<%@ page import="sched.data.UserShiftGetSingle" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.data.model.UserShift" %>
<%@ page import="sched.utils.DateUtils" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%    
    // Set the current store into the request.
    SessionUtils.setCurrentStoreIntoRequest(request);

    // Verify user is logged on.
    // Verify user has access to the store.
    if (!SessionUtils.isLoggedOn(request)
        || !RequestUtils.isCurrentUserInStore(request))
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/logonForward.jsp"/>
        <%
    }
    
    // Get current user.
    // This is needed when determing if the user is eligible for trading.
    User currentUser=RequestUtils.getCurrentUser(request);

    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));        
    
    // Get shift Id
    Long userShiftId=RequestUtils.getNumericInput(request,"s",bundle.getString("shiftIdLabel"),false);
    if (userShiftId==null)
    {
        // No shift. 
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/sched.jsp"/>
        <%
    }

    // Get roles (needed for UserShiftGetSingle)
    Map<Long,Role> roles=RequestUtils.getRoles(request);

    // Get shift templates (needed for UserShiftGetSingle)
    Map<Long,ShiftTemplate> shiftTemplates=RequestUtils.getShiftTemplates(request);

    // Get users
    Map<Long, User> users=RequestUtils.getUsers(request);	    
    
    // Get shift.
    // Set userShiftId into request because UserShiftGetSingle expects it.
    request.setAttribute("userShiftId",userShiftId);
    new UserShiftGetSingle().execute(request, roles, shiftTemplates, users);

    // If shift is null, forward to sched page.
    UserShift userShift=(UserShift)request.getAttribute("userShift");
    if (userShift==null)
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/sched.jsp"/>
        <%
    }

    // Get user (set by UserShiftGetSingle)
    User user=(User)request.getAttribute("user");
    if (user==null)
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/sched.jsp"/>
        <%
    }

%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title>
<%
    out.write( HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request)) );
    out.write( " - ");
    out.write( bundle.getString("viewShiftLabel") );
%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

<h1><%= bundle.getString("viewShiftLabel") %></h1>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

  <table border="1">

<%
    Locale locale=SessionUtils.getLocale(request);
    SimpleDateFormat displayDateTime=new SimpleDateFormat("yyyy MMM dd EEE h:mm aa",locale);		
    displayDateTime.setTimeZone(RequestUtils.getCurrentStore(request).getTimeZone());

    // User name
    out.write( "<tr><th>" + bundle.getString("userLabel") + "</th><td>" );
    String name=HtmlUtils.escapeChars(DisplayUtils.formatName(user.getFirstName(),user.getLastName(),true));
    if (name.length()==0)
    {
        name="&nbsp";
    }
    out.write( name );
    out.write( "</td></tr>" );

    // Role
    out.write( "<tr><th>" + bundle.getString("roleLabel")+ "</th><td>" );
    Role role=(Role)roles.get(new Long(userShift.getRoleId()));
    if (role!=null)
    {
        out.write(HtmlUtils.escapeChars(role.getDesc()));
    }
    else
    {
        out.write( bundle.getString("noRoleLabel") );
    }
    out.write( "</td></tr>" );

    // Role
    out.write( "<tr><th>" + bundle.getString("shiftNameLabel") + "</th><td>" );
    ShiftTemplate shiftTemplate=(ShiftTemplate)shiftTemplates.get(new Long(userShift.getShiftTemplateId()));
    if (shiftTemplate!=null)
    {
        out.write(HtmlUtils.escapeChars(shiftTemplate.getDesc()));
    }
    else
    {
        out.write( bundle.getString("noShiftNameLabel") );
    }
    out.write( "</td></tr>" );

    // Start Date
    Date startDate=(Date)userShift.getStartDate();
    out.write( "<tr><th>" + bundle.getString("startTimeLabel") + "</th><td>" );
    out.write(HtmlUtils.escapeChars(displayDateTime.format(startDate)));
    out.write( "</td></tr>" );

    // End Date
    Date endDate=DateUtils.getEndDate(userShift.getStartDate(),userShift.getDuration());
    out.write( "<tr><th>" + bundle.getString("endTimeLabel") + "</th><td>" );
    out.write(HtmlUtils.escapeChars(displayDateTime.format(endDate)));
    out.write( "</td></tr>" );

    // Duration
    out.write( "<tr><th>" + bundle.getString("durationLabel") + "</th><td>" );
    out.write(HtmlUtils.escapeChars(DisplayUtils.formatDuration(userShift.getDuration())));
    out.write( "</td></tr>" );

    // Note
    String note=userShift.getNote();
    if (note==null || note.length()==0)
    {
        note="&nbsp;";
    }
    else
    {
        note=HtmlUtils.escapeChars(note);
    }
    out.write( "<tr><th>" + bundle.getString("noteLabel") + "</th><td>" );
    out.write(note);
    out.write( "</td></tr>" );

    // Last updated by
    request.setAttribute("user",null);	
    request.setAttribute("userId",new Long(userShift.getLastUpdateUserId()));	
    new UserGetSingle().execute(request);	 
    User lastUpdateUser=(User)request.getAttribute("user");
    String lastUpdateUserName;	
    if (lastUpdateUser!=null)
    {
        lastUpdateUserName=DisplayUtils.formatName(lastUpdateUser.getFirstName(),lastUpdateUser.getLastName(),true);	
    }
    else
    {
        lastUpdateUserName="N/A";
    }
    
    out.write( "<tr><th>" + bundle.getString("lastUpdatedByLabel") + "</th><td>" );
    out.write(HtmlUtils.escapeChars(lastUpdateUserName));
    out.write( "</td></tr>" );

    // Last updated time
    out.write( "<tr><th>" + bundle.getString("lastUpdatedTimeLabel") + "</th><td>" );
    out.write(HtmlUtils.escapeChars(displayDateTime.format(userShift.getLastUpdateTime())));
    out.write( "</td></tr>" );
    
    
%>
  </table>
  <p>
  <%
        // Button
        if (currentUser.getKey().getId()==userShift.getUserId())
        {
            out.write("<form id=\"trade\" method=\"get\" action=\"userShiftRequestSwitch.jsp\" autocomplete=\"off\">");
            out.write("<input type=\"hidden\" name=\"s\" value=\"" + userShiftId.toString() + "\"></input>");
            out.write("<input type=\"hidden\" name=\"csrfToken\" value=\"" + SessionUtils.getCSRFToken(request) + "\"></input>");
            out.write("<input type=\"submit\" name=\"action\" value=\"" + bundle.getString("tradeLabel") + "\"></input>");
            out.write("</form>");      
        }
        
        // Link - Not used because confusing with link in navigation
        //out.write(" <a href=\"userShiftRequestSwitch.jsp?s=" + userShiftId.toString() + "\">" + bundle.getString("tradeLabel") + "</a>");
  %>
  </p>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>