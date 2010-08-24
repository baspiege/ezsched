<%-- This JSP creates a list of shift template select options. --%>
<%@ page language="java"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="sched.data.model.ShiftTemplate" %>
<%@ page import="sched.utils.DisplayUtils" %>
<%@ page import="sched.utils.HtmlUtils" %>
<%@ page import="sched.utils.RequestUtils" %>
<%@ page import="sched.utils.SessionUtils" %>
<%

    ResourceBundle bundle = ResourceBundle.getBundle("Text", SessionUtils.getLocale(request));

    boolean showShiftTempateDescOnly=((Boolean)request.getAttribute("showShiftTemplateDescOnly")).booleanValue();

    Map<Long,ShiftTemplate> shiftTemplates=(Map<Long,ShiftTemplate>)RequestUtils.getShiftTemplates(request);
    if (shiftTemplates!=null && !shiftTemplates.isEmpty())
    {
        Long shiftTemplateIdSelect=(Long)request.getAttribute("shiftTemplateId");
        if (shiftTemplateIdSelect==null)
        {
            shiftTemplateIdSelect=new Long(ShiftTemplate.ALL_SHIFTS);
        }

        Iterator iter = shiftTemplates.entrySet().iterator();

        while (iter.hasNext())
        {
            Entry entry = (Entry)iter.next();
            Long shiftTemplateId=(Long)entry.getKey();
            ShiftTemplate shiftTemplate=(ShiftTemplate)entry.getValue();

            out.write("<option");

            // Selected
            if (shiftTemplateIdSelect.equals(shiftTemplateId))
            {
                out.write(" selected=\"true\"");
            }

            out.write(" value=\"");
            out.write( shiftTemplateId.toString() );
            out.write("\">");
            out.write( HtmlUtils.escapeChars(shiftTemplate.getDesc()) );

            if (!showShiftTempateDescOnly)
            {
                // Start Time
                out.write(" - ");
                out.write( HtmlUtils.escapeChars(DisplayUtils.formatTime(shiftTemplate.getStartTime())) );

                // Duration
                out.write(" (");
                out.write(HtmlUtils.escapeChars(DisplayUtils.formatDuration(shiftTemplate.getDuration())));
                out.write(")");
            }

            out.write("</option>");
        }

        out.write("<option value=\"" + ShiftTemplate.NO_SHIFT + "\"");

        // No ShiftTemplate Selected
        if (shiftTemplateIdSelect.equals(new Long(ShiftTemplate.NO_SHIFT)))
        {
            out.write(" selected=\"true\"");
        }

        out.write("\">");

        // Name vs Template
        if (showShiftTempateDescOnly)
        {
            out.write(bundle.getString("noShiftNameLabel"));
        }
        else
        {
            out.write(bundle.getString("noShiftTemplateLabel"));
        }

        out.write("</option>");
    }
    else
    {
        out.write("<option value=\"" + ShiftTemplate.NO_SHIFT + "\">" + bundle.getString("noShiftTemplatesAddedLabel") + "</option>");
    }
%>