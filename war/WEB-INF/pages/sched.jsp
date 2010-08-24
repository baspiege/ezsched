<%-- This JSP has the HTML for the schedule page.--%>
<%@ page language="java"%>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="java.util.TimeZone" %>
<%@ page import="sched.data.RoleUtils" %>
<%@ page import="sched.data.UserShiftCopyMove" %>
<%@ page import="sched.data.UserShiftDelete" %>
<%@ page import="sched.data.UserShiftGetAll" %>
<%@ page import="sched.data.UserShiftMove" %>
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

    // Check if admin
    boolean isAdmin=false;
    User currentUser=RequestUtils.getCurrentUser(request);
    if (currentUser!=null)
    {
        if (currentUser.getIsAdmin())
        {
            isAdmin=true;
        }
    }

    // Get parameters
    Long startYear=null;
    Long startMonth=null;
    Long startDay=null;
    Long displayDays=null;

    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));    
    
    // Only check if not forwarded
    if (!RequestUtils.isForwarded(request))
    {
        startYear=RequestUtils.getNumericInput(request,"startYear",bundle.getString("startYearLabel"),false);
        startMonth=RequestUtils.getNumericInput(request,"startMonth",bundle.getString("startMonthLabel"),false,0,13);
        startDay=RequestUtils.getNumericInput(request,"startDay",bundle.getString("startDayLabel"),false,0,32);
        displayDays=RequestUtils.getNumericInput(request,"displayDays",bundle.getString("daysInDisplayLabel"),false,0,32);
    }
    else
    {
        request.setAttribute("startYear",null);
        request.setAttribute("startMonth",null);
        request.setAttribute("startDay",null);
        request.setAttribute("displayDays",null);
    }

    // Set from session if not specified.
    if (startYear==null && session.getAttribute("startYear")!=null)
    {
        request.setAttribute("startYear",(Long)session.getAttribute("startYear"));
    }
    if (startMonth==null && session.getAttribute("startMonth")!=null)
    {
        request.setAttribute("startMonth",(Long)session.getAttribute("startMonth"));
    }
    if (startDay==null && session.getAttribute("startDay")!=null)
    {
        request.setAttribute("startDay",(Long)session.getAttribute("startDay"));
    }
    if (displayDays==null && session.getAttribute("displayDays")!=null)
    {
        request.setAttribute("displayDays",(Long)session.getAttribute("displayDays"));
    }	

     // Get users.
    Map<Long,User> users=RequestUtils.getUsers(request);

    // Get roles (needed for UserShiftGetAll)
    Map<Long,Role> roles=RequestUtils.getRoles(request);
   
    // Get shift templates (needed for UserShiftGetAll)
    Map<Long,ShiftTemplate> shiftTemplates=RequestUtils.getShiftTemplates(request);
    
    String action=RequestUtils.getAlphaInput(request,"action","Action",false);   
    if (action!=null && action.length()!=0)
    {
        // Delete shifts
        if (action.equals(bundle.getString("deleteLabel")) && !RequestUtils.isForwarded(request))
        {
            List<Long> userShiftIds=RequestUtils.getNumericInputs(request,"s",bundle.getString("shiftIdLabel"),false);
            
            if (!RequestUtils.hasEdits(request))
            {
                for (Long userShiftId: userShiftIds)
                {
                    request.setAttribute("userShiftId",userShiftId);		
                    new UserShiftDelete().execute(request,roles,shiftTemplates,users);                        
                }
            }
        }

        // Copy and move shifts
        else if (action.equals(bundle.getString("copyMoveLabel")) && !RequestUtils.isForwarded(request))
        {            
            List<Long> userShiftIds=RequestUtils.getNumericInputs(request,"s",bundle.getString("shiftIdLabel"),false);
            Long daysToMove=RequestUtils.getNumericInput(request,"daysToMove",bundle.getString("moveDaysLabel"),true);
            request.setAttribute("s",userShiftIds);
            
            if (!RequestUtils.hasEdits(request))
            {
                new UserShiftCopyMove().execute(request,roles,shiftTemplates,users);                        
            }
        }
        
        // Move shift
        else if (action.equals("Move") && !RequestUtils.isForwarded(request))
        {            
            Long shiftIdToMove=RequestUtils.getNumericInput(request,"shiftId",bundle.getString("shiftIdLabel"),true);
            Long userIdTarget=RequestUtils.getNumericInput(request,"userIdMove",bundle.getString("userIdLabel"),true);
            
            // Check date from schedule.
            String startDateString=RequestUtils.getDateInput(request,"dateMove",bundle.getString("startDateLabel"),true);
            if (startDateString!=null)
            {
                // Split into 3 parts
                String[] dateParts=startDateString.split("-");

                startYear=new Long((String)dateParts[0]);
                startMonth=new Long((String)dateParts[1]);
                startDay=new Long((String)dateParts[2]);

                request.setAttribute("startYearMove",startYear);
                request.setAttribute("startMonthMove",startMonth);
                request.setAttribute("startDayMove",startDay);
            }
            
            if (!RequestUtils.hasEdits(request))
            {
                new UserShiftMove().execute(request,roles,shiftTemplates,users);                        
            }
        }
    }        
    
    // User, Roles, Shift Template - Optional
    Long userIdLong=SessionUtils.getFieldAsLongCheckingRequest(request, SessionUtils.USER_ID_DISPLAYED_ON_SCHEDULE, "userId", bundle.getString("userIdLabel"), User.ALL_USERS);
    Long roleIdLong=SessionUtils.getFieldAsLongCheckingRequest(request, SessionUtils.ROLE_ID_DISPLAYED_ON_SCHEDULE, "roleId", bundle.getString("roleIdLabel"), Role.ALL_ROLES);
    Long shiftTemplateIdLong=SessionUtils.getFieldAsLongCheckingRequest(request, SessionUtils.SHIFT_TEMPLATE_ID_DISPLAYED_ON_SCHEDULE, "shiftTemplateId" , bundle.getString("shiftTemplateIdLabel"), ShiftTemplate.ALL_SHIFTS);		

    // Show add?
    boolean showAdd=false;

    //if (!RequestUtils.hasEdits(request))
    //{        
        // Check if role exists.
        if (roleIdLong!=null && roleIdLong.longValue()!=Role.NO_ROLE && roleIdLong.longValue()!=Role.ALL_ROLES && !roles.containsKey(roleIdLong))
        {
            roleIdLong=new Long(Role.ALL_ROLES);
            request.setAttribute("roleId",null);			
        }
        SessionUtils.setRoleIdDisplayedOnSchedule(request,roleIdLong);
        
        // Check if shift templates exist.
        if (shiftTemplateIdLong!=null && shiftTemplateIdLong.longValue()!=ShiftTemplate.NO_SHIFT && shiftTemplateIdLong.longValue()!=ShiftTemplate.ALL_SHIFTS && !shiftTemplates.containsKey(shiftTemplateIdLong))
        {
            shiftTemplateIdLong=new Long(ShiftTemplate.ALL_SHIFTS);
            request.setAttribute("shiftTemplateId",null);			
        }		
        SessionUtils.setShiftTemplateIdDisplayedOnSchedule(request,shiftTemplateIdLong);
        
        // Check if user exists.
        if (userIdLong!=null && userIdLong.longValue()!=User.ALL_USERS && !users.containsKey(userIdLong))
        {
            userIdLong=new Long(User.ALL_USERS);
            request.setAttribute("userId",null);			
        }		
        SessionUtils.setUserIdDisplayedOnSchedule(request,userIdLong);		
        
        if (currentUser!=null)
        {
            // If admin
            if (currentUser.getIsAdmin())
            {
                showAdd=true;
            }
            // Check roles
            else
            {
                showAdd=RoleUtils.isRoleThatAllUsersCanUpdate(roles);
            }
        }        

        // User shifts (4th arg is true because shifts are not sorted by user Id)
        new UserShiftGetAll().execute(request, roles, shiftTemplates, users, true);

        // Set date into session.  Do this after UserShiftGetAll because the dates can be changed.
        session.setAttribute("startYear",request.getAttribute("startYear"));
        session.setAttribute("startMonth",request.getAttribute("startMonth"));
        session.setAttribute("startDay",request.getAttribute("startDay"));
        session.setAttribute("displayDays",request.getAttribute("displayDays"));
    //}

    String title=HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request));
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= title %> <%= bundle.getString("scheduleLabel")%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<%
    out.write("<body onunload=\"saveSchedPos();\"");

    if (!RequestUtils.hasEdits(request))
    {            
        Long scrollX=RequestUtils.getCookieValueNumeric(request,"schedX",0L);
        Long scrollY=RequestUtils.getCookieValueNumeric(request,"schedY",0L);
        
        out.write(" onload=\"window.scrollTo(" + scrollX.toString() + "," + scrollY.toString() + ");");
    }
    out.write("\">");
%>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

  <form name="schedView" method="get" action="sched.jsp" onsubmit="saveSchedPos();">
    <fieldset class="action">
      <legend><b><%= bundle.getString("viewSchedule")%></b></legend>
     
          <select name="userId" title="<%= bundle.getString("usersLabel")%>" id="userId">
            <option value="<%=User.ALL_USERS%>"><%= bundle.getString("allUsersLabel")%></option>
<jsp:include page="/WEB-INF/pages/components/userSelectOptions.jsp"/>
          </select>
          
          <select name="roleId" title="<%= bundle.getString("rolesLabel")%>" id="roleId">
            <option value="<%=Role.ALL_ROLES%>"><%= bundle.getString("allRolesLabel")%></option>
<% request.setAttribute("displayAllRoles",new Boolean(true)); %><jsp:include page="/WEB-INF/pages/components/roleSelectOptions.jsp"/>
            </select>
                      
            <select name="shiftTemplateId" title="<%= bundle.getString("shiftNamesLabel")%>" id="shiftTemplateId">
            <option value="<%=ShiftTemplate.ALL_SHIFTS%>"><%= bundle.getString("allShiftsLabel")%></option>
<% request.setAttribute("showShiftTemplateDescOnly",new Boolean(true)); %>
<jsp:include page="/WEB-INF/pages/components/shiftTemplateSelectOptions.jsp"/>
            </select>
          
        

          <%= bundle.getString("startDateLabel")%>
          
    <%
    request.setAttribute("shiftDatePrefix","start");
    request.setAttribute("shiftDateTime","false");
    %><jsp:include page="/WEB-INF/pages/components/dateSelect.jsp"/>

          <label for="days"><%= bundle.getString("daysInDisplayLabel")%></label>
          

<%
    // Display Days
    out.write("<input type=\"text\" name=\"");
    out.write("displayDays\" title=\"");
    out.write(bundle.getString("daysInDisplayLabel"));
    out.write("\" value=\"");

    Long displayDaysSelect=(Long)request.getAttribute("displayDays");
    if (displayDaysSelect==null)
    {
       displayDaysSelect=new Long(7);
    }
    out.write(displayDaysSelect.toString());

    out.write("\" size=\"2\" maxlength=\"2\" >");
%>
      <input type="submit" name="action" value="<%= bundle.getString("viewButton")%>"></input>
      <input type="submit" name="action" value="<%= bundle.getString("viewPreviousPeriodButton")%>"></input>
      <input type="submit" name="action" value="<%= bundle.getString("viewNextPeriodButton")%>"></input>
    </fieldset>
  </form>    
  <form name="sched" method="post" action="sched.jsp" onsubmit="saveSchedPos();">  
<%
//if (!RequestUtils.hasEdits(request))
//{
%>
    <div style="float:left;"><h1 id="testdrop"><%= title %> <%= bundle.getString("scheduleLabel")%></h1></div>
  

<%
    if (showAdd)
    {
%>  
    <div style="float:right;padding-top:1em;">
    <button onclick="checkAll(document.sched.s,true);return false;"><%= bundle.getString("selectAllLabel")%></button>
    <button onclick="checkAll(document.sched.s,false);return false;"><%= bundle.getString("unSelectAllLabel")%></button>    
    <input type="submit" name="action" value="<%= bundle.getString("deleteLabel")%>"></input>
    <%-- <div style="background-color:#c0c0c0;border-width:3px;border-color:#000000;padding-right:5px;display:inline;"> --%>
    <div style="padding-right:5px;display:inline;">
    <input type="submit" name="action" value="<%= bundle.getString("copyMoveLabel")%>"></input><%
    // Display Days
    out.write("<input type=\"text\" name=\"");
    out.write("daysToMove\" title=\"");
    out.write(bundle.getString("moveDaysLabel"));
    out.write("\" value=\"");

    Long moveDaysSelect=(Long)request.getAttribute("moveDays");
    if (moveDaysSelect==null)
    {
       moveDaysSelect=new Long(7);
    }
    out.write(moveDaysSelect.toString());

    out.write("\" size=\"2\" maxlength=\"2\" > <label for=\"daysToMove\">" + bundle.getString("daysLabel") + "<label>");
%>
    </div>
    </div>
<%
    }
%>
    <div style="clear:both;"></div>    
<%
     
    // Get TimeZone.
    TimeZone timeZone=RequestUtils.getCurrentStore(request).getTimeZone();
    Locale locale=SessionUtils.getLocale(request);

    // Date format.  Set TimeZone for all of them.
    SimpleDateFormat displayMonthDateDayofWeek=new SimpleDateFormat("MMM dd EEE", locale);
    displayMonthDateDayofWeek.setTimeZone(timeZone);

    SimpleDateFormat displayMonthDate=new SimpleDateFormat("MMM dd", locale);
    displayMonthDate.setTimeZone(timeZone);

    SimpleDateFormat displayHourAmPm=new SimpleDateFormat("h aa", locale);
    displayHourAmPm.setTimeZone(timeZone);

    SimpleDateFormat displayHour=new SimpleDateFormat("h", locale);
    displayHour.setTimeZone(timeZone);

    SimpleDateFormat displayHourMinAmPm=new SimpleDateFormat("h:mm aa", locale);
    displayHourMinAmPm.setTimeZone(timeZone);

    SimpleDateFormat displayHourMin=new SimpleDateFormat("h:mm", locale);
    displayHourMin.setTimeZone(timeZone);

    // Get start date
    Date startDate=(Date)request.getAttribute("startDate");
    if (startDate==null)
    {
        startDate=new Date();
    }

    Calendar currCalendar = DateUtils.getCalendar(request);
    currCalendar.setTime( startDate );

    // Build table (days on first row, then user and schedule for days)
    out.write("<table id=\"sched\" border=\"1\" class=\"sched\">");

    // Number of days
    int displayDaysSelectInt=displayDaysSelect.intValue();
    int width=100/(displayDaysSelectInt+1);

    for (int i=0;i<displayDaysSelectInt+1;i++)
    {
        // Create columns
        out.write("<col width=\"" + width + "%\"/>");
    }

    out.write("<tr>");
    out.write("<th>");
    out.write(bundle.getString("usersLabel"));    
    out.write(" / ");
    out.write(bundle.getString("daysLabel"));
    out.write("</th>");

    // Each day in the display
    List days=new ArrayList();
    for(int i=0;i<displayDaysSelectInt;i++)
    {        
        out.write("<th id=\"");
        out.write(new Integer(currCalendar.get(Calendar.YEAR)).toString());
        out.write("-");
        out.write(new Integer(currCalendar.get(Calendar.MONTH)+1).toString());
        out.write("-");
        out.write(new Integer(currCalendar.get(Calendar.DATE)).toString());
        out.write("\">");        
        
        out.write("<input type=\"checkbox\" name=\"selCol\" title=\"" + bundle.getString("selectColLabel") + "\" value=\"\" onclick=\"checkCol(this," + i + ");\"/> ");
        
        out.write(displayMonthDateDayofWeek.format(currCalendar.getTime()));
        out.write("</th>");
        currCalendar.add(Calendar.DATE, 1);
    }
    out.write("</tr>");

    // Display users and the shifts in the days
    Map<Long,UserShift> shifts=(Map)request.getAttribute("userShifts");
    
    if (users!=null && !users.isEmpty())
    {
        String addLabel=bundle.getString("addLabel");
    
        // For each user
        Iterator iter = users.entrySet().iterator();
        int row=0;
        while (iter.hasNext())
        {
            row++;
            Entry entry = (Entry)iter.next();
            User user=(User)entry.getValue();
        
            long currUserId=user.getKey().getId();
            
            if (userIdLong.longValue()==User.ALL_USERS || userIdLong.longValue()==currUserId)
            {

                List userShifts=(List)shifts.get(new Long(currUserId));
                if (userShifts==null)
                {
                    userShifts=new ArrayList();
                }

                // Id is user Id.  Used for drag and drop.
                out.write("<tr id=\"" +  currUserId + "\">");

                // User name
                out.write("<th>");
                String userName=HtmlUtils.escapeChars(DisplayUtils.formatName(user.getFirstName(),user.getLastName(),true));
                out.write("<input type=\"checkbox\" name=\"selRow\" title=\"" + bundle.getString("selectRowLabel") + "\" value=\"\" onclick=\"checkRow(this," + row + ");\"/> ");
                out.write( userName );
                out.write("</th>");

                currCalendar.setTime( startDate );

                for(int i=0;i<displayDaysSelectInt;i++)
                {
                    String cellDateDisplay=displayMonthDateDayofWeek.format(currCalendar.getTime());

                    out.write("<td title=\"" + userName + " - ");
                    out.write(cellDateDisplay);
                    out.write("\">");

                    /*                    
                    if (isAdmin || (showAdd && currUserId==currentUser.getKey().getId()))
                    {		

                    
                        out.write(" onmouseup=\"a('");
                        //out.write("u=");
                        out.write(new Long(currUserId).toString());
                        out.write("','");
                        out.write(new Integer(currCalendar.get(Calendar.YEAR)).toString());
                        out.write("-");
                        out.write(new Integer(currCalendar.get(Calendar.MONTH)+1).toString());
                        out.write("-");
                        out.write(new Integer(currCalendar.get(Calendar.DATE)).toString());
                        out.write("');\"");
                    }                    
                    */
                    
                    //out.write(">");

                    // Spin through all shifts for this user
                    boolean hasShift=false;

                    // Display shifts
                    for (int j=0;j<userShifts.size();j++)
                    {
                        UserShift shift=(UserShift)userShifts.get(j);

                        Date startShift=shift.getStartDate();
                        Date endShift=DateUtils.getEndDate(startShift,shift.getDuration());
                        long currRoleId=shift.getRoleId();
                        long currShiftTemplateId=shift.getShiftTemplateId();

                        Calendar startShiftCalendar = DateUtils.getCalendar(request);
                        startShiftCalendar.setTime( startShift );

                        Calendar endShiftCalendar = DateUtils.getCalendar(request);
                        endShiftCalendar.setTime( endShift );

                        StringBuffer shiftDisplay=new StringBuffer();
                        boolean hasCurrentShift=false;
                        boolean startsDayBefore=false;

                        // Create next day.  Clone current and add 1 day.                        
                        Calendar nextDay=(Calendar)currCalendar.clone();
                        nextDay.add(Calendar.DATE, 1);
                        
                        // Shifts are ordered by start time so if the shift start
                        // time is greater than next day, break.
                        if (startShift.compareTo(nextDay.getTime())>0)
                        {
                            break;
                        }
                        
                        // For Roles, if display all and the current role exists or is no role, OR current role is the role to display,
                        // For Shift Templates, if display all and the current shift template exists or is no shift template, OR current shift template is the shift template to display.
                        if ( ((roleIdLong.longValue()==Role.ALL_ROLES && (roles.containsKey(new Long(currRoleId)) || currRoleId==Role.NO_ROLE)) || roleIdLong.longValue()==currRoleId)
                        && ((shiftTemplateIdLong.longValue()==ShiftTemplate.ALL_SHIFTS && (shiftTemplates.containsKey(new Long(currShiftTemplateId)) || currShiftTemplateId==ShiftTemplate.NO_SHIFT)) || shiftTemplateIdLong.longValue()==currShiftTemplateId) )
                        {           
                            boolean endsOnSameDay=
                                startShiftCalendar.get(Calendar.DATE)==endShiftCalendar.get(Calendar.DATE) &&
                                startShiftCalendar.get(Calendar.MONTH)==endShiftCalendar.get(Calendar.MONTH) &&
                                startShiftCalendar.get(Calendar.YEAR)==endShiftCalendar.get(Calendar.YEAR);
                        
                            // If the shift starts on the same day as the current day, then add it to
                            // the display.
                            if( startShiftCalendar.get(Calendar.DATE)==currCalendar.get(Calendar.DATE) &&
                                startShiftCalendar.get(Calendar.MONTH)==currCalendar.get(Calendar.MONTH) &&
                                startShiftCalendar.get(Calendar.YEAR)==currCalendar.get(Calendar.YEAR)
                                )
                            {
                                hasCurrentShift=true;
                                hasShift=true;
                
                                // If am/pm is same, only use on end.
                                if (endsOnSameDay && startShiftCalendar.get(Calendar.AM_PM)==endShiftCalendar.get(Calendar.AM_PM))
                                {
                                    // If min not zero, display minutes.
                                    shiftDisplay.append(DisplayUtils.getHourMinuteDisplay(startShiftCalendar, startShift, displayHour, displayHourMin));
                                }
                                else
                                {
                                    shiftDisplay.append(DisplayUtils.getHourMinuteDisplay(startShiftCalendar, startShift, displayHourAmPm, displayHourMinAmPm));
        
                                }
        
                                // If the shift ends on the same day, add the end shift.
                                if(endsOnSameDay)
                                {
                                    shiftDisplay.append(" &rarr; ");
                                    shiftDisplay.append(DisplayUtils.getHourMinuteDisplay(endShiftCalendar, endShift, displayHourAmPm, displayHourMinAmPm));
                                    
                                    // Remove from list as it isn't needed anymore.
                                    // Since item is removed, decrease counter by 1.
                                    userShifts.remove(j);
                                    j=j-1;                                   
                                }
                                // If the shift doesn't end on the same day, if must proceed to the next day.
                                else
                                {                                    
                                    // If ends at the start of the next day, remove from list because otherwise
                                    // the shift will be of zero length on that day.
                                    if (endShift.compareTo(nextDay.getTime())==0)
                                    {
                                        shiftDisplay.append( " &rarr; 12AM"  );                                    
                                    
                                        // Remove from list as it isn't needed anymore.                              
                                        // Since item is removed, decrease counter by 1.                                
                                        userShifts.remove(j);
                                        j=j-1;                                    
                                    }
                                    else
                                    {
                                        shiftDisplay.append( " &rarr; (" + bundle.getString("nextDayLabel") + ")"  );                                    
                                    }
                                }

                            }
                            // If end is same as date
                            else if (endShiftCalendar.get(Calendar.DATE)==currCalendar.get(Calendar.DATE) &&
                                endShiftCalendar.get(Calendar.MONTH)==currCalendar.get(Calendar.MONTH) &&
                                endShiftCalendar.get(Calendar.YEAR)==currCalendar.get(Calendar.YEAR) && (endShiftCalendar.get(Calendar.HOUR_OF_DAY)!=0 || endShiftCalendar.get(Calendar.MINUTE)!=0)  )
                            {
                                startsDayBefore=true;
                            
                                hasCurrentShift=true;
                                hasShift=true;
        
                                shiftDisplay.append( "(" + bundle.getString("previousDayLabel") + ") &rarr; "  );                                    
                                shiftDisplay.append(DisplayUtils.getHourMinuteDisplay(endShiftCalendar, endShift, displayHourAmPm, displayHourMinAmPm));

                                // Remove from list as it isn't needed anymore.                              
                                // Since item is removed, decrease counter by 1.                                
                                userShifts.remove(j);
                                j=j-1;
        

                            }
                            // If shift starts before this day and ends after, then mark as All Day.
                            else if (currCalendar.getTime().compareTo(startShift)>0 && endShift.compareTo(nextDay.getTime())>0)
                            {                            
                                startsDayBefore=true;                            
                            
                                hasCurrentShift=true;
                                hasShift=true;
                                shiftDisplay.append( bundle.getString("allDayLabel")  );
                            }
                        }

                        if (hasCurrentShift)
                        {
                            out.write("<div class=\"drag\">");
                        
                            Role role=(Role)roles.get(new Long(currRoleId));

                            // Check if checkbox shows
                            boolean showCheckbox=isAdmin || (currUserId==currentUser.getKey().getId() && role!=null && role.getAllUserUpdateAccess());

                            String shiftIdString=new Long(shift.getKey().getId()).toString();
                            
                            if (!startsDayBefore)
                            {        
                                if (showCheckbox)
                                {
                                    out.write("<input class=\"si\" type=\"checkbox\" name=\"s\" value=\"" + shiftIdString + "\"/> ");                            
                                }
                                else
                                {
                                    out.write("&#9632 "); // black square
                                    // out.write("&bull; ");
                                }
                            }

                            //if (showLink)
                            //{
                                out.write("<a href=\"userShift.jsp?s=");
                                out.write(shiftIdString);
                                out.write("\">");
                                
                                //out.write("\" onclick=\"s(this);\"");
                                //out.write(">");
                                
                            //}

                            out.write(shiftDisplay.toString());

                            // Get role description
                            if (role!=null)
                            {
                                out.write(" ");
                                out.write(HtmlUtils.escapeChars(role.getDesc()));
                            }

                            // Get shift template description
                            ShiftTemplate shiftTemplate=(ShiftTemplate)shiftTemplates.get(new Long(currShiftTemplateId));
                            if (shiftTemplate!=null)
                            {
                                //out.write("<div class=\"someclass\">");                            
                                
                                out.write(" ");
                                out.write(HtmlUtils.escapeChars(shiftTemplate.getDesc()));
                                
                                //out.write("</div>");                            
                            }

                            //if (showLink)
                            //{
                                out.write("</a>");
                            //}
                            
                            out.write("</div>");                            
                        }
                    }

                    if (isAdmin || (currUserId==currentUser.getKey().getId() && showAdd))
                    {		
                        out.write("<a class=\"add\" href=\"userShift.jsp?");
                        out.write("u=");
                        out.write(new Long(currUserId).toString());
                        out.write("&d=");
                        out.write(new Integer(currCalendar.get(Calendar.YEAR)).toString());
                        out.write("-");
                        out.write(new Integer(currCalendar.get(Calendar.MONTH)+1).toString());
                        out.write("-");
                        out.write(new Integer(currCalendar.get(Calendar.DATE)).toString());
                        out.write("\">");
                        out.write("+");
                        out.write("</a>");                                        
                    }
                    else
                    {
                        if (!hasShift)
                        {
                            out.write("&nbsp;");
                        }
                        //else
                        //{
                        //	out.write("<br/>");                        
                        //}
                    }

                    out.write("</td>");

                    // Increment current day
                    currCalendar.add(Calendar.DATE, 1);
                }
                out.write("</tr>");
            }	
        }
    }
    else
    {
        // Will not happen because page can't display if no users, but just in case. (change --- to "No Users")
        out.write("<tr><td colspan=\"" + (displayDaysSelectInt+1) + "\"> --- </td></tr>");
    }

    out.write("</table>");
//}
%>
</form>
<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
<%-- <pre id="debug"></pre> --%>
</body>
<script type="text/javascript" src="/js/sched.js" >
</script>
</html>