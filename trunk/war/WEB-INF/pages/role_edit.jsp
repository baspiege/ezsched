<%-- This JSP has the HTML for the role update page.--%>
<%@ page language="java"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.RoleGetSingle" %>
<%@ page import="sched.data.RoleUpdate" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
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
        // Forward them to the role page.
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/role.jsp"/>
        <%
    }
   
    // Get Id
    Long roleIdRequest=RequestUtils.getNumericInput(request,"roleId",bundle.getString("roleIdLabel"),true);
    if (roleIdRequest==null)
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/role.jsp"/>
        <%
    }

    // Set fields
    String desc="";
    boolean allUserUpdateAccess=false;

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
        allUserUpdateAccess=role.getAllUserUpdateAccess();	

        // Process based on action
        if (action!=null && action.length()!=0 && !RequestUtils.isForwarded(request))
        {
            if (action.equals(bundle.getString("updateLabel")))
            {
                // Required
                desc=RequestUtils.getAlphaInput(request,"desc",bundle.getString("descriptionLabel"),true);

                // Optional
                allUserUpdateAccess=RequestUtils.getBooleanInput(request,"allUserUpdateAccess",bundle.getString("allUserUpdateAccessLabel"),false);
                    
                if (!RequestUtils.hasEdits(request))
                {
                    new RoleUpdate().execute(request);
                }

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
    }

    String title=HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request));
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= title %> - <%=bundle.getString("editRoleLabel")%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

  <form id="role" method="post" action="role_edit.jsp?roleId=<%=roleIdRequest%>" autocomplete="off">
    <fieldset class="action">
      <legend><b><%=bundle.getString("editRoleLabel")%></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

      <table>

        <tr><td><label for="desc">Description (required)</label></td><td><input type="text" name="desc" value="<%=HtmlUtils.escapeChars(desc)%>" id="desc" maxlength="100" title="Description"/></td></tr>
        <tr><td><label for="allUserUpdateAccess"><%= bundle.getString("allUserUpdateAccessLabel") %><sup><small>*</small></sup></label></td><td>
            <select name="allUserUpdateAccess" title="<%= bundle.getString("allUserUpdateAccessLabel") %>" id="allUserUpdateAccess">
            <option value="false" <%= !allUserUpdateAccess?"selected=true":"" %>><%= bundle.getString("noLabel") %></option>
            <option value="true" <%= allUserUpdateAccess?"selected=true":"" %>><%= bundle.getString("yesLabel") %></option>
            </select></td>
        </tr>
      </table>

      <p><sup><small>*</small></sup><%= bundle.getString("allUserUpdateAccessFootnote") %></p> 

      <input type="submit" name="action" value="<%= bundle.getString("updateLabel") %>"></input> <input type="submit" name="action" value="<%= bundle.getString("cancelLabel") %>"/>
    </fieldset>
  </form>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>