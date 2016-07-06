#region Namespaces
using System;
using System.Data;
using Microsoft.SqlServer.Dts.Pipeline.Wrapper;
using Microsoft.SqlServer.Dts.Runtime.Wrapper;
using System.Collections.Generic;
using System.Linq;
#endregion
 
 
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
 
    private int qGramSize = 2;
 
    public override void Input0_ProcessInputRow(Input0Buffer Row)
    {
        List<string> firstSet = new List<string>();
        List<string> secondSet = new List<string>();
        List<string> qGrams = new List<string>();
        List<string> firstQGrams = new List<string>();
        List<string> secondQGrams = new List<string>();
        var firstScore = 0;
        var secondScore = 0;
 
        //add inputput strings to a list
        firstSet.Add(Row.fNameA);
        firstSet.Add(Row.gNameA);
        secondSet.Add(Row.fNameB);
        secondSet.Add(Row.gNameB);
 
        for(var lnx = 0; lnx < firstSet.Count; lnx++)
        {
            for (var inx = 0; inx < firstSet[lnx].Length - 1; inx++)
            {
                qGrams.Add(firstSet[lnx].Substring(inx, qGramSize));
                firstQGrams.Add(firstSet[lnx].Substring(inx, qGramSize));
            }
        }
 
        for (var lnx = 0; lnx < secondSet.Count; lnx++)
        {
            for (var inx = 0; inx < secondSet[lnx].Length - 1; inx++)
            {
                qGrams.Add(secondSet[lnx].Substring(inx, qGramSize));
                secondQGrams.Add(secondSet[lnx].Substring(inx, qGramSize));
            }
        }
 
 
        qGrams = qGrams.Distinct().ToList();
        firstQGrams = firstQGrams.Distinct().ToList();
        secondQGrams = secondQGrams.Distinct().ToList();
 
 
        // compare set 1
        for (var knx = 0; knx < qGrams.Count; knx++)
        {
            for (var bnx = 0; bnx < firstQGrams.Count; bnx++)
            {
                if (qGrams[knx] == firstQGrams[bnx])
                    firstScore++;
            }
        }
 
        // compare set 2
        for (var knx = 0; knx < qGrams.Count; knx++)
        {
            for (var bnx = 0; bnx < secondQGrams.Count; bnx++)
            {
                if (qGrams[knx] == secondQGrams[bnx])
                    secondScore++;
            }
        }
 
        Row.score = (((double)firstScore + secondScore) / (qGrams.Count * 2)) * 100;
 
    }   
 
}
