<%-- This JSP has the HTML for the user page. --%>
<%@ page language="java"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.UserAdd" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
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

    // Check if admin
    User currentUser=RequestUtils.getCurrentUser(request);
    boolean isCurrentUserAdmin=false;
    if (currentUser!=null && currentUser.getIsAdmin())
    {
        isCurrentUserAdmin=true;
    }
    
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));                    

    // Default
    boolean isAdmin=false;
    String firstName="";
    String lastName="";
    String emailAddr="";
    Long defaultRoleId=new Long(Role.NO_ROLE);
    request.setAttribute("roleId",defaultRoleId);	
    
    Long defaultShiftTemplateId=new Long(ShiftTemplate.NO_SHIFT);
    request.setAttribute("shiftTemplateId",defaultShiftTemplateId);		

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
    
        if (isCurrentUserAdmin && action.equals(bundle.getString("addLabel")))
        {
            // Required
            firstName=RequestUtils.getAlphaInput(request,"firstName",bundle.getString("firstNameLabel"),true);

            // Optional
            lastName=RequestUtils.getAlphaInput(request,"lastName",bundle.getString("lastNameLabel"),false);
            emailAddr=RequestUtils.getAlphaInput(request,"emailAddr",bundle.getString("emailAddressLabel"),false);
            isAdmin=RequestUtils.getBooleanInput(request,"isAdmin",bundle.getString("adminAccessLabel"),false);
            
            // Role Id
            defaultRoleId=RequestUtils.getNumericInput(request,"defaultRoleId",bundle.getString("defaultRoleLabel"),false);
            if (defaultRoleId==null)
            {
                defaultRoleId=new Long(Role.NO_ROLE);
                request.setAttribute("defaultRoleId",defaultRoleId);
            }

            // Set roleId into the request so it's selected in roleSelectOptions component
            if (defaultRoleId!=null)
            {
                request.setAttribute("roleId",defaultRoleId);
            }
            
            // Shift Template Id
            defaultShiftTemplateId=RequestUtils.getNumericInput(request,"defaultShiftTemplateId",bundle.getString("defaultShiftTemplateLabel"),false);
            if (defaultShiftTemplateId==null)
            {
                defaultShiftTemplateId=new Long(ShiftTemplate.NO_SHIFT);
                request.setAttribute("defaultShiftTemplateId",defaultShiftTemplateId);
            }

            // Set shiftTemplateId into the request so it's selected in shiftTemplateSelectOptions component
            if (defaultShiftTemplateId!=null)
            {
                request.setAttribute("shiftTemplateId",defaultShiftTemplateId);
            }			

            if (!RequestUtils.hasEdits(request))
            {
                new UserAdd().execute(request);
            }

            // If successful, reset form.
            if (!RequestUtils.hasEdits(request))
            {
                firstName="";
                lastName="";
                emailAddr="";
                isAdmin=false;
                
                // Role
                defaultRoleId=new Long(Role.NO_ROLE);
                request.setAttribute("roleId",defaultRoleId);
                
                // Shift template
                defaultShiftTemplateId=new Long(ShiftTemplate.NO_SHIFT);				
                request.setAttribute("shiftTemplateId",defaultShiftTemplateId);			
            }
        }
    }

    // Set the users into the request.
    if (isCurrentUserAdmin)
    {
        RequestUtils.getUsers(request);
    }
    else
    {
        // If non-admin, add current user to list.
        Map<Long,User> userMap=new HashMap<Long,User>();
        userMap.put(new Long(currentUser.getKey().getId()),currentUser);
        request.setAttribute("users", userMap);
    }

    // Create title.  Plural for admins.
    StringBuffer titleSb=new StringBuffer();
    titleSb.append(HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request)));
    titleSb.append(" ");	
    if (isCurrentUserAdmin)
    {
        titleSb.append(bundle.getString("usersLabel"));				
    }
    else
    {
        titleSb.append(bundle.getString("userLabel"));				    
    }
    
    String title=titleSb.toString();
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= title %></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

<%
// Display add for admins only
if (isCurrentUserAdmin)
{
%>
<form id="updates" method="post" action="user.jsp" autocomplete="off">
    <fieldset class="action">
      <legend><b><%= bundle.getString("addUserLabel")%></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

    <table>
    <tr><td><label for="firstName"><%= bundle.getString("firstNameLabel")%> (<%= bundle.getString("requiredLabel")%>)</label></td><td><input type="text" name="firstName" title="<%= bundle.getString("firstNameLabel")%>" value="<%=HtmlUtils.escapeChars(firstName)%>" id="firstName" maxlength="100"/></td></tr>
    <tr><td><label for="lastName"><%= bundle.getString("lastNameLabel")%></label></td><td><input type="text" name="lastName" title="<%= bundle.getString("lastNameLabel")%>" value="<%=HtmlUtils.escapeChars(lastName)%>" id="lastName" maxlength="100"/></td></tr>
    <tr><td><label for="emailAddr"><%= bundle.getString("emailAddressLabel")%><sup><small>*</small></sup></label></td><td><input type="text" name="emailAddr" title="<%= bundle.getString("emailAddressLabel")%>" value="<%=HtmlUtils.escapeChars(emailAddr)%>" id="emailAddr" maxlength="100"/></td></tr>
    <tr><td><label for="isAdmin">Admin Access</label></td><td>
        <select name="isAdmin" title="<%= bundle.getString("adminAccessLabel")%>" id="isAdmin">
        <option value="false" <%= !isAdmin?"selected=true":"" %>><%= bundle.getString("noLabel")%></option>
        <option value="true" <%= isAdmin?"selected=true":"" %>><%= bundle.getString("yesLabel")%></option>
        </select></td>
    </tr>

    <tr>
      <td><label for="defaultRoleId"><%= bundle.getString("defaultRoleLabel")%></label></td>
      <td><select name="defaultRoleId" title="<%= bundle.getString("rolesLabel")%>" id="defaultRoleId">
<% request.setAttribute("displayAllRoles",new Boolean(false)); %><jsp:include page="/WEB-INF/pages/components/roleSelectOptions.jsp"/>
        </select>
      </td>
    </tr>
    
    <tr>
      <td><label for="defaultShiftTemplateId"><%= bundle.getString("defaultShiftTemplateLabel")%></label></td>
      <td><select name="defaultShiftTemplateId" title="<%= bundle.getString("shiftTemplatesLabel")%>" id="defaultShiftTemplateId">
<% request.setAttribute("showShiftTemplateDescOnly",new Boolean(true)); %>	  
<jsp:include page="/WEB-INF/pages/components/shiftTemplateSelectOptions.jsp"/>
        </select>
      </td>
    </tr>	

    </table>
    <p><sup><small>*</small></sup><%= bundle.getString("userEmailSignInFootnote")%></p> 
    <input type="submit" name="action" value="<%= bundle.getString("addLabel")%>"/>
    <input type="hidden" name="csrfToken" value="<%= SessionUtils.getCSRFToken(request) %>"/>
    </fieldset>
</form>
<%  
}
%>

<%
    out.write("<h1>" + title + "</h1>");

    Map<Long,User> users=(Map<Long,User>)request.getAttribute("users");	

    if (users!=null && !users.isEmpty())
    {
        // Roles and shift templates
        Map<Long,Role> roles=RequestUtils.getRoles(request);
        Map<Long,ShiftTemplate> shiftTemplates=RequestUtils.getShiftTemplates(request);		

        out.write("<table border=\"1\" style=\"text-align:left;\"><tr>");
        out.write("<th>" + bundle.getString("userNameLabel") + "</th>");
        out.write("<th>" + bundle.getString("emailAddressLabel") + "</th>");

        // Fields only for admins to see/use
        if (isCurrentUserAdmin)
        {
            out.write("<th>" + bundle.getString("adminAccessLabel") + "</th>");        
            out.write("<th>" + bundle.getString("defaultRoleLabel") + "</th>");
            out.write("<th>" + bundle.getString("defaultShiftTemplateLabel") + "</th>");            
            out.write("<th>" + bundle.getString("actionLabel") + "</th>");
        }

        out.write("</tr>");

        Iterator iter = users.entrySet().iterator();
        while (iter.hasNext())
        {
            Entry entry = (Entry)iter.next();
            User user=(User)entry.getValue();
        
            out.write("<tr>");
            
            // Name
            out.write("<td>");            
            String name=HtmlUtils.escapeChars(DisplayUtils.formatName(user.getFirstName(),user.getLastName(),true));
            if (name.length()==0)
            {
                name="&nbsp";
            }
            out.write( name );
            out.write("</td>");

            // Email
            out.write("<td>");            
            String emailAddrDisplay=user.getEmailAddress();
            if (emailAddrDisplay==null || emailAddrDisplay.length()==0)
            {
                emailAddrDisplay="&nbsp;";
            }
            else
            {
                emailAddrDisplay=HtmlUtils.escapeChars(emailAddrDisplay);
            }
            out.write(emailAddrDisplay);
            out.write("</td>");            

            if (isCurrentUserAdmin)
            {
                // Admin access
                out.write("<td>");
                if (user.getIsAdmin())
                {
                    out.write(bundle.getString("yesLabel"));
                }
                else
                {
                    out.write("&nbsp;");
                }
                out.write("</td>");
    
                // Default Role
                out.write("<td>");
                Role role=(Role)roles.get(new Long(user.getDefaultRoleId()));
                if (role!=null)
                {
                    out.write(HtmlUtils.escapeChars(role.getDesc()));
                }
                else
                {
                    out.write("&nbsp;");
                }
                out.write("</td>");
                
                // Default Shift Template
                out.write("<td>");
                ShiftTemplate shiftTemplate=(ShiftTemplate)shiftTemplates.get(new Long(user.getDefaultShiftTemplateId()));
                if (shiftTemplate!=null)
                {
                    // Desc
                    out.write(HtmlUtils.escapeChars(shiftTemplate.getDesc()));
                    
                    // Start Time
                    out.write(" - ");
                    out.write( HtmlUtils.escapeChars(DisplayUtils.formatTime(shiftTemplate.getStartTime())) );      
        
                    // Duration
                    out.write(" (");
                    out.write(HtmlUtils.escapeChars(DisplayUtils.formatDuration(shiftTemplate.getDuration())));
                    out.write(")");					
                }
                else
                {
                    out.write("&nbsp;");
                }                
                out.write("</td>");                
         
                // Actions            
                out.write("<td>");                
                long userId=user.getKey().getId();

                // Edit
                out.write("<a href=\"user_edit.jsp?userId=" + userId + "\">" + bundle.getString("editLabel") + "</a>");

                // Delete
                if (isCurrentUserAdmin)
                {
                    out.write(" <a href=\"user_delete.jsp?userId=" + userId + "\">" + bundle.getString("deleteLabel") + "</a>");
                }
                out.write("</td>");                
            }
            
            out.write("</tr>");                
        }

        out.write("</table>");
    }
    else
    {
        out.write("<p>" + bundle.getString("noneLabel") + "</p>");
    }
%>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>