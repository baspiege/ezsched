<%-- This JSP has the HTML for the shift template update page.--%>
<%@ page language="java"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.ShiftTemplateGetSingle" %>
<%@ page import="sched.data.ShiftTemplateAddUpdate" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.utils.DateUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));           

    // If cancel, forward right away.
    String action=RequestUtils.getAlphaInput(request,"action","Action",false);
    if (action!=null && action.equals(bundle.getString("cancelLabel")))
    {
        // Reset fields
        request.setAttribute("startHour",null);
        request.setAttribute("startMinute",null);
        request.setAttribute("startAmPm",null);
        request.setAttribute("durationHour",null);					
        request.setAttribute("durationMinute",null);	
    
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/WEB-INF/pages/shiftTemplate.jsp"/>
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
    
    // Check if admin
    User currentUser=RequestUtils.getCurrentUser(request);
    boolean isCurrentUserAdmin=false;
    if (currentUser!=null && currentUser.getIsAdmin())
    {
        isCurrentUserAdmin=true;
    }
    else
    {
        // Forward them to the sched page.
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/sched.jsp"/>
        <%
    }

    // Get Id
    Long shiftTemplateIdRequest=RequestUtils.getNumericInput(request,"shiftTemplateId",bundle.getString("shiftTemplateIdLabel"),true);
    if (shiftTemplateIdRequest==null)
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/shiftTemplate.jsp"/>
        <%
    }

    // Set fields
    String desc="";
    Long startHour=null;
    Long startMinute=null;
    String startAmPm="";
    Long durationHour=null;
    Long durationMinute=null;

    // Get shiftTemplate info
    if (!RequestUtils.hasEdits(request))
    {
        new ShiftTemplateGetSingle().execute(request);
        ShiftTemplate shiftTemplate=(ShiftTemplate)request.getAttribute("shiftTemplate");

        if (shiftTemplate==null)
        {
            RequestUtils.resetAction(request);
            RequestUtils.removeEdits(request);
            %>
            <jsp:forward page="/shiftTemplate.jsp"/>
            <%
        }

        // Set fields
        desc=shiftTemplate.getDesc();
            
        // Get time and calculate start hour and minute.
        int shiftTemplateStartTime=shiftTemplate.getStartTime();		

        long startHourLong=0;
        long startMinuteLong=0;		
                
        if (shiftTemplateStartTime!=0)
        {
            startHourLong=shiftTemplateStartTime/60;
            startMinuteLong=shiftTemplateStartTime%60;
        }
        
        // AM/PM
        if (shiftTemplateStartTime>=12*60)
        {
            request.setAttribute("startAmPm",DateUtils.PM);
        }
        else
        {
            request.setAttribute("startAmPm",DateUtils.AM);
        }		
        
        // Convert 24 hour to 12 hour.
        if (startHourLong==0)
        {
            startHourLong=12;
        }
        else if (startHourLong>12)
        {
            startHourLong=startHourLong-12;
        }
        
        request.setAttribute("startHour",new Long(startHourLong));
        request.setAttribute("startMinute",new Long(startMinuteLong));		
        
        // Get duration and calculate hour and min.
        int shiftTemplateDuration=shiftTemplate.getDuration();
        
        long durationHourLong=0;
        long durationMinuteLong=0;		
                
        if (shiftTemplateDuration!=0)
        {
            durationHourLong=shiftTemplateDuration/60;
            durationMinuteLong=shiftTemplateDuration%60;
        }
        
        request.setAttribute("durationHour",new Long(durationHourLong));
        request.setAttribute("durationMinute",new Long(durationMinuteLong));				
    
        // Process based on action
        if (action!=null && action.length()!=0 && !RequestUtils.isForwarded(request))
        {
            if (action.equals(bundle.getString("updateLabel")))
            {
                // Required
                desc=RequestUtils.getAlphaInput(request,"desc",bundle.getString("nameLabel"),true);				
                startHour=RequestUtils.getNumericInput(request,"startHour",bundle.getString("startHourLabel"),true,0,13);
                startMinute=RequestUtils.getNumericInput(request,"startMinute",bundle.getString("startMinuteLabel"),true,-1,60);
                startAmPm=RequestUtils.getAmPmInput(request,"startAmPm",bundle.getString("startAmPmLabel"),true);                
                
                durationHour=RequestUtils.getNumericInput(request,"durationHour",bundle.getString("durationHoursLabel"),true);
                durationMinute=RequestUtils.getNumericInput(request,"durationMinute",bundle.getString("durationMinutesLabel"),true);		
                    
                if (!RequestUtils.hasEdits(request))
                {
                    new ShiftTemplateAddUpdate().execute(request);
                }

                // If successful, go back to shiftTemplate page.
                if (!RequestUtils.hasEdits(request))
                {
                    // Reset fields
                    request.setAttribute("startHour",null);
                    request.setAttribute("startMinute",null);
                    request.setAttribute("startAmPm",null);
                    request.setAttribute("durationHour",null);					
                    request.setAttribute("durationMinute",null);					
                
                    RequestUtils.resetAction(request);

                    // Route to shiftTemplate page.
                    %>
                    <jsp:forward page="/shiftTemplate.jsp"/>
                    <%
                }
            }
        }
    }

    String title=HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request));
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= title %> - <%= bundle.getString("editShiftTemplateLabel") %></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

  <form id="shiftTemplate" method="post" action="shiftTemplate_edit.jsp?shiftTemplateId=<%=shiftTemplateIdRequest%>" autocomplete="off">
    <fieldset class="action">
      <legend><b><%= bundle.getString("editShiftTemplateLabel") %></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

      <table>
        <tr><td><label for="desc"><%=bundle.getString("nameLabel")%> (<%=bundle.getString("requiredLabel")%>)</label></td><td><input type="text" name="desc" value="<%=HtmlUtils.escapeChars(desc)%>" id="desc" maxlength="100" title="<%=bundle.getString("nameLabel")%>"/></td></tr>

        <tr>
          <td><%=bundle.getString("defaultStartTimeLabel")%></td>
          <td><% request.setAttribute("shiftDatePrefix","start"); %><jsp:include page="/WEB-INF/pages/components/timeSelect.jsp"/></td>
        </tr>

        <tr>
          <td><%=bundle.getString("defaultDurationLabel")%></td>
          <td><% request.setAttribute("shiftDatePrefix","duration"); %><jsp:include page="/WEB-INF/pages/components/durationSelect.jsp"/></td>
        </tr>

      </table>
      <br/>

      <input type="submit" name="action" value="<%=bundle.getString("updateLabel")%>"></input> <input type="submit" name="action" value="<%=bundle.getString("cancelLabel")%>"/>
    </fieldset>
  </form>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>