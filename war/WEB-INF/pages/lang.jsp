<%-- This JSP has the routing logic for the language page.--%>
<%@ page language="java"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="sched.data.RoleAdd" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%
    // Set the current store into the request.
    SessionUtils.setCurrentStoreIntoRequest(request);
       
    // Get lange attribute.
    String locale=RequestUtils.getLocaleInput(request,"locale","Locale",true);

    if (locale!=null)
    {
        SessionUtils.setLocale(request,locale);       
    }
       
    // Verify user is logged on.
    // Verify user has access to the store.
    if (!SessionUtils.isLoggedOn(request)
        || !RequestUtils.isCurrentUserInStore(request))
    {
        RequestUtils.resetAction(request);
        RequestUtils.removeEdits(request);
        %>
        <jsp:forward page="/logon.jsp"/>
        <%
    }
    else
    {
        %>
        <jsp:forward page="/store.jsp"/>
        <%    
    }
%>