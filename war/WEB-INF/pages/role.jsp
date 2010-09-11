<%-- This JSP has the HTML for the role page.--%>
<%@ page language="java"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.RoleAdd" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.User" %>
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

    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));                
    
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

    // Default
    boolean allUserUpdateAccess=false;
    String desc="";

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
            desc=RequestUtils.getAlphaInput(request,"desc",bundle.getString("descriptionLabel"),true);

            // Optional
            allUserUpdateAccess=RequestUtils.getBooleanInput(request,"allUserUpdateAccess",bundle.getString("allUserUpdateAccessLabel"),false);

            if (!RequestUtils.hasEdits(request))
            {
                new RoleAdd().execute(request);
            }

            // If successful, reset form.
            if (!RequestUtils.hasEdits(request))
            {
                desc="";
                allUserUpdateAccess=false;
            }
        }
    }

    String title=HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request));
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= title %> <%= bundle.getString("rolesLabel") %></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

  <form id="role" method="post" action="role.jsp" autocomplete="off">
    <fieldset class="action">
      <legend><b><%= bundle.getString("addRoleLabel") %></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

      <table>
        <tr><td><label for="desc"><%= bundle.getString("descriptionLabel") %> (<%= bundle.getString("requiredLabel") %>)</label></td><td><input type="text" name="desc" value="<%= HtmlUtils.escapeChars(desc) %>" id="desc" maxlength="100" title="<%= bundle.getString("descriptionLabel") %>"/></td></tr>
        <tr><td><label for="allUserUpdateAccess"><%= bundle.getString("allUserUpdateAccessLabel") %><sup><small>*</small></sup></label></td><td>
            <select name="allUserUpdateAccess" title="<%= bundle.getString("allUserUpdateAccessLabel") %>" id="allUserUpdateAccess">
            <option value="false" <%= !allUserUpdateAccess?"selected=true":"" %>><%= bundle.getString("noLabel") %></option>
            <option value="true" <%= allUserUpdateAccess?"selected=true":"" %>><%= bundle.getString("yesLabel") %></option>
            </select></td>
        </tr>

      </table>
      
      <p><sup><small>*</small></sup><%= bundle.getString("allUserUpdateAccessFootnote") %></p> 
      
      <input type="hidden" name="csrfToken" value="<%= SessionUtils.getCSRFToken(request) %>"/>
      <input type="submit" name="action" value="<%= bundle.getString("addLabel") %>"></input>
    </fieldset>
  </form>

<h1><%= title %> <%= bundle.getString("rolesLabel") %></h1>

<%
    Map<Long,Role> roles=RequestUtils.getRoles(request);

    if (roles!=null && !roles.isEmpty())
    {
        out.write("<table border=\"1\" style=\"text-align:left;\"><tr>");
        out.write("<th>" + bundle.getString("descriptionLabel") + "</th>");
        out.write("<th>" + bundle.getString("allUserUpdateAccessLabel") + "</th>");
        

        // If non-admins, can do actions, update the logic below.
        if (isCurrentUserAdmin)
        {
            out.write("<th>" + bundle.getString("actionLabel") + "</th>");
        }
        out.write("</tr>");

        Iterator iter = roles.entrySet().iterator();
        while (iter.hasNext())
        {
            Entry entry = (Entry)iter.next();
            Role role=(Role)entry.getValue();

            out.write("<tr>");            
            
            // Display desc
            out.write("<td>");
            out.write( HtmlUtils.escapeChars(role.getDesc()) );
            out.write("</td>");            

            // Can all add/edit/delete?
            out.write("<td>");
            if (role.getAllUserUpdateAccess())
            {
                out.write(bundle.getString("yesLabel"));
            }
            else
            {
                out.write("&nbsp;");
            } 
            out.write("</td>");            

            // Update
            if (isCurrentUserAdmin)
            {
                long roleId=role.getKey().getId();
            
                out.write("<td>");
                out.write("<a href=\"role_edit.jsp?roleId=" + roleId);
                out.write("\">" + bundle.getString("editLabel") + "</a>");

                out.write(" <a href=\"role_delete.jsp?roleId=" + roleId);
                out.write("\">" + bundle.getString("deleteLabel") + "</a>");
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