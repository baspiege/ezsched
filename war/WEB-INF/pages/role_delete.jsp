<%-- This JSP has the HTML for the role delete page. --%>
<%@ page language="java"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.RoleDelete" %>
<%@ page import="sched.data.RoleGetSingle" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%@ page import="sched.utils.StringUtils" %>
<%
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));   

    // If cancel, forward right away.
    String action=RequestUtils.getAlphaInput(request,"action","Action",false);
    if (action!=null && action.equals(bundle.getString("cancelLabel")))
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/WEB-INF/pages/role.jsp"/>
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
        // Forward them to the sched page.  Can't forward to role.
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/sched.jsp"/>
        <%
    }

    // Get Role Id
    Long roleIdRequest=RequestUtils.getNumericInput(request,"roleId",bundle.getString("roleIdLabel"),true);
    if (roleIdRequest==null)
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/role.jsp"/>
        <%
    }

    // Display name
    String desc="";

    // Get role info
    if (!RequestUtils.hasEdits(request))
    {
        new RoleGetSingle().execute(request);
        Role role=(Role)request.getAttribute("role");

        if (role==null)
        {
            RequestUtils.resetAction(request);
            RequestUtils.removeEdits(request);
            %>
            <jsp:forward page="/role.jsp"/>
            <%
        }

        // Set fields
        desc=role.getDesc();
    }
    else
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/role.jsp"/>
        <%
    }

    // Forward based on action
    if (!StringUtils.isEmpty(action) && action.length()!=0 && !RequestUtils.isForwarded(request))
    {
        Long token=RequestUtils.getNumericInput(request,"csrfToken","CSRF Token",true);
        if (!SessionUtils.isCSRFTokenValid(request,token))
        {
            %>
            <jsp:forward page="/logonForward.jsp"/>
            <%
        }
    
        if (action.equals(bundle.getString("deleteLabel")))
        {
            new RoleDelete().execute(request);

            // If successful, go back to role page.
            if (!RequestUtils.hasEdits(request))
            {
                RequestUtils.resetAction(request);

                // Route to role page.
                %>
                <jsp:forward page="/role.jsp"/>
                <%
            }
        }
    }
%>

<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request)) %> - <%= bundle.getString("deleteRoleLabel")%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

<form id="updates" method="post" action="role_delete.jsp">

  <fieldset class="action">
    <legend><b><%= bundle.getString("deleteRoleLabel")%></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

    <p><%= HtmlUtils.escapeChars(desc) %> - <%= bundle.getString("deleteRoleConfSentence1") %> <%= bundle.getString("deleteRoleConfSentence2") %></p>
    <input type="submit" name="action" value="<%= bundle.getString("deleteLabel") %>" />
    <input type="submit" name="action" value="<%= bundle.getString("cancelLabel") %>"/>
    <input type="hidden" name="roleId" value="<%=roleIdRequest%>"/>
    <input type="hidden" name="csrfToken" value="<%= SessionUtils.getCSRFToken(request) %>"/>
    </fieldset>
</form>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>