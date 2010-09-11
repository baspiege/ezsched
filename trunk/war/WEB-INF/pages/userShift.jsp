<%-- This JSP has the HTML for the user shift page. --%>
<%@page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page language="java"%>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="java.util.TimeZone" %>
<%@ page import="sched.data.RoleUtils" %>
<%@ page import="sched.data.UserShiftAddUpdate" %>
<%@ page import="sched.data.UserShiftDelete" %>
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
<%@ page import="sched.utils.StringUtils" %>
<%
    // TODO Remove...
    // If cancel, forward right away.
    String action=RequestUtils.getAlphaInput(request,"action","Action",false);
    if (action!=null && action.equals("Return to Schedule"))
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/WEB-INF/pages/sched.jsp"/>
        <%
    }

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
    // This is needed when determing if the user is eligible for what type of page.
    User currentUser=RequestUtils.getCurrentUser(request);

    // Get roles (needed for UserShiftGetSingle)
    // This is needed when determing if the user is eligible for what type of page.
    Map<Long,Role> roles=RequestUtils.getRoles(request);

    // Get shift templates (needed for UserShiftGetSingle)
    Map<Long,ShiftTemplate> shiftTemplates=RequestUtils.getShiftTemplates(request);

    // Get users
    Map<Long, User> users=RequestUtils.getUsers(request);	

    // There are two ways to come to this page.
    // 1.) Without a shift specified.  In this case, the user can only add.
    // 2.) With a shift specified.  In this case, the shift can be updated or forwarded to the view page.
    
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));        
    String pageTitle=null;
    boolean fromSched=RequestUtils.getBooleanInput(request,"fromSched","From Schedule",false);

    // Type
    int type=0;
    int ADD=1;
    int EDIT=2;

    // If shift Id, then either updating or viewing.
    Long userShiftId=RequestUtils.getNumericInput(request,"s",bundle.getString("shiftIdLabel"),false);
    UserShift userShift=null;
    if (userShiftId!=null)
    {
        // Get single shift.
        request.setAttribute("userShiftId",userShiftId);
        new UserShiftGetSingle().execute(request, roles, shiftTemplates, users);

        // If shift is null, forward to sched page.
        userShift=(UserShift)request.getAttribute("userShift");
        if (userShift==null)
        {
            RequestUtils.resetAction(request);
            RequestUtils.removeEdits(request);
            %>
            <jsp:forward page="/sched.jsp"/>
            <%
        }

        // If an admin or self and role permits, then editing.
        Role role=null;
        long roleId=userShift.getRoleId();
        if (roles.containsKey(new Long(roleId)))
        {
            role=(Role)roles.get(new Long(roleId));
        }
        // If an admin, or self and role permits, then editing.
        if (currentUser.getIsAdmin() || (currentUser.getKey().getId()==userShift.getUserId() && role!=null && role.getAllUserUpdateAccess()))
        {
            type=EDIT;
            pageTitle=bundle.getString("editShiftLabel");
        }
        else
        {
            // Forward to view page.
            %>
            <jsp:forward page="/userShift_view.jsp"/>
            <%
        }
    }
    else
    {
        // If not allowed, forward to sched page.
        if (!currentUser.getIsAdmin() && !RoleUtils.isRoleThatAllUsersCanUpdate(roles))
        {
            RequestUtils.resetAction(request);
            RequestUtils.removeEdits(request);
            %>
            <jsp:forward page="/sched.jsp"/>
            <%
        }

        type=ADD;
        pageTitle=bundle.getString("addShiftLabel");
    }

    // If admin, get user list.
    if (currentUser.getIsAdmin())
    {
        // Get users
        // Add message if there are no users.
        // This will never occur but check anyway.
        if (users!=null && users.isEmpty())
        {                       
            RequestUtils.addEdit(request,bundle.getString("addUserBeforeAddingShiftEdit"));
        }
    }

    // Defaults
    Long userIdRequest=null;
    boolean usesCustomStartTime=false;
    boolean usesCustomDuration=false;
    Long roleId=null;
    Long shiftTemplateId=null;
    Long startYear=null;
    Long startMonth=null;
    Long startDay=null;
    Long shiftRepetition=null;
    Long daysBetweenRepetitions=null;
    Long startHour=null;
    Long startMinute=null;
    String startAmPm=null;
    String note=null;

    //userShift=(UserShift)request.getAttribute("userShift");
    if (userShift!=null && (action==null || action.length()==0))
    {
        // User Id
        if (currentUser.getIsAdmin())
        {
            userIdRequest=new Long(userShift.getUserId());
        }
        else
        {
            userIdRequest=new Long(currentUser.getKey().getId());
        }
        request.setAttribute("userId",userIdRequest);

        // Role
        roleId=new Long(userShift.getRoleId());
        request.setAttribute("roleId",roleId);

        // Shift Template
        shiftTemplateId=new Long(userShift.getShiftTemplateId());
        request.setAttribute("shiftTemplateId",shiftTemplateId);

        // Get shift template for comparison of default time and duration
        ShiftTemplate shiftTemplate=(ShiftTemplate)shiftTemplates.get(new Long(shiftTemplateId));		

        // Set date
        Date startShift=userShift.getStartDate();
        Calendar startShiftCalendar = DateUtils.getCalendar(request);
        startShiftCalendar.setTime( startShift );

        // Year
        startYear=new Long(startShiftCalendar.get(Calendar.YEAR));
        request.setAttribute("startYear",startYear);

        // Month
        startMonth=new Long(startShiftCalendar.get(Calendar.MONTH)+1);
        request.setAttribute("startMonth",startMonth);

        // Day
        startDay=new Long(startShiftCalendar.get(Calendar.DATE));
        request.setAttribute("startDay",startDay);

        // Hour
        startHour=new Long(startShiftCalendar.get(Calendar.HOUR));
        if (startHour==0)
        {
            startHour=12L;
        }
        request.setAttribute("startHour",startHour);		

        // Minute
        startMinute=new Long(startShiftCalendar.get(Calendar.MINUTE));		
        request.setAttribute("startMinute",startMinute);

        int amPm=startShiftCalendar.get(Calendar.AM_PM);
        if (amPm==Calendar.PM)
        {
            request.setAttribute("startAmPm",DateUtils.PM);
        }
        else
        {
            request.setAttribute("startAmPm",DateUtils.AM);
        }

        // If hour and minute do not equal default, check box.
        int hourOfDay=startShiftCalendar.get(Calendar.HOUR_OF_DAY);
        int startTime=(hourOfDay*60) + startMinute.intValue();
        if (shiftTemplate==null || shiftTemplate.getStartTime()!=startTime)
        {
            usesCustomStartTime=true;
            request.setAttribute("usesCustomStartTime",new Boolean(true));
        }

        // If duration matches default, check box and update field.
        int userShiftDuration=userShift.getDuration();

        long durationHour=0;
        long durationMinute=0;		

        if (shiftTemplate==null || shiftTemplate.getDuration()!=userShiftDuration)
        {
            usesCustomDuration=true;
            request.setAttribute("usesCustomDuration",new Boolean(true));

            if (userShiftDuration!=0)
            {
                durationHour=userShiftDuration/60;
                durationMinute=userShiftDuration%60;
            }
        }
        else
        {
            if (shiftTemplate.getDuration()!=0)
            {
                durationHour=shiftTemplate.getDuration()/60;
                durationMinute=shiftTemplate.getDuration()%60;
            }
        }

        request.setAttribute("durationHour",new Long(durationHour));
        request.setAttribute("durationMinute",new Long(durationMinute));				

        note=userShift.getNote();		
    }
    else
    {
        // Uses custom times.
        usesCustomStartTime=RequestUtils.getBooleanInput(request,"usesCustomStartTime",bundle.getString("overrideStartTimeLabel"),false);
        usesCustomDuration=RequestUtils.getBooleanInput(request,"usesCustomDuration",bundle.getString("overrideDurationLabel"),false);

        if (currentUser.getIsAdmin())
        {
            userIdRequest=RequestUtils.getNumericInput(request,"u",bundle.getString("userIdLabel"),false);
            if (userIdRequest==null)
            {
                userIdRequest=RequestUtils.getNumericInput(request,"userId",bundle.getString("userIdLabel"),false);
            }
            else
            {
                request.setAttribute("userId",userIdRequest);
            }
        }
        else
        {
            userIdRequest=new Long(currentUser.getKey().getId());
        }

        // Check date from schedule.
        String startDateString=RequestUtils.getDateInput(request,"d",bundle.getString("startDateLabel"),false);
        if (startDateString!=null)
        {
            fromSched=true;

            // Split into 3 parts
            String[] dateParts=startDateString.split("-");

            startYear=new Long((String)dateParts[0]);
            startMonth=new Long((String)dateParts[1]);
            startDay=new Long((String)dateParts[2]);

            request.setAttribute("startYear",startYear);
            request.setAttribute("startMonth",startMonth);
            request.setAttribute("startDay",startDay);
        }
        // Date from this page.
        else
        {
            startYear=RequestUtils.getNumericInput(request,"startYear",bundle.getString("startYearLabel"),false);
            startMonth=RequestUtils.getNumericInput(request,"startMonth",bundle.getString("startMonthLabel"),false,0,13);
            startDay=RequestUtils.getNumericInput(request,"startDay",bundle.getString("startDayLabel"),false,0,32);
        }

        // Repeats
        shiftRepetition=RequestUtils.getNumericInput(request,"shiftRepetition",bundle.getString("repeatsLabel"),false,0,32);
        daysBetweenRepetitions=RequestUtils.getNumericInput(request,"shiftDaysBetweenRepetitions",bundle.getString("daysBetweenRepetitionsLabel"),false,0,32);

        // Note
        note=RequestUtils.getAlphaInput(request,"note",bundle.getString("noteLabel"),false);		
    }

    // Process based on action
    if (!StringUtils.isEmpty(action) && !RequestUtils.isForwarded(request))
    {   
        Long token=RequestUtils.getNumericInput(request,"csrfToken","CSRF Token",true);
        if (!SessionUtils.isCSRFTokenValid(request,token))
        {
            %>
            <jsp:forward page="/logonForward.jsp"/>
            <%
        }
    
        if ((type==ADD && action.equals(bundle.getString("addLabel"))) || (type==EDIT && action.equals(bundle.getString("updateLabel"))))
        {		
            if (currentUser.getIsAdmin() && userIdRequest==null)
            {
                String message=bundle.getString("userIdLabel") + ": " + bundle.getString("fieldRequiredEdit");                
                RequestUtils.addEdit(request,message);
            }

            if (startYear==null)
            {
                String message=bundle.getString("startYearLabel") + ": " + bundle.getString("fieldRequiredEdit");                
                RequestUtils.addEdit(request,message);            
            }

            if (startMonth==null)
            {
                String message=bundle.getString("startMonthLabel") + ": " + bundle.getString("fieldRequiredEdit");                
                RequestUtils.addEdit(request,message);            
            }

            if (startDay==null)
            {
                String message=bundle.getString("startDayLabel") + ": " + bundle.getString("fieldRequiredEdit");                
                RequestUtils.addEdit(request,message);            
            }

            // Required
            shiftTemplateId=RequestUtils.getNumericInput(request,"shiftTemplateId",bundle.getString("shiftTemplateIdLabel"),true);
            roleId=RequestUtils.getNumericInput(request,"roleId",bundle.getString("roleIdLabel"),true);

            // Custom Start Time
            if (usesCustomStartTime || shiftTemplateId.longValue()==ShiftTemplate.NO_SHIFT)
            {
                // Start
                startHour=RequestUtils.getNumericInput(request,"startHour",bundle.getString("startHourLabel"),true,0,13);
                startMinute=RequestUtils.getNumericInput(request,"startMinute",bundle.getString("startMinuteLabel"),true,-1,60);
                startAmPm=RequestUtils.getAmPmInput(request,"startAmPm",bundle.getString("startAmPmLabel"),true);
            }

            // Custom Duration
            if (usesCustomDuration || shiftTemplateId.longValue()==ShiftTemplate.NO_SHIFT)
            {
                // Duration
                Long durationHour=RequestUtils.getNumericInput(request,"durationHour",bundle.getString("durationHoursLabel"),true);
                Long durationMinute=RequestUtils.getNumericInput(request,"durationMinute",bundle.getString("durationMinutesLabel"),true);
            }

            if (!RequestUtils.hasEdits(request))
            {
                new UserShiftAddUpdate().execute(request,roles,shiftTemplates,users);
            }

            // If no edits or from the schedule, forward to the schedule.
            if (!RequestUtils.hasEdits(request) && (type==EDIT || fromSched))
            {				
                RequestUtils.resetAction(request);			
                %>
                <jsp:forward page="/sched.jsp"/>
                <%
            }
        }
        else if (type==EDIT && action.equals(bundle.getString("deleteLabel")))
        {
            new UserShiftDelete().execute(request,roles,shiftTemplates,users);

            // If successful, go back to schedule.
            if (!RequestUtils.hasEdits(request))
            {
                RequestUtils.resetAction(request);

                // Route to role page.
                %>
                <jsp:forward page="/sched.jsp"/>
                <%
            }
        }
    }
    else if (type==ADD)
    {
        // Not required
        shiftTemplateId=RequestUtils.getNumericInput(request,"shiftTemplateId",bundle.getString("shiftTemplateIdLabel"),false);
        roleId=RequestUtils.getNumericInput(request,"roleId",bundle.getString("roleIdLabel"),false);

        User user=null;

        // If no role Id, get default role Id if there is a user.
        if (!RequestUtils.hasEdits(request) && roleId==null && userIdRequest!=null)
        {
            long defaultRoleId=Role.NO_ROLE;        
        
            if (currentUser.getIsAdmin())
            {
                if (users.containsKey(userIdRequest))
                {
                    user=users.get(userIdRequest);
                }

                if (user!=null)
                {
                    defaultRoleId=user.getDefaultRoleId();
                }
            }
            else
            {
                defaultRoleId=currentUser.getDefaultRoleId();
            }
            
            if (defaultRoleId!=Role.NO_ROLE)
            {            
                // Set roleId into the request so it's selected in roleSelectOptions component.
                request.setAttribute("roleId",defaultRoleId);          
            }
        }

        // If no shift teamplte Id, get default shift template Id if there is a user.
        if (!RequestUtils.hasEdits(request) && shiftTemplateId==null && userIdRequest!=null)
        {
            long defaultShiftTemplateId=ShiftTemplate.NO_SHIFT;

            if (currentUser.getIsAdmin())
            {
                if (users.containsKey(userIdRequest))
                {
                    user=users.get(userIdRequest);
                }

                if (user!=null)
                {
                    defaultShiftTemplateId=user.getDefaultShiftTemplateId();
                }
            }
            else
            {
                defaultShiftTemplateId=currentUser.getDefaultShiftTemplateId();
            }

            if (defaultShiftTemplateId!=ShiftTemplate.NO_SHIFT)
            {
                // Set shiftTemplateId into the request so it's selected in shiftTemplateSelectOptions component.
                request.setAttribute("shiftTemplateId",defaultShiftTemplateId);
            }
        }		
    }
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title>
<%
    out.write( HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request)) );
    out.write( " - ");
    out.write( pageTitle );
%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<script type="text/javascript">//<![CDATA[
function highlightOverride(checkboxId, hourId, minuteId)
{
    var checkbox=document.getElementById(checkboxId);
    var hour=document.getElementById(hourId);
    var minute=document.getElementById(minuteId);

    if (checkbox && hour && minute){
        if (checkbox.checked){
            hour.disabled=false;
            hour.style.backgroundColor="#ffffff";
            minute.disabled=false;
            minute.style.backgroundColor="#ffffff";
        }else{
            hour.disabled=true;
            hour.style.backgroundColor="#c0c0c0";
            minute.disabled=true;
            minute.style.backgroundColor="#c0c0c0";
        }
    }
}
//]]></script>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body onload="highlightOverride('usesCustomDuration','durationHour','durationMinute');highlightOverride('usesCustomStartTime','startHour','startMinute'); ">
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

  <form id="shift" method="post" action="userShift.jsp" autocomplete="off">
    <fieldset class="action">
      <legend><b><%= pageTitle %></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

      <table>
        <tr>
<% if (currentUser.getIsAdmin())
{%>
          <td><label for="userId"><%= bundle.getString("userLabel") %></label></td>
          <td><select name="userId" title="<%= bundle.getString("usersLabel") %>" id="userId">
<jsp:include page="/WEB-INF/pages/components/userSelectOptions.jsp"/>
          </select></td></tr>
<%}%>
        <tr>
          <td><label for="roleId"><%= bundle.getString("roleLabel") %></label></td>
          <td><select name="roleId" title="<%= bundle.getString("rolesLabel") %>" id="roleId">
<% request.setAttribute("displayAllRoles",new Boolean(false)); %><jsp:include page="/WEB-INF/pages/components/roleSelectOptions.jsp"/>
            </select>
          </td>
        </tr>
        <tr>
          <td><%= bundle.getString("startDateLabel") %></td>
          <td>
<% request.setAttribute("shiftDatePrefix","start"); %><jsp:include page="/WEB-INF/pages/components/dateSelect.jsp"/></td>
        </tr>

<%
    boolean noShiftTemplates=(shiftTemplates==null || shiftTemplates.isEmpty());
%>
        <tr>
          <td><label for="shiftTemplateId"><%= bundle.getString("shiftTemplateLabel") %><%if (!noShiftTemplates){%><sup><small>*</small></sup><%}%></label></td>
          <td>
            <select name="shiftTemplateId" title="<%= bundle.getString("shiftTemplatesLabel") %>" id="shiftTemplateId">
<% request.setAttribute("showShiftTemplateDescOnly",new Boolean(false)); %>			
<jsp:include page="/WEB-INF/pages/components/shiftTemplateSelectOptions.jsp"/>
            </select>
          </td>
        </tr>

        <tr>
          <td>

<% if (!noShiftTemplates)
{
    out.write("<input type=\"checkbox\" name=\"usesCustomStartTime\" id=\"usesCustomStartTime\" value=\"true\"");

    if (usesCustomStartTime)
    {
        out.write("checked=\"checked\"");
    }
    out.write(" onclick=\"highlightOverride('usesCustomStartTime','startHour','startMinute');\"");
    out.write(">");
    out.write("<label for=\"usesCustomStartTime\">");
    out.write(bundle.getString("overrideStartTimeLabel") );
    out.write("</label>");    
}
else
{
    out.write(bundle.getString("startTimeLabel") );
}
%>
</td>
        <td><% request.setAttribute("shiftDatePrefix","start"); %><jsp:include page="/WEB-INF/pages/components/timeSelect.jsp"/></td>
        </tr>

        <tr>
          <td>
<% if (!noShiftTemplates)
{
    out.write("<input type=\"checkbox\" name=\"usesCustomDuration\" id=\"usesCustomDuration\" value=\"true\"");

    if (usesCustomDuration)
    {
        out.write("checked=\"checked\"");
    }
    out.write(" onclick=\"highlightOverride('usesCustomDuration','durationHour','durationMinute');\"");
    out.write(">");
    out.write("<label for=\"usesCustomDuration\">");
    out.write( bundle.getString("overrideDurationLabel") );
    out.write("</label>");    
}
else
{
    out.write( bundle.getString("durationLabel") );
}       
%>
</td>
          <td><% request.setAttribute("shiftDatePrefix","duration"); %><jsp:include page="/WEB-INF/pages/components/durationSelect.jsp"/></td>
        </tr>

<% if (type==ADD)
{%>
       <tr>
          <td><%= bundle.getString("repeatsLabel") %></td>
          <td><% request.setAttribute("shiftDatePrefix","shift"); %><jsp:include page="/WEB-INF/pages/components/repetitionSelect.jsp"/></td>
       </tr>
<%}%>
        <tr><td><label for="desc"><%= bundle.getString("noteLabel") %></label></td><td><input type="text" name="note" value="<%= HtmlUtils.escapeChars(note) %>" id="note" title="<%= bundle.getString("noteLabel") %>" maxlength="100"/></td></tr>
<%
    if (type==EDIT && userShift!=null)
    {
        // Last updated by	
        User lastUpdateUser=null;
        Long lastUpdateUserIdLong=new Long(userShift.getLastUpdateUserId());
        if (users.containsKey(lastUpdateUserIdLong))
        {
            lastUpdateUser=users.get(lastUpdateUserIdLong);
        }		

        String lastUpdateUserName;	
        if (lastUpdateUser!=null)
        {
            lastUpdateUserName=DisplayUtils.formatName(lastUpdateUser.getFirstName(),lastUpdateUser.getLastName(),true);	
        }
        else
        {
            lastUpdateUserName="N/A";
        }
        out.write( "<tr><td>" + bundle.getString("lastUpdatedByLabel") + "</td><td>" );
        out.write(HtmlUtils.escapeChars(lastUpdateUserName));
        out.write( "</td></tr>" );

        // Last updated time
        Locale locale=SessionUtils.getLocale(request);        
        SimpleDateFormat displayDateTime=new SimpleDateFormat("yyyy MMM dd EEE h:mm aa",locale);
        TimeZone timeZone=RequestUtils.getCurrentStore(request).getTimeZone();		
        displayDateTime.setTimeZone(timeZone);		
        out.write( "<tr><td>" + bundle.getString("lastUpdatedTimeLabel") + "</td><td>" );
        out.write(HtmlUtils.escapeChars(displayDateTime.format(userShift.getLastUpdateTime())));
        out.write( "</td></tr>" );
    }
%>
      </table>

<%
    if (!noShiftTemplates)
    {
        out.write("<p><sup><small>*</small></sup>" + bundle.getString("overrideFootnote") + "</p>");
    }
    else
    {
        out.write("<br/>");
    }

    // If adding, use add button.
    if (type==ADD)
    {
        out.write("<input type=\"hidden\" name=\"fromSched\" value=\"" + fromSched + "\"></input>");	
        out.write("<input type=\"submit\" name=\"action\" value=\"" + bundle.getString("addLabel") + "\"></input>");
    }
    // If editing, use update and delete.
    if (type==EDIT)
    {
        out.write("<input type=\"hidden\" name=\"s\" value=\"" + userShiftId.toString() + "\"></input>");
        out.write("<input type=\"submit\" name=\"action\" value=\"" + bundle.getString("updateLabel") + "\"></input>");
        out.write(" <input type=\"submit\" name=\"action\" value=\"" + bundle.getString("deleteLabel") + "\"></input>");
        //out.write("</fieldset></form>");
        //out.write("<form type=\"submit\" method=\"get\" action=\"userShiftRequestSwitch.jsp\" > <input type=\"submit\" name=\"action\" value=\"" + bundle.getString("tradeLabel") + "\"></input></form>");
        out.write(" <a href=\"userShiftRequestSwitch.jsp?s=" + userShiftId.toString() + "\">" + bundle.getString("tradeLabel") + "</a>");
    }
%>
      <input type="hidden" name="csrfToken" value="<%= SessionUtils.getCSRFToken(request) %>"/>
    </fieldset>
  </form>

    <%
    List userShiftAdditions=(List)request.getAttribute("userShifts");
    if (userShiftAdditions!=null && userShiftAdditions.size()>0)
    {
        out.write("<h1>" + bundle.getString("shiftsAddedLabel"));

        /*
        String userName=null;
        if (users.containsKey(userIdRequest))
        {
            User user=users.get(userIdRequest);
            userName=HtmlUtils.escapeChars(DisplayUtils.formatName(user.getFirstName(),user.getLastName(),false));					
        }		
        else
        {
            userName="";
        }

        out.write(userName);
        */
        out.write("</h1>");		

        %>
        <jsp:include page="/WEB-INF/pages/components/userShiftTable.jsp"/>
        <%
    }
    %>


<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>