<%-- This JSP has the HTML for the Shift Template delete page. --%>
<%@ page language="java"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.ShiftTemplateDelete" %>
<%@ page import="sched.data.ShiftTemplateGetSingle" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
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
        // Forward them to the sched page.  Can't forward to shift template.
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/sched.jsp"/>
        <%
    }

    // Get Shift Template Id
    Long shiftTemplateIdRequest=RequestUtils.getNumericInput(request,"shiftTemplateId",bundle.getString("shiftTemplateIdLabel"),true);
    if (shiftTemplateIdRequest==null)
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/shiftTemplate.jsp"/>
        <%
    }

    // Display name
    String desc="";

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
    }
    else
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/shiftTemplate.jsp"/>
        <%
    }

    // Forward based on action
    if (!StringUtils.isEmpty(action) && !RequestUtils.isForwarded(request))
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
            new ShiftTemplateDelete().execute(request);

            // If successful, go back to shiftTemplate page.
            if (!RequestUtils.hasEdits(request))
            {
                RequestUtils.resetAction(request);

                // Route to shiftTemplate page.
                %>
                <jsp:forward page="/shiftTemplate.jsp"/>
                <%
            }
        }
    }
%>

<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= HtmlUtils.escapeChars(RequestUtils.getCurrentStoreName(request)) %> - <%= bundle.getString("deleteShiftTemplateLabel")%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>
<jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>

<form id="updates" method="post" action="shiftTemplate_delete.jsp">

  <fieldset class="action">
    <legend><b><%= bundle.getString("deleteShiftTemplateLabel")%></b></legend>

<jsp:include page="/WEB-INF/pages/components/edits.jsp"/>

    <p><%= HtmlUtils.escapeChars(desc) %> - <%= bundle.getString("deleteShiftTemplateConfSentence1") %> <%= bundle.getString("deleteShiftTemplateConfSentence2") %></p>
    <input type="submit" name="action" value="<%= bundle.getString("deleteLabel") %>"/>
    <input type="submit" name="action" value="<%= bundle.getString("cancelLabel") %>"/>
    <input type="hidden" name="shiftTemplateId" value="<%=shiftTemplateIdRequest%>"/>
    <input type="hidden" name="csrfToken" value="<%= SessionUtils.getCSRFToken(request) %>"/>

    </fieldset>
</form>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>