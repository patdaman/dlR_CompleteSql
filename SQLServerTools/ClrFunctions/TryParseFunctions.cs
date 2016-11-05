using System;
using System.Data.SqlTypes;

public partial class UserDefinedFunctions
{
    ///-------------------------------------------------------------------------------------------------
    /// <summary>   Parse date time. </summary>
    ///
    /// <remarks>   Pdelosreyes, 20160302. </remarks>
    ///
    /// <param name="date">    The date input. </param>
    ///
    /// <returns>   A SqlDateTime. </returns>
    ///-------------------------------------------------------------------------------------------------

    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlDateTime ParseDateTime(SqlString date)
    {
        DateTime dtValue;
        if (DateTime.TryParse(date.ToString(), out dtValue))
            return (DateTime)dtValue;
        return SqlDateTime.Null;
    }

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   Parse double. </summary>
    ///
    /// <remarks>   Pdelosreyes, 20160302. </remarks>
    ///
    /// <param name="number">   Number string </param>
    ///
    /// <returns>   A SqlDouble. </returns>
    ///-------------------------------------------------------------------------------------------------

    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlDouble ParseDouble(SqlString number)
    {
        Double numValue;
        if (Double.TryParse(number.ToString(), out numValue))
            return (Double)numValue;
        return SqlDouble.Null;
    }

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   Parse dirty double. </summary>
    ///
    /// <remarks>   Pdelosreyes, 20160303. </remarks>
    ///
    /// <param name="number">   Number string will be stripped to digits and decimal. </param>
    ///
    /// <returns>   A SqlDouble. </returns>
    ///-------------------------------------------------------------------------------------------------

    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlDouble ParseDirtyDouble(SqlString number)
    {
        Double numValue;
        string regex = @"[^0-9.]";
        number = RegexReplace(number.ToString(), regex, "");
        if (Double.TryParse(number.ToString(), out numValue))
            return (Double)numValue;
        return SqlDouble.Null;
    }

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   Parse boolean. </summary>
    ///
    /// <remarks>   Pdelosreyes, 20160302. </remarks>
    ///
    /// <param name="boolean">  The boolean string. </param>
    ///
    /// <returns>   A SqlBoolean. </returns>
    ///-------------------------------------------------------------------------------------------------

    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlBoolean ParseBoolean(SqlString boolean)
    {
        if (boolean != null)
        {
            Boolean bValue;
            switch (boolean.ToString().ToLower())
            {
                case "true":
                case "1":
                case "yes":
                    return true;
                case "false":
                case "0":
                case "no":
                    return false;
            }
            return (SqlBoolean)(Boolean.TryParse(boolean.ToString(), out bValue));
        }
        return SqlBoolean.Null;
    }

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   Parse int. </summary>
    ///
    /// <remarks>   Pdelosreyes, 20160303. </remarks>
    ///
    /// <param name="integer">  The integer. </param>
    ///
    /// <returns>   A SqlInt32. </returns>
    ///-------------------------------------------------------------------------------------------------

    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlInt32 ParseInt(SqlString integer)
    {
        Int32 iValue;

        if (Int32.TryParse(integer.ToString(), out iValue))
            return (Int32)iValue;
        return SqlInt32.Null;
    }
}
