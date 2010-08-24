<%-- This JSP has the HTML for the user shift switch select options.  TODO - Delete if not needed. --%>
<%@ page language="java"%>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="sched.data.model.Role" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.data.model.User" %>
<%@ page import="sched.data.model.UserShift" %>
<%@ page import="sched.utils.DateUtils" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%
    // If there are shifts, create a list.
    Map shifts=(Map)request.getAttribute("userShifts");

    if (shifts!=null && !shifts.isEmpty())
    {
        // Roles and shift templates
        Map<Long,Role> roles=(Map<Long,Role>)RequestUtils.getRoles(request);
		Map<Long,ShiftTemplate> shiftTemplates=RequestUtils.getShiftTemplates(request);
        Map<Long,User> users=(Map<Long,User>)RequestUtils.getUsers(request);

        SimpleDateFormat displayDateTime=new SimpleDateFormat("yyyy MMM dd EEE h:mm aa");
        displayDateTime.setTimeZone(RequestUtils.getCurrentStore(request).getTimeZone());

        Iterator iter = shifts.entrySet().iterator();
        while (iter.hasNext())
        {
            Entry entry = (Entry)iter.next();
            UserShift userShift=(UserShift)entry.getValue();

            long userShiftId=userShift.getKey().getId();

            Date startDate=(Date)userShift.getStartDate();
            Date endDate=DateUtils.getEndDate(userShift.getStartDate(),userShift.getDuration());

            // Get role description
            Role role=(Role)roles.get(new Long(userShift.getRoleId()));
            String roleDesc=null;
            if (role!=null)
            {
                roleDesc=HtmlUtils.escapeChars(role.getDesc());
            }

            // Get shift template description
            ShiftTemplate shiftTemplate=(ShiftTemplate)shiftTemplates.get(new Long(userShift.getShiftTemplateId()));
            String shiftTemplateDesc=null;
            if (shiftTemplate!=null)
            {
                shiftTemplateDesc=HtmlUtils.escapeChars(shiftTemplate.getDesc());
            }

            // Option
            out.write("<option");

            // Selected
            //if (userIdSelect==userId)
            //{
            //    out.write(" selected=\"true\"");
            //}

            out.write(" value=\"");
            out.write( new Long(userShiftId).toString() );
            out.write("\">");

            // Start to End
            out.write(HtmlUtils.escapeChars(displayDateTime.format(startDate)));
            out.write(" to ");
            out.write(HtmlUtils.escapeChars(displayDateTime.format(endDate)));
            out.write(" - ");

            out.write(HtmlUtils.escapeChars(DisplayUtils.formatDuration(userShift.getDuration())));

            // Don't write if no role.
            if (userShift.getRoleId()!=Role.NO_ROLE)
            {
                out.write(" - ");
                out.write(roleDesc);
            }

            // Don't write if no shift.
            if (userShift.getShiftTemplateId()!=ShiftTemplate.NO_SHIFT)
            {
                out.write(" - ");
                out.write(shiftTemplateDesc);
            }

            // Add user
            Long userIdLong=new Long(userShift.getUserId());
            if (users.containsKey(userIdLong))
            {
                User user=(User)users.get(userIdLong);

                out.write(" - ");
                out.write(HtmlUtils.escapeChars(DisplayUtils.formatName(user.getFirstName(),user.getLastName(),true)));
            }

            out.write("</option>");
        }
    }
%>