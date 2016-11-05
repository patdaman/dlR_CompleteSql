using System;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.IO;
using System.Collections.Generic;
using System.Text;

namespace Group_Concat
{
    ///-------------------------------------------------------------------------------------------------
    /// <summary>   A group concatenate. </summary>
    ///
    /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
    ///-------------------------------------------------------------------------------------------------

    [Serializable]
    [SqlUserDefinedAggregate(Format.UserDefined,
                             MaxByteSize = -1,
                             IsInvariantToNulls = true,
                             IsInvariantToDuplicates = false,
                             IsInvariantToOrder = true,
                             IsNullIfEmpty = true)]
    public struct GROUP_CONCAT : IBinarySerialize
    {
        private Dictionary<string, int> values;

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Initialises this object. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///-------------------------------------------------------------------------------------------------

        public void Init()
        {
            this.values = new Dictionary<string, int>();
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Accumulates the given value. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="VALUE">    The value. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Accumulate([SqlFacet(MaxSize = 4000)] SqlString VALUE)
        {
            if (!VALUE.IsNull)
            {
                string key = VALUE.Value;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += 1;
                }
                else
                {
                    this.values.Add(key, 1);
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Merges the given group. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="Group">    The group. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Merge(GROUP_CONCAT Group)
        {
            foreach (KeyValuePair<string, int> item in Group.values)
            {
                string key = item.Key;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += Group.values[key];
                }
                else
                {
                    this.values.Add(key, Group.values[key]);
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Gets the terminate. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <returns>   A SqlString. </returns>
        ///-------------------------------------------------------------------------------------------------

        [return: SqlFacet(MaxSize = -1)]
        public SqlString Terminate()
        {
            if (this.values != null && this.values.Count > 0)
            {
                StringBuilder returnStringBuilder = new StringBuilder();

                foreach (KeyValuePair<string, int> item in this.values)
                {
                    for (int value = 0; value < item.Value; value++)
                    {
                        returnStringBuilder.Append(item.Key);
                        returnStringBuilder.Append(",");
                    }
                }
                return returnStringBuilder.Remove(returnStringBuilder.Length - 1, 1).ToString();
            }

            return null;
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Reads the given r. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="r">    The r to read. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Read(BinaryReader r)
        {
            int itemCount = r.ReadInt32();
            this.values = new Dictionary<string, int>(itemCount);
            for (int i = 0; i <= itemCount - 1; i++)
            {
                this.values.Add(r.ReadString(), r.ReadInt32());
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Writes the given w. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="w">    The w to write. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Write(BinaryWriter w)
        {
            w.Write(this.values.Count);
            foreach (KeyValuePair<string, int> s in this.values)
            {
                w.Write(s.Key);
                w.Write(s.Value);
            }
        }
    }

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   A group concatenate s. </summary>
    ///
    /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
    ///-------------------------------------------------------------------------------------------------

    [Serializable]
    [SqlUserDefinedAggregate(Format.UserDefined,
                          MaxByteSize = -1,
                          IsInvariantToNulls = true,
                          IsInvariantToDuplicates = false,
                          IsInvariantToOrder = true,
                          IsNullIfEmpty = true)]
    public struct GROUP_CONCAT_S : IBinarySerialize
    {
        private Dictionary<string, int> values;
        private byte sortBy;

        private SqlByte SortBy
        {
            set
            {
                if (this.sortBy == 0)
                {
                    if (
                        value.Value != 1 // ASC
                        &&
                        value.Value != 2 // DESC
                        )
                    {
                        throw new Exception("Invalid SortBy value: use 1 for ASC or 2 for DESC.");
                    }
                    this.sortBy = Convert.ToByte(value.Value);
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Initialises this object. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///-------------------------------------------------------------------------------------------------

        public void Init()
        {
            this.values = new Dictionary<string, int>();
            this.sortBy = 0;
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Accumulates. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="VALUE">        The value. </param>
        /// <param name="SORT_ORDER">   The sort order. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Accumulate([SqlFacet(MaxSize = 4000)] SqlString VALUE,
                               SqlByte SORT_ORDER)
        {
            if (!VALUE.IsNull)
            {
                string key = VALUE.Value;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += 1;
                }
                else
                {
                    this.values.Add(key, 1);
                }
                this.SortBy = SORT_ORDER;
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Merges the given group. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="Group">    The group. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Merge(GROUP_CONCAT_S Group)
        {
            if (this.sortBy == 0)
            {
                this.sortBy = Group.sortBy;
            }

            foreach (KeyValuePair<string, int> item in Group.values)
            {
                string key = item.Key;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += Group.values[key];
                }
                else
                {
                    this.values.Add(key, Group.values[key]);
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Gets the terminate. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <returns>   A SqlString. </returns>
        ///-------------------------------------------------------------------------------------------------

        [return: SqlFacet(MaxSize = -1)]
        public SqlString Terminate()
        {
            if (this.values != null && this.values.Count > 0)
            {
                SortedDictionary<string, int> sortedValues;
                StringBuilder returnStringBuilder = new StringBuilder();

                if (this.sortBy == 2)
                {
                    // create SortedDictionary in descending order using the ReverseComparer
                    sortedValues = new SortedDictionary<string, int>(values, new ReverseComparer());
                }
                else
                {
                    // create SortedDictionary in ascending order using the default comparer
                    sortedValues = new SortedDictionary<string, int>(values);
                }

                // iterate over the SortedDictionary
                foreach (KeyValuePair<string, int> item in sortedValues)
                {
                    string key = item.Key;
                    for (int value = 0; value < item.Value; value++)
                    {
                        returnStringBuilder.Append(key);
                        returnStringBuilder.Append(",");
                    }
                }
                return returnStringBuilder.Remove(returnStringBuilder.Length - 1, 1).ToString();
            }

            return null;
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Reads the given r. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="r">    The r to read. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Read(BinaryReader r)
        {
            int itemCount = r.ReadInt32();
            this.values = new Dictionary<string, int>(itemCount);
            for (int i = 0; i <= itemCount - 1; i++)
            {
                this.values.Add(r.ReadString(), r.ReadInt32());
            }
            this.sortBy = r.ReadByte();
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Writes the given w. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="w">    The w to write. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Write(BinaryWriter w)
        {
            w.Write(this.values.Count);
            foreach (KeyValuePair<string, int> s in this.values)
            {
                w.Write(s.Key);
                w.Write(s.Value);
            }
            w.Write(this.sortBy);
        }
    }

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   A reverse comparer. </summary>
    ///
    /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
    ///-------------------------------------------------------------------------------------------------

    public class ReverseComparer : IComparer<string>
    {
        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Compares two string objects to determine their relative ordering. </summary>
        ///
        /// <remarks>   Pdelosreyes, 10/14/2015. </remarks>
        ///
        /// <param name="x">    String to be compared. </param>
        /// <param name="y">    String to be compared. </param>
        ///
        /// <returns>   Negative if 'x' is less than 'y', 0 if they are equal, or positive if it is
        ///             greater. </returns>
        ///-------------------------------------------------------------------------------------------------

        public int Compare(string x, string y)
        {
            // Compare y and x in reverse order.
            return y.CompareTo(x);
        }
    }
    [Serializable]
    [SqlUserDefinedAggregate(Format.UserDefined,
                              MaxByteSize = -1,
                              IsInvariantToNulls = true,
                              IsInvariantToDuplicates = false,
                              IsInvariantToOrder = true,
                              IsNullIfEmpty = true)]

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   A group concatenate ds. </summary>
    ///
    /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
    ///-------------------------------------------------------------------------------------------------

    public struct GROUP_CONCAT_DS : IBinarySerialize
    {
        private Dictionary<string, int> values;
        private string delimiter;
        private byte sortBy;

        private SqlString Delimiter
        {
            set
            {
                string newDelimiter = value.ToString();
                if (this.delimiter != newDelimiter)
                {
                    this.delimiter = newDelimiter;
                }
            }
        }

        private SqlByte SortBy
        {
            set
            {
                if (this.sortBy == 0)
                {
                    if (
                        value.Value != 1 // ASC
                        &&
                        value.Value != 2 // DESC
                        )
                    {
                        throw new Exception("Invalid SortBy value: use 1 for ASC or 2 for DESC.");
                    }
                    this.sortBy = Convert.ToByte(value.Value);
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Initialises this object. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///-------------------------------------------------------------------------------------------------

        public void Init()
        {
            this.values = new Dictionary<string, int>();
            this.delimiter = string.Empty;
            this.sortBy = 0;
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Accumulates. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="VALUE">        The value. </param>
        /// <param name="DELIMITER">    The delimiter. </param>
        /// <param name="SORT_ORDER">   The sort order. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Accumulate([SqlFacet(MaxSize = 4000)] SqlString VALUE,
                               [SqlFacet(MaxSize = 4)] SqlString DELIMITER,
                               SqlByte SORT_ORDER)
        {
            if (!VALUE.IsNull)
            {
                string key = VALUE.Value;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += 1;
                }
                else
                {
                    this.values.Add(key, 1);
                }
                this.Delimiter = DELIMITER;
                this.SortBy = SORT_ORDER;
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Merges the given group. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="Group">    The group. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Merge(GROUP_CONCAT_DS Group)
        {
            if (string.IsNullOrEmpty(this.delimiter))
            {
                this.delimiter = Group.delimiter;
            }
            if (this.sortBy == 0)
            {
                this.sortBy = Group.sortBy;
            }

            foreach (KeyValuePair<string, int> item in Group.values)
            {
                string key = item.Key;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += Group.values[key];
                }
                else
                {
                    this.values.Add(key, Group.values[key]);
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Gets the terminate. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <returns>   A SqlString. </returns>
        ///-------------------------------------------------------------------------------------------------

        [return: SqlFacet(MaxSize = -1)]
        public SqlString Terminate()
        {
            if (this.values != null && this.values.Count > 0)
            {
                SortedDictionary<string, int> sortedValues;
                StringBuilder returnStringBuilder = new StringBuilder();

                if (this.sortBy == 2)
                {
                    // create SortedDictionary in descending order using the ReverseComparer
                    sortedValues = new SortedDictionary<string, int>(values, new ReverseComparer());
                }
                else
                {
                    // create SortedDictionary in ascending order using the default comparer
                    sortedValues = new SortedDictionary<string, int>(values);
                }

                // iterate over the SortedDictionary
                foreach (KeyValuePair<string, int> item in sortedValues)
                {
                    for (int value = 0; value < item.Value; value++)
                    {
                        returnStringBuilder.Append(item.Key);
                        returnStringBuilder.Append(this.delimiter);
                    }
                }

                // remove trailing delimiter as we return the result
                return returnStringBuilder.Remove(returnStringBuilder.Length - this.delimiter.Length, this.delimiter.Length).ToString();
            }

            return null;
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Reads the given r. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="r">    The r to read. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Read(BinaryReader r)
        {
            int itemCount = r.ReadInt32();
            this.values = new Dictionary<string, int>(itemCount);
            for (int i = 0; i <= itemCount - 1; i++)
            {
                this.values.Add(r.ReadString(), r.ReadInt32());
            }
            this.delimiter = r.ReadString();
            this.sortBy = r.ReadByte();
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Writes the given w. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="w">    The w to write. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Write(BinaryWriter w)
        {
            w.Write(this.values.Count);
            foreach (KeyValuePair<string, int> s in this.values)
            {
                w.Write(s.Key);
                w.Write(s.Value);
            }
            w.Write(this.delimiter);
            w.Write(this.sortBy);
        }
    }

    [Serializable]
    [SqlUserDefinedAggregate(Format.UserDefined,
                         MaxByteSize = -1,
                         IsInvariantToNulls = true,
                         IsInvariantToDuplicates = false,
                         IsInvariantToOrder = true,
                         IsNullIfEmpty = true)]

    ///-------------------------------------------------------------------------------------------------
    /// <summary>   A group concatenate d. </summary>
    ///
    /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
    ///-------------------------------------------------------------------------------------------------

    public struct GROUP_CONCAT_D : IBinarySerialize
    {
        private Dictionary<string, int> values;
        private string delimiter;

        private SqlString Delimiter
        {
            set
            {
                string newDelimiter = value.ToString();
                if (this.delimiter != newDelimiter)
                {
                    this.delimiter = newDelimiter;
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Initialises this object. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///-------------------------------------------------------------------------------------------------

        public void Init()
        {
            this.values = new Dictionary<string, int>();
            this.delimiter = string.Empty;
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Accumulates. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="VALUE">        The value. </param>
        /// <param name="DELIMITER">    The delimiter. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Accumulate([SqlFacet(MaxSize = 4000)] SqlString VALUE,
                               [SqlFacet(MaxSize = 4)] SqlString DELIMITER)
        {
            if (!VALUE.IsNull)
            {
                string key = VALUE.Value;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += 1;
                }
                else
                {
                    this.values.Add(key, 1);
                }
                this.Delimiter = DELIMITER;
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Merges the given group. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="Group">    The group. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Merge(GROUP_CONCAT_D Group)
        {
            if (string.IsNullOrEmpty(this.delimiter))
            {
                this.delimiter = Group.delimiter;
            }

            foreach (KeyValuePair<string, int> item in Group.values)
            {
                string key = item.Key;
                if (this.values.ContainsKey(key))
                {
                    this.values[key] += Group.values[key];
                }
                else
                {
                    this.values.Add(key, Group.values[key]);
                }
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Gets the terminate. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <returns>   A SqlString. </returns>
        ///-------------------------------------------------------------------------------------------------

        [return: SqlFacet(MaxSize = -1)]
        public SqlString Terminate()
        {
            if (this.values != null && this.values.Count > 0)
            {
                StringBuilder returnStringBuilder = new StringBuilder();

                foreach (KeyValuePair<string, int> item in this.values)
                {
                    for (int value = 0; value < item.Value; value++)
                    {
                        returnStringBuilder.Append(item.Key);
                        returnStringBuilder.Append(this.delimiter);
                    }
                }

                // remove trailing delimiter as we return the result
                return returnStringBuilder.Remove(returnStringBuilder.Length - this.delimiter.Length, this.delimiter.Length).ToString();
            }

            return null;
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Reads the given r. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="r">    The r to read. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Read(BinaryReader r)
        {
            int itemCount = r.ReadInt32();
            this.values = new Dictionary<string, int>(itemCount);
            for (int i = 0; i <= itemCount - 1; i++)
            {
                this.values.Add(r.ReadString(), r.ReadInt32());
            }
            this.delimiter = r.ReadString();
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Writes the given w. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="w">    The w to write. </param>
        ///-------------------------------------------------------------------------------------------------

        public void Write(BinaryWriter w)
        {
            w.Write(this.values.Count);
            foreach (KeyValuePair<string, int> s in this.values)
            {
                w.Write(s.Key);
                w.Write(s.Value);
            }
            w.Write(this.delimiter);
        }
    }
}

