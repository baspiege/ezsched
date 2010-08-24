package sched.utils;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Map;

import sched.data.model.Role;
import sched.data.model.ShiftTemplate;
import sched.data.model.User;
import sched.data.model.UserShift;
import sched.data.model.UserShiftRequestSwitch;

/**
 * Display utilities.
 *
 * @author Brian Spiegel
 */
public class DisplayUtils
{

    /**
    * Get minute select.
    */
    public static String getHourMinuteDisplay(Calendar aCalendar, Date aDate, SimpleDateFormat aHour, SimpleDateFormat aHourMin)
    {
        if (aCalendar.get(Calendar.MINUTE)!=0)
        {
            return aHourMin.format(aDate);
        }
        else
        {
            return aHour.format(aDate);
        }
    }

    /**
     * Format duration.
     *
     * @param aMinutes minutes
     *
     * @return a formatted name
     */
    public static String formatDuration(int aMinutes)
    {
        int hours=0;
        int minutes=0;

        if (aMinutes!=0)
        {
            hours=aMinutes/60;
            minutes=aMinutes%60;
        }

        String display=new Integer(hours).toString() + " Hrs " + new Integer(minutes).toString() + " Mins";

        return display;
    }

    /**
     * Format a name.
     *
     * @param aFirstName first name
     * @param aLastName last name
     *
     * @return a formatted name
     */
    public static String formatName(String aFirstName, String aLastName, boolean aLastNameFirst)
    {
        String name=null;

        boolean noFirst=aFirstName==null || aFirstName.length()==0;
        boolean noLast=aLastName==null || aLastName.length()==0;

        if (noFirst && noLast)
        {
            name="";
        }
        else if (noFirst)
        {
            name=aLastName;
        }
        else if (noLast)
        {
            name=aFirstName;
        }
        else
        {
            if (aLastNameFirst)
            {
                name=aLastName + ", " + aFirstName;
            }
            else
            {
                name=aFirstName + " " + aLastName;
            }
        }

        return name;
    }

    /**
     * Format time from minutes to hours, minutes, and AM/PM.
     *
     * @param aMinutes minutes
     *
     * @return a formatted time
     */
    public static String formatTime(int aMinutes)
    {
        int hours=0;
        int minutes=0;

        if (aMinutes!=0)
        {
            hours=aMinutes/60;
            minutes=aMinutes%60;
        }

        StringBuffer timeDisplay=new StringBuffer();
        if (hours==0)
        {
            timeDisplay.append("12");
        }
        else if (hours>13)
        {
            timeDisplay.append(hours-12);
        }
        else
        {
            timeDisplay.append(hours);
        }

        timeDisplay.append(":");

        // Minutes
        if (minutes<10)
        {
            timeDisplay.append("0");
        }
        timeDisplay.append(minutes);

        // Am/Pm
        if (hours>11)
        {
            timeDisplay.append(" PM");
        }
        else
        {
            timeDisplay.append(" AM");
        }

        return timeDisplay.toString();
    }

    /**
     * Format a shift for display.
     *
     * @param aMinutes minutes
     *
     * @return a formatted time
     */
    public static String formatUserShift(UserShift aUserShift, Map<Long,Role> aRoles, Map<Long,ShiftTemplate> aShiftTemplates, Map<Long,User> aUsers, SimpleDateFormat aDisplayDateTime)
    {
        StringBuffer result=new StringBuffer();
        long userShiftId=aUserShift.getKey().getId();

        Date startDate=(Date)aUserShift.getStartDate();
        Date endDate=DateUtils.getEndDate(aUserShift.getStartDate(),aUserShift.getDuration());

        // Get role description
        Role role=(Role)aRoles.get(new Long(aUserShift.getRoleId()));
        String roleDesc=null;
        if (role!=null)
        {
            roleDesc=HtmlUtils.escapeChars(role.getDesc());
        }

        // Get shift template description
        ShiftTemplate shiftTemplate=(ShiftTemplate)aShiftTemplates.get(new Long(aUserShift.getShiftTemplateId()));
        String shiftTemplateDesc=null;
        if (shiftTemplate!=null)
        {
            shiftTemplateDesc=HtmlUtils.escapeChars(shiftTemplate.getDesc());
        }

        // Add user
        result.append("<td>");
        Long userIdLong=new Long(aUserShift.getUserId());
        if (aUsers.containsKey(userIdLong))
        {
            User user=(User)aUsers.get(userIdLong);

            result.append(HtmlUtils.escapeChars(DisplayUtils.formatName(user.getFirstName(),user.getLastName(),true)));
        }
        else
        {
            result.append("&nbsp;");
        }
        result.append("</td>");

        // Start to End
        result.append("<td>");
        result.append(HtmlUtils.escapeChars(aDisplayDateTime.format(startDate)));
        //result.append(" to ");
        //result.append(HtmlUtils.escapeChars(aDisplayDateTime.format(endDate)));
        result.append("</td>");

        // Duration
        result.append("<td>");
        result.append(HtmlUtils.escapeChars(DisplayUtils.formatDuration(aUserShift.getDuration())));
        result.append("</td>");

        // Role
        result.append("<td>");
        if (aUserShift.getRoleId()!=Role.NO_ROLE)
        {
            result.append(roleDesc);
        }
        else
        {
            result.append("&nbsp;");
        }
        result.append("</td>");


        // Shift Name
        result.append("<td>");
        if (aUserShift.getShiftTemplateId()!=ShiftTemplate.NO_SHIFT)
        {
            result.append(shiftTemplateDesc);
        }
        else
        {
            result.append("&nbsp;");
        }
        result.append("</td>");

        return result.toString();
    }
}
