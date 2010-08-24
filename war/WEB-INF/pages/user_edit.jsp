<%-- This JSP has the HTML for the user update page. --%>
<%@ page language="java"%>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.UserGetSingle" %>
<%@ page import="sched.data.UserUpdate" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));                    

    // If cancel, forward right away.
    String action=RequestUtils.getAlphaInput(request,"action","Action",false);
    if (action!=null && action.equals(bundle.getString("cancelLabel")))
    {
        request.setAttribute("roleId",null);
        request.setAttribute("shiftTemplateId",null);		
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/WEB-INF/pages/user.jsp"/>
        <%
    }

    // Set the current store into the request.
    SessionUtils.setCurrentStoreIntoRequest(request);

    // Verify user is logged on.
    // Verify user has access to the store.
    if (!SessionUtils.isLoggedOn(request)
        || !RequestUtils.isCurrentUserInStore(request))
    {
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
        // Forward them to the user page.
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/user.jsp"/>
        <%
    }    
    
    // Get Id
    Long userIdRequest=RequestUtils.getNumericInput(request,"userId",bundle.getString("userIdLabel"),true);
    if (userIdRequest==null)
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/user.jsp"/>
        <%
    }

    // Set fields
    boolean isAdmin=false;
    String firstName="";
    String lastName="";
    String emailAddr="";
    Long defaultRoleId=new Long(Role.NO_ROLE);
    Long defaultShiftTemplateId=new Long(ShiftTemplate.NO_SHIFT);	

    // Get user info
    if (!RequestUtils.hasEdits(request))
    {
        new UserGetSingle().execute(request);

        // Set roles. Needed for role drop down.
        RequestUtils.getRoles(request);		

        User user=(User)request.getAttribute("user");
        if (user==null)
        {
            RequestUtils.resetAction(request);
            RequestUtils.removeEdits(request);
            %>
            <jsp:forward page="/user.jsp"/>
            <%
        }
        
        // Set fields
        isAdmin=user.getIsAdmin();
        firstName=user.getFirstName();
        lastName=user.getLastName();
        emailAddr=user.getEmailAddress();
        defaultRoleId=new Long(user.getDefaultRoleId());
        defaultShiftTemplateId=new Long(user.getDefaultShiftTemplateId());		

        // Set roleId into the request so it's selected in roleSelectOptions component
        if (defaultRoleId!=null)
        {
            request.setAttribute("roleId",defaultRoleId);
        }

        // Set shiftTemplateId into the request so it's selected in shiftTemplateSelectOptions component
        if (defaultShiftTemplateId!=null)
        {
            request.setAttribute("shiftTemplateId",defaultShiftTemplateId);
        }		

        // Process based on action
        if (action!=null && action.length()!=0 && !RequestUtils.isForwarded(request))
        {
            if (action.equals(bundle.getString("updateLabel")))
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
                    // If none, use no role.
                    defaultRoleId=new Long(Role.NO_ROLE);
                    request.setAttribute("defaultRoleId",defaultRoleId);
                }
                
                // Shift Template Id
                defaultShiftTemplateId=RequestUtils.getNumericInput(request,"defaultShiftTemplateId",bundle.getString("defaultShiftTemplateLabel"),false);
                if (defaultShiftTemplateId==null)
                {
                    // If none, use no shift.				
                    defaultShiftTemplateId=new Long(ShiftTemplate.NO_SHIFT);
                    request.setAttribute("defaultShiftTemplateId",defaultShiftTemplateId);
                }				

                // Set roleId into the request so it's selected in roleSelectOptions component
                request.setAttribute("roleId",defaultRoleId);
    
                if (!RequestUtils.hasEdits(request))
                {
                    new UserUpdate().execute(request);
                }
    
                // If the user changes their own email, forward to logon so they re-enter the site.
                Boolean userChangedOwnEmailAddress=(Boolean)request.getAttribute("userChangedOwnEmailAddress");
                if (userChangedOwnEmailAddress!=null && userChangedOwnEmailAddress.booleanValue())
                {
                    RequestUtils.resetAction(request);
                    RequestUtils.removeEdits(request);
                    %>
                    <jsp:forward page="/logonForward.jsp"/>
                    <%
                }

                // If successful, go back to user page.
                if (!RequestUtils.hasEdits(request))
                {
                    request.setAttribute("roleId",null);
                    request.setAttribute("shiftTemplateId",null);
                    
                    RequestUtils.resetAction(request);

                    // Route to user page.
                    %>
                    <jsp:forward page="/user.jsp"/>
                    <%
                }
            }
        }
    }
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request)) %> - <%= bundle.getString("editUserLabel") %></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

<form id="updates" method="post" action="user_edit.jsp?userId=<%=userIdRequest%>" autocomplete="off">
    <fieldset class="action">
      <legend><b><%= bundle.getString("editUserLabel") %></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

    <table>
    <tr><td><label for="firstName"><%= bundle.getString("firstNameLabel") %> (<%= bundle.getString("requiredLabel") %>)</label></td><td><input type="text" name="firstName" title="<%= bundle.getString("firstNameLabel") %>" value="<%=HtmlUtils.escapeChars(firstName)%>" id="firstName" maxlength="100"/></td></tr>
    <tr><td><label for="lastName"><%= bundle.getString("lastNameLabel") %></label></td><td><input type="text" name="lastName" title="<%= bundle.getString("lastNameLabel") %>" value="<%=HtmlUtils.escapeChars(lastName)%>" id="lastName" maxlength="100"/></td></tr>
    <tr><td><label for="emailAddr"><%= bundle.getString("emailAddressLabel") %><sup><small>*</small></sup></label></td><td><input type="text" name="emailAddr" title="<%= bundle.getString("emailAddressLabel") %>" value="<%=HtmlUtils.escapeChars(emailAddr)%>" id="emailAddr" maxlength="100"/></td></tr>

    <tr><td><label for="isAdmin"><%= bundle.getString("adminAccessLabel") %></label></td><td>
        <select name="isAdmin" title="<%= bundle.getString("adminAccessLabel") %>" id="isAdmin">
        <option value="false" <%= !isAdmin?"selected=true":"" %>><%= bundle.getString("noLabel") %></option>
        <option value="true" <%= isAdmin?"selected=true":"" %>><%= bundle.getString("yesLabel") %></option>
        </select></td>
    </tr>

    <tr>
      <td><label for="defaultRoleId"><%= bundle.getString("defaultRoleLabel") %></label></td>
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

    <p><sup><small>*</small></sup><%= bundle.getString("userEmailSignInFootnote")%> <%= bundle.getString("userEmailChangeFootnote")%> </p> 

    <input type="submit" name="action" value="<%= bundle.getString("updateLabel")%>"/> <input type="submit" name="action" value="<%= bundle.getString("cancelLabel")%>"/>
    </fieldset>
</form>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>