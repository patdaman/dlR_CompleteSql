using System;
using System.Data.SqlTypes;
using System.Text.RegularExpressions;

public partial class UserDefinedFunctions
{
    /// <summary>
    /// Searches the input string for an occurrence of the regular expression supplied
    /// in a pattern parameter with matching options supplied in an options parameter.
    /// </summary>
    /// <param name="input">The string to be tested for a match.</param>
    /// <param name="pattern">The regular expression pattern to match.</param>
    /// <param name="start">Integer Value of starting position + 1.</param>\
    /// <param name="n"></param>
    /// <returns>varchar - characters that match the pattern</returns>
    /// <exception cref="System.ArgumentException">Regular expression parsing error.</exception>
    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlChars RegexMatch(SqlChars input, SqlChars pattern, SqlInt32 start, SqlInt32 n)
    {
        if (input.IsNull || pattern.IsNull || input.Value.Length < 1) return SqlChars.Null;
        int s, i;
        if (start.IsNull) s = 0;
        else s = start.Value - 1;
        if (s >= input.Value.Length)
            throw new ArgumentException(string.Format("RegexMatch: Start expected to be between 1 and {0:G} (got {1:G}", input.Value.Length, s + 1));
        if (n.IsNull) i = 0;
        else i = n.Value - 1;
        string _input = new string(input.Value).Substring(s);
        string _pattern = new string(pattern.Value);
        MatchCollection mc = Regex.Matches(_input, _pattern);
        if (mc.Count <= i) return SqlChars.Null;
        string _result = mc[i].Value;
        return new SqlChars(_result);
    }

    /// <summary>
    /// Searches the input string for an occurrence of the regular expression supplied
    /// in a pattern parameter with matching options supplied in an options parameter.
    /// </summary>
    /// <param name="input">The string to be tested for a match.</param>
    /// <param name="pattern">The regular expression pattern to match.</param>
    /// <param name="start">Int - starting position.</param>
    /// <param name="n"></param>
    /// <returns>Int - position of start of Regex match</returns>
    /// <exception cref="System.ArgumentException">Regular expression parsing error.</exception>
    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlInt32 RegexIndex(SqlChars input, SqlChars pattern, SqlInt32 start, SqlInt32 n)
    {
        if (input.IsNull || pattern.IsNull || input.Value.Length < 1) return SqlInt32.Null;
        int s, i;
        if (start.IsNull) s = 0;
        else s = start.Value - 1;
        if (s >= input.Value.Length)
            throw new ArgumentException(string.Format("RegexIndex: Start expected to be between 1 and {0:G} (got {1:G}", input.Value.Length, s + 1));
        if (n.IsNull) i = 0;
        else i = n.Value - 1;
        string _input = new string(input.Value).Substring(s);
        string _pattern = new string(pattern.Value);
        MatchCollection mc = Regex.Matches(_input, _pattern);
        if (mc.Count <= i) return SqlInt32.Null;
        int _result = mc[i].Index;
        return _result + s + 1;
    }

    /// <summary>
    /// Searches the input string for an occurrence of the regular expression supplied
    /// in a pattern parameter with matching options supplied in an options parameter.
    /// </summary>
    /// <param name="input">The string to be tested for a match.</param>
    /// <param name="pattern">The regular expression pattern to match.</param>
    /// <param name="start">A bitwise OR combination of RegexOption enumeration values.</param>
    /// <returns>true - if inputted string matches to pattern, else - false</returns>
    /// <exception cref="System.ArgumentException">Regular expression parsing error.</exception>
    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlBoolean RegexIsMatch(SqlChars input, SqlChars pattern, SqlInt32 start)
    {
        if (input.IsNull || pattern.IsNull || input.Value.Length < 1) return SqlBoolean.Null;
        int s;
        if (start.IsNull) s = 0;
        else s = start.Value - 1;
        if (s >= input.Value.Length)
            throw new ArgumentException(string.Format("RegexIsMatch: Start expected to be between 1 and {0:G} (got {1:G}", input.Value.Length, s + 1));
        string _input = new string(input.Value).Substring(s);
        string _pattern = new string(pattern.Value);
        return new SqlBoolean(Regex.IsMatch(_input, _pattern));
    }

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   RegEx replace. </summary>
    ///
    /// <remarks>   Pdelosreyes, 20160301. </remarks>
    ///
    /// <param name="text">         The text. </param>
    /// <param name="expression">   The Regex expression. </param>
    /// <param name="replace">      The replacement value </param>
    ///
    /// <returns>   A SqlString. </returns>
    ///-------------------------------------------------------------------------------------------------

    [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true)]
    public static SqlString RegexReplace(string text, string expression, string replace)
    {

        var updatedString = string.Empty;

        if (!string.IsNullOrEmpty(text))
        {
            updatedString = Regex.Replace(text, expression, replace);
        }

        return new SqlString(updatedString);

    }

    /// <summary>
    /// Searches the input string a for an occurrence of string b
    /// with a parameter for case sensitivity.
    /// </summary>
    /// <param name="a">Input A</param>
    /// <param name="b">Input B</param>
    /// <param name="casesensitive">Bit - Test for case sensitive or not</param>
    /// <returns>true - if input string contains other string, else - false</returns>
    /// <exception cref="System.ArgumentException">Regular expression parsing error.</exception>
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SqlBoolean StringContains(SqlChars a, SqlChars b, SqlBoolean casesensitive)
    {
        if (a.IsNull || b.IsNull) return SqlBoolean.Null;
        string sa = new string(a.Value);
        string sb = new string(b.Value);
        StringComparison sc = casesensitive.IsNull || casesensitive.Value ? StringComparison.InvariantCulture : StringComparison.InvariantCultureIgnoreCase;
        return new SqlBoolean(sa.IndexOf(sb, sc) >= 0);
    }
}
