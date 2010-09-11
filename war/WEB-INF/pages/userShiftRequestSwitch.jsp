<%-- This JSP has the HTML for the user shift request switch page.--%>
<%@ page language="java"%>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.UserShiftGetAll"%>
<%@ page import="sched.data.UserShiftGetSingle"%>
<%@ page import="sched.data.UserShiftRequestSwitchAddUpdate" %>
<%@ page import="sched.data.UserShiftRequestSwitchGetAll" %>
<%@ page import="sched.data.UserShiftRequestSwitchProcess" %>
<%@ page import="sched.data.UserShiftRequestSwitchDelete" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.data.model.UserShift" %>
<%@ page import="sched.data.model.UserShiftRequestSwitch" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%@ page import="sched.utils.StringUtils" %>
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

        %>
       <%-- <jsp:forward page="/sched.jsp"/> --%>
        <%    
    
    // Check if admin
    // TODO - Needed?
    User currentUser=RequestUtils.getCurrentUser(request);
    boolean isCurrentUserAdmin=false;
    if (currentUser!=null && currentUser.getIsAdmin())
    {
        isCurrentUserAdmin=true;
    }
    
    // Get users.
    Map<Long,User> users=RequestUtils.getUsers(request);

    // Get roles (needed for UserShiftGetAll)
    Map<Long,Role> roles=RequestUtils.getRoles(request);
   
    // Get shift templates (needed for UserShiftGetAll)
    Map<Long,ShiftTemplate> shiftTemplates=RequestUtils.getShiftTemplates(request);        
    
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));            

    Long userShiftId=RequestUtils.getNumericInput(request,"s",bundle.getString("shiftIdLabel"),false);
    UserShift userShift=null;
    if (userShiftId!=null)
    {
        // Get single shift.
        request.setAttribute("userShiftId",userShiftId);
        new UserShiftGetSingle().execute(request, roles, shiftTemplates, users);
        
        userShift=(UserShift)request.getAttribute("userShift");
    }

    // Process based on action
    String action=RequestUtils.getAlphaInput(request,"action","Action",false);
    if (!StringUtils.isEmpty(action) && !RequestUtils.isForwarded(request))
    {    
        Long token=RequestUtils.getNumericInput(request,"csrfToken","CSRF Token",true);
        if (!SessionUtils.isCSRFTokenValid(request,token))
        {
            %>
            <jsp:forward page="/logonForward.jsp"/>
            <%
        }
    
        Map<Long,UserShift> shifts=new LinkedHashMap<Long,UserShift>();    
    
        if (action.equals(bundle.getString("startNewRequestLabel")))
        {        
            request.setAttribute("actionType",new Integer(UserShiftRequestSwitchAddUpdate.ADD_NEW));
        
            // Required
            request.setAttribute("userShiftRequestSwitchId",null);
            
            if (!RequestUtils.hasEdits(request))
            {           
                new UserShiftRequestSwitchAddUpdate().execute(request,roles,shiftTemplates,users,shifts);
            }

            // If successful, reset form.
            if (!RequestUtils.hasEdits(request))
            {
                userShift=null;
                userShiftId=null;
            }
        }
        else if (action.equals(bundle.getString("addShiftToTradeLabel")))
        {        
            request.setAttribute("actionType",new Integer(UserShiftRequestSwitchAddUpdate.ADD_EXISTING));

            // Required
            RequestUtils.getNumericInput(request,"userShiftRequestSwitchId",bundle.getString("tradeIdLabel"),true);
            
            if (!RequestUtils.hasEdits(request))
            {           
                new UserShiftRequestSwitchAddUpdate().execute(request,roles,shiftTemplates,users,shifts);
            }

            // If successful, reset form.
            if (!RequestUtils.hasEdits(request))
            {
                userShift=null;
                userShiftId=null;
            }
        }    
        else if (action.equals("User1Approves") || action.equals("User2Approves") ||
            action.equals("User1NotApproves") || action.equals("User2NotApproves") ||
            action.equals("RemoveUserShift1") || action.equals("RemoveUserShift2"))
        {    
            int actionType=-1;
            if (action.equals("User1Approves"))
            {
                actionType=UserShiftRequestSwitchAddUpdate.USER1_APPROVES;
            }
            else if (action.equals("User2Approves"))
            {
                actionType=UserShiftRequestSwitchAddUpdate.USER2_APPROVES;
            }
            else if (action.equals("User1NotApproves"))
            {
                actionType=UserShiftRequestSwitchAddUpdate.USER1_NOT_APPROVES;
            }
            else if (action.equals("User2NotApproves"))
            {
                actionType=UserShiftRequestSwitchAddUpdate.USER2_NOT_APPROVES;
            }            
            else if (action.equals("RemoveUserShift1"))
            {
                actionType=UserShiftRequestSwitchAddUpdate.REMOVE_USER_SHIFT1;
            }
            else if (action.equals("RemoveUserShift2"))
            {
                actionType=UserShiftRequestSwitchAddUpdate.REMOVE_USER_SHIFT2;
            }
                        
            request.setAttribute("actionType",new Integer(actionType));
       
            // Required
            RequestUtils.getNumericInput(request,"userShiftRequestSwitchId",bundle.getString("tradeIdLabel"),true);
            
            if (!RequestUtils.hasEdits(request))
            {           
                new UserShiftRequestSwitchAddUpdate().execute(request,roles,shiftTemplates,users,shifts);
            }

            // If successful, reset form.
            if (!RequestUtils.hasEdits(request))
            {
                userShift=null;
                userShiftId=null;
            }
        }                
        else if (action.equals("Process"))
        {        
            // Required
            RequestUtils.getNumericInput(request,"userShiftRequestSwitchId",bundle.getString("tradeIdLabel"),true);
            
            if (!RequestUtils.hasEdits(request))
            { 
                new UserShiftRequestSwitchProcess().execute(request,roles,shiftTemplates,users,shifts);
            }
        }        
        else if (action.equals("Delete"))
        {        
            // Required
            RequestUtils.getNumericInput(request,"userShiftRequestSwitchId",bundle.getString("tradeIdLabel"),true);
            
            if (!RequestUtils.hasEdits(request))
            { 
                new UserShiftRequestSwitchDelete().execute(request,roles,shiftTemplates,users,shifts);
            }
        }                
    }
    
    new UserShiftRequestSwitchGetAll().execute(request,roles, shiftTemplates, users);        
    Map<Long,UserShift> shifts=(Map)request.getAttribute("userShifts");            
        
    String title=HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request));
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= title %> <%=bundle.getString("tradesLabel")%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

    <%
        if (userShift!=null)
        {
    %>
  
    <form id="role" method="post" action="userShiftRequestSwitch.jsp" autocomplete="off">  
  
      <fieldset class="action">
      <legend><b><%=bundle.getString("addTradeLabel")%></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>
        
      <p> <%=bundle.getString("addNewTradeOrAddToExistingSentence")%> </p>
      
      <%
        List shiftsTemp=new ArrayList();
        shiftsTemp.add(userShift);
        request.setAttribute("userShifts",shiftsTemp);
      %>
      
      <jsp:include page="/WEB-INF/pages/components/userShiftTable.jsp"/>      

      <table>
      
<%--        <tr><td><label for="desc">Note</label></td><td><input type="text" name="note" value="<%= HtmlUtils.escapeChars("update") %>" id="note" maxlength="100" title="Note"/></td></tr>        --%>

      </table>
      
      <br/>

      <input type="hidden" name="csrfToken" value="<%= SessionUtils.getCSRFToken(request) %>"/>
      <input type="submit" name="action" value="<%=bundle.getString("startNewRequestLabel")%>"></input>
      
    <%        
        if (userShiftId!=null)
        {
            out.write("<input type=\"hidden\" name=\"s\" value=\"" + userShiftId.toString() + "\"></input>");
        }
    %>      
    </fieldset>
  </form>

<%
}
else
{
%>      
<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>
<%
}

//if (!RequestUtils.hasEdits(request))
//{
%>
  
<h1><%= title %> <%=bundle.getString("tradesLabel")%></h1>

<%
    //Map<Long,UserShiftRequestSwitch> userShiftRequestSwitchs=RequestUtils.getUserShiftRequestSwitchs(request);    
    Map<Long,UserShiftRequestSwitch> userShiftRequestSwitchs=(Map<Long,UserShiftRequestSwitch>)request.getAttribute("userShiftRequestSwitchs");    
    
    //Map<Long,Role> roles=(Map<Long,Role>)request.getAttribute("roles");
    //Map<Long,ShiftTemplate> shiftTemplates=(Map<Long,ShiftTemplate>)request.getAttribute("shiftTemplates");
    //Map<Long,User> users=(Map<Long,User>)request.getAttribute("users");
    
    if (userShiftRequestSwitchs!=null && !userShiftRequestSwitchs.isEmpty())
    {
        SimpleDateFormat displayDateTime=new SimpleDateFormat("yyyy MMM dd EEE h:mm aa", SessionUtils.getLocale(request));           
        displayDateTime.setTimeZone(RequestUtils.getCurrentStore(request).getTimeZone());        
    
        out.write("<table border=\"1\" style=\"text-align:left;\"><tr>");
        out.write("<th>Status</th>");
        // rowspan=\"2\"
        //out.write("<th colspan=\"5\">Shift 1</th>");        
        //out.write("<th colspan=\"5\">Shift 2</th></tr><tr>"); 
            
        // User Shift 1
        out.write("<th>" + bundle.getString("userLabel") + " 1</th>");
        out.write("<th>" + bundle.getString("startTimeLabel") + "</th>");
        out.write("<th>" + bundle.getString("durationLabel") + "</th>");       
        out.write("<th>" + bundle.getString("roleLabel") + "</th>");
        out.write("<th>" + bundle.getString("shiftNameLabel") + "</th>");

        // User Shift 2
        out.write("<th>" + bundle.getString("userLabel") + " 2</th>");
        out.write("<th>" + bundle.getString("startTimeLabel") + "</th>");
        out.write("<th>" + bundle.getString("durationLabel") + "</th>");       
        out.write("<th>" + bundle.getString("roleLabel") + "</th>");
        out.write("<th>" + bundle.getString("shiftNameLabel") + "</th>");

        out.write("<th>" + bundle.getString("actionLabel") + "</th>");

        //out.write("<th>Note</th>");                
        out.write("</tr>");       
        
        Iterator iter = userShiftRequestSwitchs.entrySet().iterator();
        while (iter.hasNext())
        {
            Entry entry = (Entry)iter.next();
            UserShiftRequestSwitch userShiftRequestSwitch=(UserShiftRequestSwitch)entry.getValue();

            UserShift userShift1=null;
            UserShift userShift2=null;
            
            long userShiftRequestSwitchId=userShiftRequestSwitch.getKey().getId();
            
            out.write("<tr>");
                
            // Status
            out.write("<td>");            
            int status=userShiftRequestSwitch.getStatus();
            
            if (status==UserShiftRequestSwitch.PROCESSED)
            {
                out.write(bundle.getString("processedLabel"));
            }
            else
            {
                //boolean addedApproval=false;
                
                if (userShiftRequestSwitch.getUserStatus1()!=UserShiftRequestSwitch.APPROVED
                && userShiftRequestSwitch.getUserStatus2()!=UserShiftRequestSwitch.APPROVED)                
                {
                    out.write(bundle.getString("waiting1And2Approval"));
                }                
                else if (userShiftRequestSwitch.getUserStatus1()!=UserShiftRequestSwitch.APPROVED)
                {
                    out.write(bundle.getString("waiting1Approval"));
                }
                else if (userShiftRequestSwitch.getUserStatus2()!=UserShiftRequestSwitch.APPROVED)
                {
                    out.write(bundle.getString("waiting2Approval"));
                }
                else
                {
                    out.write(bundle.getString("approvedByBoth"));
                }
            }
            
            /*
            if (status==UserShiftRequestSwitch.PROCESSED)
            {
                out.write("Processed");
            }            
            else
            {
                out.write("&nbsp;");
            }*/           
            out.write("</td>");
            
            // Shift 1         
            Long userShiftId1=new Long(userShiftRequestSwitch.getUserShiftId1());
            if (shifts!=null && shifts.containsKey(userShiftId1))
            {
                userShift1=(UserShift)shifts.get(userShiftId1);        
               
                out.write(DisplayUtils.formatUserShift(userShift1, roles, shiftTemplates, users, displayDateTime));                
            }
            else
            {
                out.write("<td>");//&nbsp;</td>");

                if (userShiftId!=null)
                {
                    //out.write("<form method=\"post\" action=\"userShiftRequestSwitch.jsp\"><input type=\"submit\" name=\"action\" value=\"Add Shift\"></input></form>");                                  

                    // Button
                    out.write("<form method=\"post\" action=\"userShiftRequestSwitch.jsp\" autocomplete=\"off\">");
                    out.write("<input type=\"hidden\" name=\"userShiftRequestSwitchId\" value=\"" + userShiftRequestSwitchId + "\"></input>");
                    out.write("<input type=\"hidden\" name=\"s\" value=\"" + userShiftId + "\"></input>");
                    out.write("<input type=\"submit\" name=\"action\" value=\"" + bundle.getString("addShiftToTradeLabel") + "\"></input>");
                    out.write("<input type=\"hidden\" name=\"csrfToken\" value=\"" + SessionUtils.getCSRFToken(request) + "\"></input>");
                    out.write("</form>");      
                
                    // Link
                    //out.write("<a href=\"userShiftRequestSwitch.jsp?action=AddToExisting&userShiftRequestSwitchId=" + userShiftRequestSwitchId + "&s=" + userShiftId.toString());
                    //out.write("\">" + bundle.getString("addShiftLabel") + "</a>");            
                }
                else
                {
                    out.write("&nbsp;");
                }
                out.write("</td>");
                
                out.write("<td>&nbsp;</td>");                        
                out.write("<td>&nbsp;</td>");                        
                out.write("<td>&nbsp;</td>");                        
                out.write("<td>&nbsp;</td>");                                        
            }

            // Shift 2          
            Long userShiftId2=new Long(userShiftRequestSwitch.getUserShiftId2());
            if (shifts!=null && shifts.containsKey(userShiftId2))
            {
                userShift2=(UserShift)shifts.get(userShiftId2);                    
            
                // Shift 2
                out.write(DisplayUtils.formatUserShift(userShift2, roles, shiftTemplates, users, displayDateTime));                
            }
            else
            {
                out.write("<td>");//&nbsp;</td>");

                if (userShiftId!=null)
                {
                    //out.write("<form method=\"post\" action=\"userShiftRequestSwitch.jsp\"><input type=\"submit\" name=\"action\" value=\"Add Shift\"></input></form>");                                    
                
                    // Button
                    out.write("<form method=\"post\" action=\"userShiftRequestSwitch.jsp\" autocomplete=\"off\">");
                    out.write("<input type=\"hidden\" name=\"userShiftRequestSwitchId\" value=\"" + userShiftRequestSwitchId + "\"></input>");
                    out.write("<input type=\"hidden\" name=\"s\" value=\"" + userShiftId + "\"></input>");
                    out.write("<input type=\"submit\" name=\"action\" value=\"" + bundle.getString("addShiftToTradeLabel") + "\"></input>");
                    out.write("<input type=\"hidden\" name=\"csrfToken\" value=\"" + SessionUtils.getCSRFToken(request) + "\"></input>");
                    out.write("</form>");      
                
                    // Link
                    //out.write(" <a href=\"userShiftRequestSwitch.jsp?action=AddToExisting&userShiftRequestSwitchId=" + userShiftRequestSwitchId + "&s=" + userShiftId.toString());
                    //out.write("\">" + bundle.getString("addShiftLabel") + "</a>");            
                }
                else
                {
                    out.write("&nbsp;");
                }
                out.write("</td>");

                
                out.write("<td>&nbsp;</td>");                        
                out.write("<td>&nbsp;</td>");                        
                out.write("<td>&nbsp;</td>");                        
                out.write("<td>&nbsp;</td>");                                        
            }
            
            // long userShiftRequestSwitchId=userShiftRequestSwitch.getKey().getId();

            // Actions
            out.write("<td>");            
            
            boolean prev=false;
            
            if (isCurrentUserAdmin)
            {
                out.write("<a href=\"userShiftRequestSwitch.jsp?action=Process&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                out.write("\">" + bundle.getString("processLabel") + "</a>");
            
                //out.write(" <a href=\"userShiftRequestSwitch.jsp?action=Deny&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                //out.write("\">Deny</a>");

                //out.write(" <a href=\"userShiftRequestSwitch_edit.jsp?userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                //out.write("\">Edit</a>");
            
                out.write(" | <a href=\"userShiftRequestSwitch.jsp?action=Delete&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                out.write("\">" + bundle.getString("deleteLabel") + "</a>");
                
                prev=true;
            }
            
            if (userShift1!=null && (currentUser.getKey().getId()==userShift1.getUserId() || isCurrentUserAdmin))
            {
                if (prev)
                {
                    out.write(" | ");            
                }
                
                if (userShiftRequestSwitch.getUserStatus1()!=UserShiftRequestSwitch.APPROVED)
                {
                    out.write("<a href=\"userShiftRequestSwitch.jsp?action=User1Approves&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                    out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                    out.write("\">" + bundle.getString("user1ApprovesLabel") + "</a>");            
                }
                else
                {
                    out.write("<a href=\"userShiftRequestSwitch.jsp?action=User1NotApproves&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                    out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                    out.write("\">" + bundle.getString("removeUser1ApprovalLabel") + "</a>");            
                }
                
                out.write(" | <a href=\"userShiftRequestSwitch.jsp?action=RemoveUserShift1&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                out.write("\">" + bundle.getString("removeShift1Label") + "</a>");          

                prev=true;                
            }
            
            if (userShift2!=null && (currentUser.getKey().getId()==userShift2.getUserId() || isCurrentUserAdmin))
            {            
                if (prev)
                {
                    out.write(" | ");            
                }

                if (userShiftRequestSwitch.getUserStatus2()!=UserShiftRequestSwitch.APPROVED)
                {
                    out.write("<a href=\"userShiftRequestSwitch.jsp?action=User2Approves&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                    out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                    out.write("\">" + bundle.getString("user2ApprovesLabel") + "</a>");                       
                }
                else
                {
                    out.write("<a href=\"userShiftRequestSwitch.jsp?action=User2NotApproves&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                    out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                    out.write("\">" + bundle.getString("removeUser2ApprovalLabel") + "</a>");                                   
                }
                
                out.write(" | <a href=\"userShiftRequestSwitch.jsp?action=RemoveUserShift2&userShiftRequestSwitchId=" + userShiftRequestSwitchId);
                out.write("&csrfToken=" + SessionUtils.getCSRFToken(request));
                out.write("\">" + bundle.getString("removeShift2Label") + "</a>");
            }
            
            out.write("</td>");

            // Note
            //out.write("<td> &nbsp;");
            //out.write("</td>");           
                
            out.write("</tr>");
        }

        out.write("</table>");
    }
    else
    {
        out.write("<p>" + bundle.getString("noneLabel") + "</p>");
    }
//}
%>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>