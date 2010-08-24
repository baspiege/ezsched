<%-- This JSP has the HTML for the help page.--%>
<%@ page language="java"%>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.UserSetCurrent" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%
    // Set the current store into the request.
    SessionUtils.setCurrentStoreIntoRequest(request);

    // Set user if there is a store.
    if (RequestUtils.getCurrentStore(request)!=null)
    {
        new UserSetCurrent().execute(request);
    }
    
    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));        
%>
<%@ include file="/WEB-INF/pages/components/noCache.jsp" %>
<%@ include file="/WEB-INF/pages/components/docType.jsp" %>
<title><%= bundle.getString("helpLabel")%></title>
<link type="text/css" rel="stylesheet" href="/stylesheets/main.css" />
<style type="text/css">
li {margin-bottom: 1em;}
</style>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" /></head>
<body>

<%-- Get nav based on authentication. --%>
<%@ page import="sched.utils.SessionUtils" %>
<%
    String heading="<h1>" + bundle.getString("helpLabel") + "</h1>";

    // If user is logged on, use full nav.
    if (SessionUtils.isLoggedOn(request))
    {
        %>
        <jsp:include page="/WEB-INF/pages/components/navLinks.jsp"/>
        <%
        out.write(heading);
    }
    else
    {
        %>
        <div style="float:left;">
        <p><a href="logon.jsp"><%= bundle.getString("homeLabel")%></a></p>
        </div>
        <jsp:include page="/WEB-INF/pages/components/navLinksPreAuth.jsp"/>
        <%
        out.write(heading);
    }
%>

<ol>
<li> <%= bundle.getString("helpQ1")%></li>
<li> <%= bundle.getString("helpQ2")%></li>
<li> <%= bundle.getString("helpQ3")%></li>
</ol>

<jsp:include page="/WEB-INF/pages/components/footer.jsp"/>
</body>
</html>