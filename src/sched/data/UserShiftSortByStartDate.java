package sched.data;

import java.util.Comparator;
import java.util.Date;

import sched.data.model.UserShift;

/**
 * Comparator for sorting user shift by start date - descending.
 *
 * @author Brian Spiegel
 */
public class UserShiftSortByStartDate implements Comparator
{

    /**
     * Compare based on start date.
     *
     * @param aUserShift1 shift 1
     * @param aUserShift2 shift 2
     * @return an int indicating the result of the comparison
     */
    public int compare(Object aUserShift1, Object aUserShift2)
    {
        // Parameter are of type Object, so we have to downcast it
        Date date1=((UserShift)aUserShift1).getStartDate();
        Date date2=((UserShift)aUserShift2).getStartDate();

        return date2.compareTo(date1);
    }
}
