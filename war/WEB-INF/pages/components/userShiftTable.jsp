<%-- This JSP has the HTML for the user shift table. --%>
<%@ page language="java"%>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.data.model.UserShift" %>
<%@ page import="sched.utils.DateUtils" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%
    // If there are shifts, create a list.
    List shifts=(List)request.getAttribute("userShifts");

    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));

    if (shifts!=null && !shifts.isEmpty())
    {
        // Users, roles, and shift templates
        Map<Long,User> users=(Map<Long,User>)RequestUtils.getUsers(request);
        Map<Long,Role> roles=(Map<Long,Role>)RequestUtils.getRoles(request);
		Map<Long,ShiftTemplate> shiftTemplates=RequestUtils.getShiftTemplates(request);

        out.write("<table border=\"1\" style=\"text-align:left;\"><tr>");
        out.write("<th>" + bundle.getString("userLabel") + "</th>");
        out.write("<th>" + bundle.getString("startTimeLabel") + "</th>");
        out.write("<th>" + bundle.getString("endTimeLabel") + "</th>");
        out.write("<th>" + bundle.getString("durationLabel") + "</th>");
        out.write("<th>" + bundle.getString("roleLabel") + "</th>");
        out.write("<th>" + bundle.getString("shiftNameLabel") + "</th>");
        out.write("</tr>");

        SimpleDateFormat displayDateTime=new SimpleDateFormat("yyyy MMM dd EEE h:mm aa", SessionUtils.getLocale(request));
        displayDateTime.setTimeZone(RequestUtils.getCurrentStore(request).getTimeZone());

        for (int i=0;i<shifts.size();i++)
        {
            UserShift userShift=(UserShift)shifts.get(i);

            Date startDate=(Date)userShift.getStartDate();
            Date endDate=DateUtils.getEndDate(userShift.getStartDate(),userShift.getDuration());

            // Get role description
            Role role=(Role)roles.get(new Long(userShift.getRoleId()));
            String roleDesc=null;
            if (role!=null)
            {
                roleDesc=HtmlUtils.escapeChars(role.getDesc());
            }
            else
            {
                roleDesc="&nbsp;";
            }

            // Get role description
            User user=(User)users.get(new Long(userShift.getUserId()));
            String userName=null;
            if (user!=null)
            {
                userName=HtmlUtils.escapeChars(DisplayUtils.formatName(user.getFirstName(),user.getLastName(),false));
            }
            else
            {
                userName="&nbsp;";
            }

            // Get shift template description
            ShiftTemplate shiftTemplate=(ShiftTemplate)shiftTemplates.get(new Long(userShift.getShiftTemplateId()));
            String shiftTemplateDesc=null;
            if (shiftTemplate!=null)
            {
                shiftTemplateDesc=HtmlUtils.escapeChars(shiftTemplate.getDesc());
            }
            else
            {
                shiftTemplateDesc="&nbsp;";
            }

            out.write("<tr>");

            // User
            out.write("<td>");
			out.write( userName );
            out.write("</td>");

            // Start time
            out.write("<td>");
            out.write(HtmlUtils.escapeChars(displayDateTime.format(startDate)));
            out.write("</td>");

            // End time
            out.write("<td>");
            out.write(HtmlUtils.escapeChars(displayDateTime.format(endDate)));
            out.write("</td>");

            // Duration
            out.write("<td>");
            out.write(HtmlUtils.escapeChars(DisplayUtils.formatDuration(userShift.getDuration())));
            out.write("</td>");

            // Role
            out.write("<td>");
            out.write(roleDesc);
            out.write("</td>");

            // Shift name
            out.write("<td>");
            out.write(shiftTemplateDesc);
            out.write("</td>");

            out.write("</tr>");
        }

        out.write("</table>");
    }
    else
    {
        out.write("<p>" + bundle.getString("noneLabel") + "</p>");
    }
%>