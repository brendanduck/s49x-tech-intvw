#region Namespaces
using System;
using System.Data;
using System.Collections.Generic;
using Microsoft.SqlServer.Dts.Pipeline.Wrapper;
using Microsoft.SqlServer.Dts.Runtime.Wrapper;
#endregion
//
// icao dob match scoring 
// 20151215 Brendan Duck
//
// Takes two dates represented as strings in the format 'YYYY-MM-DD' and returns a score out of 100
//


[Microsoft.SqlServer.Dts.Pipeline.SSISScriptComponentEntryPointAttribute]
public class ScriptMain : UserComponent
{

    public override void PreExecute()
    {
        base.PreExecute();
    }

    public override void PostExecute()
    {
        base.PostExecute();
    }

    private int[] yearRanges =  {1,5,10,15};


    private string aYear;
    private string aMonth;
    private string aDay;
    private string bYear;
    private string bMonth;
    private string bDay;
    private string aDayTrans;
    private string bDayTrans;
    private string aMonthTrans;
    private string bMonthTrans;
    private string aYearTrans;
    private string bYearTrans;
    private int aYearNum;
    private int bYearNum;
    private int aYearTransNum;
    private int bYearTransNum;
    private int score;

    public override void Input0_ProcessInputRow(Input0Buffer Row)
    {
        // reset before processing each row
        aYear = "0000";
        aMonth = "00";
        aDay = "00";
        bYear = "0000";
        bMonth = "00";
        bDay = "00";
        aDayTrans = "00";
        bDayTrans = "00";
        aMonthTrans = "00";
        bMonthTrans = "00";
        aYearTrans = "0000";
        bYearTrans = "0000";
        aYearNum = 0;
        bYearNum = 0;
        aYearTransNum = 0;
        bYearTransNum = 0;
        score = 0;


        // split up the first date
        if (Row.PADOB.Length > 0)
        {
			aYear = Row.PADOB.Split('-')[0];
            aMonth = Row.PADOB.Split('-')[1];
			aDay = Row.PADOB.Split('-')[2];
            aDayTrans = Reverse(aDay);
            aMonthTrans = Reverse(aMonth);
            aYearTrans = Row.PADOB.Substring(0, 2) + Row.PADOB.Substring(3,1) + Row.PADOB.Substring(2,1);
            aYearNum = Int32.Parse(aYear);
            aYearTransNum = Int32.Parse(aYearTrans);
        }

        // split up the second date
        if (Row.DDDOB.Length > 0)
        {
            bYear = Row.DDDOB.Split('-')[0];
			bMonth = Row.DDDOB.Split('-')[1];
            bDay = Row.DDDOB.Split('-')[2];
            bDayTrans = Reverse(bday);
            bMonthTrans = Reverse(bMonth);
            bYearTrans = Row.DDDOB.Substring(0, 2) + Row.DDDOB.Substring(3,1) + Row.DDDOB.Substring(2,1);
            bYearNum = Int32.Parse(bYear);
            bYearTransNum = Int32.Parse(bYearTrans);
        }


        //determine score
        if (Row.PADOB == Row.DDDOB) //a
        {
            score = 100;
        }
        else if ((aYear == "0000") || (bYear == "0000")) //b
        {
            score = 80;
        }
        else if (((aMonth == bMonth) && ((aDay == bDay) || (aDay == "00") || (bDay == "00"))) || ((aDay == bDay) && ((aMonth == bMonth)||(aMonth == "00") || (bMonth == "00")))) //c
        {
            if((Math.Abs(aYearNum - bYearNum)) <= yearRanges[1])
            {
                score = 75;
            }
            else if (aYearTrans == bYearTrans)
            {
                score = 40;
            }
            else if ((Math.Abs(aYearNum - bYearNum)) <= yearRanges[2])
            {
                score = 55;
            }
            else if( (Math.Abs(aYearTransNum - bYearTransNum)) <= yearRanges[2])
            {
                score = 30;
            }
            else if ((Math.Abs(aYearNum - bYearNum)) <= yearRanges[3])
            {
                score = 10;
            }
        }
        else if ((aYear == bYear) && ((aDay == bDay) || (aDay == "00") || (bDay == "00")))
        {
            if (aMonthTrans == bMonthTrans)
            {
                score = 40;
            }
            else
            {
                score = 60;
            }
        }
        else if ((aYear == bYear) && ((aMonth == bMonth) || (aMonth == "00") || (bMonth == "00")))
        {
            if (aDayTrans == bDayTrans)
            {
                score = 70;
            }
            else
            {
                score = 60;
            }
         }
        else if ((aMonth == bDay) || (bMonth == aDay))
        {
            if (aYear == bYear)
            {
                score = 70;
            }
            else if ((Math.Abs(aYearNum - bYearNum)) <= yearRanges[2])
            {
                score = 30;
            }
        }
        else if (aYear == bYear)
        {
            score = 50;
        }
        else if ((Math.Abs(aYearNum - bYearNum)) <= yearRanges[1])
        {
            score = 30;
        }

        Row.dobScore = score;
    }


    // string reverse function
	public static string Reverse(string s)
    {
        char[] charArray = s.ToCharArray();
        Array.Reverse(charArray);
        return new string(charArray);
    }

}
