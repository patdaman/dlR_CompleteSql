using System.Reflection;
using System;
using System.Data;
using System.Xml;

// General Information about an assembly is controlled through the following 
// set of attributes. Change these attribute values to modify the information
// associated with the SQLCLR assembly.
[assembly: AssemblyTitle("SGNL_WAREHOUSE")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("Signal Genetics")]
[assembly: AssemblyProduct("SGNL_WAREHOUSE")]
[assembly: AssemblyCopyright("Copyright ©  2015")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version 
//      Build Number
//      Revision
//
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace ExcelExport
{
    /// <summary>
    /// Summary description for ExcelExportUtility.
    /// </summary>
    public class ExcelExportUtility
    {
        private int sheetNameColumnOrdinal = -1;
        private string defaultFilename = "ExcelExportRequest";
        private string mFilePath = "";

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Constructor. </summary>
        ///
        /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
        ///
        /// <param name="fileName"> Filename of the file. </param>
        /// <param name="filePath"> Full pathname of the file. </param>
        ///-------------------------------------------------------------------------------------------------

        public ExcelExportUtility(string fileName, string filePath)
        {
            mFilePath = filePath;
            defaultFilename = fileName;
        }

        /// <summary>
        /// Main method for exporting to Excel.
        /// </summary>
        /// <param name="data"></param>
        public void Export(DataSet data)
        {
            string outputFile;
            outputFile = mFilePath + defaultFilename + ".xls";

            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;

            using (XmlWriter xw = XmlWriter.Create(outputFile, settings))
            {
                //Required namespaces used for SpreadsheetML standard.
                xw.WriteStartDocument();
                xw.WriteProcessingInstruction("mso-application", "Excel.Sheet");
                xw.WriteStartElement("Workbook", "urn:schemas-microsoft-com:office:Spreadsheet");
                xw.WriteAttributeString("xmlns", "o", null, "urn:schemas-microsoft-com:office:office");
                xw.WriteAttributeString("xmlns", "x", null, "urn:schemas-microsoft-com:office:excel");
                xw.WriteAttributeString("xmlns", "ss", null, "urn:schemas-microsoft-com:office:Spreadsheet");
                xw.WriteAttributeString("xmlns", "html", null, "http://www.w3.org/TR/REC-html40");

                WriteHeaderInfo(xw);

                //Iterate the tables in the dataset.
                //Each table will become a tab or sheet in the workbook.
                foreach (DataTable dt in data.Tables)
                {
                    //Default the tab name to either the table name 
                    //or pull tab name from first column of each resultset.
                    string sheetName;
                    if (dt.Rows.Count > 0)
                        sheetName = dt.Rows[0][sheetNameColumnOrdinal].ToString();
                    else
                        sheetName = dt.TableName;

                    //Start of a tab
                    xw.WriteStartElement("Worksheet");
                    xw.WriteAttributeString("ss", "Name", null, sheetName);

                    xw.WriteStartElement("Table");
                    xw.WriteAttributeString("ss", "DefaultColumnWidth", null, "100");

                    //Write out header data
                    xw.WriteStartElement("Row");
                    //Format column headings
                    foreach (DataColumn dc in dt.Columns)
                    {
                        if (dc.Ordinal != sheetNameColumnOrdinal)
                        {
                            xw.WriteStartElement("Cell");
                            xw.WriteAttributeString("ss", "StyleID", null, "Header");
                            xw.WriteStartElement("Data");
                            xw.WriteAttributeString("ss", "Type", null, "String");
                            xw.WriteString(dc.ColumnName);
                            xw.WriteEndElement(); //End Data
                            xw.WriteEndElement(); //End Cell
                        }
                    }
                    xw.WriteEndElement(); //End Row

                    //Write out row data
                    foreach (DataRow dr in dt.Rows)
                    {
                        xw.WriteStartElement("Row");
                        foreach (DataColumn dc in dt.Columns)
                        {
                            if (dc.Ordinal != sheetNameColumnOrdinal)
                            {
                                string dataType;
                                string style;
                                string output;

                                //Set appropriate styling of each cell based on datatype
                                //This depends on how sql server ends up reporting the datatype.
                                switch (dc.DataType.ToString())
                                {
                                    case "System.DateTime":
                                        dataType = "DateTime";
                                        style = "Date";

                                        try
                                        {
                                            output = DateTime.Parse(dr[dc].ToString()).ToString("yyyy-MM-dd");
                                        }
                                        catch (FormatException fe) //date is null or empty in dataset
                                        {
                                            output = "";
                                        }

                                        break;
                                    case "System.Decimal":
                                    case "System.Double":
                                    case "System.Int16":
                                    case "System.Int32":
                                    case "System.Int64":
                                    case "System.Byte":
                                        dataType = "Number";
                                        style = "Data";
                                        output = dr[dc].ToString().Trim();
                                        break;
                                    default:
                                        dataType = "String";
                                        style = "Data";
                                        output = dr[dc].ToString().Trim();
                                        break;
                                }

                                //if no data then write empty cell node
                                xw.WriteStartElement("Cell");
                                xw.WriteStartAttribute("StyleID", "");
                                xw.WriteString(style);
                                xw.WriteEndAttribute(); //End Style Attribute
                                if (output != "")
                                {
                                    xw.WriteStartElement("Data");
                                    xw.WriteAttributeString("ss", "Type", null, dataType);
                                    xw.WriteString(output);
                                    xw.WriteEndElement(); //End Data

                                }
                                xw.WriteEndElement(); //End Cell
                            }
                        }
                        xw.WriteEndElement(); //End Row
                    }

                    xw.Flush();
                    xw.WriteEndElement(); //End Table
                    xw.WriteEndElement(); //End Worksheet
                }

                xw.WriteEndElement(); //End Workbook
                xw.Flush();
            }

        }

        /// <summary>
        /// Used to set up column headers and data type styling.
        /// </summary>
        /// <param name="xw"></param>
        public void WriteHeaderInfo(XmlWriter xw)
        {
            xw.WriteStartElement("Styles");

            //Default styling
            xw.WriteStartElement("Style");
            xw.WriteAttributeString("ss", "ID", null, "Default");
            xw.WriteAttributeString("ss", "Name", null, "Normal");
            xw.WriteStartElement("Alignment");
            xw.WriteAttributeString("ss", "Vertical", null, "Bottom");
            xw.WriteEndElement(); //End Alignment
            xw.WriteElementString("Borders", "");
            xw.WriteElementString("Font", "");
            xw.WriteElementString("Interior", "");
            xw.WriteElementString("NumberFormat", "");
            xw.WriteElementString("Protection", "");
            xw.WriteEndElement(); //End Style

            //Header styling
            xw.WriteStartElement("Style");
            xw.WriteAttributeString("ss", "ID", null, "Header");
            xw.WriteStartElement("Borders");
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Bottom");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "2");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Left");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "2");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Right");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "2");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Top");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "2");
            xw.WriteEndElement(); //End Border
            xw.WriteEndElement(); //End Borders
            xw.WriteStartElement("Font");
            xw.WriteAttributeString("ss", "Bold", null, "1");
            xw.WriteEndElement(); //End Font
            xw.WriteStartElement("Interior");
            xw.WriteAttributeString("ss", "Color", null, "#C0C0C0");
            xw.WriteAttributeString("ss", "Pattern", null, "Solid");
            xw.WriteEndElement(); //End Interior
            xw.WriteEndElement(); //End Style

            //Data styling
            xw.WriteStartElement("Style");
            xw.WriteAttributeString("ss", "ID", null, "Data");
            xw.WriteStartElement("Alignment");
            xw.WriteAttributeString("ss", "Vertical", null, "Bottom");
            xw.WriteAttributeString("ss", "WrapText", null, "0");
            xw.WriteEndElement(); //End Alignment
            xw.WriteStartElement("Borders");
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Bottom");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Left");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Right");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Top");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteEndElement(); //End Borders
            xw.WriteEndElement(); //End Style

            //Date styling
            xw.WriteStartElement("Style");
            xw.WriteAttributeString("ss", "ID", null, "Date");
            xw.WriteStartElement("Alignment");
            xw.WriteAttributeString("ss", "Vertical", null, "Bottom");
            xw.WriteAttributeString("ss", "WrapText", null, "1");
            xw.WriteEndElement(); //End Alignment
            xw.WriteStartElement("NumberFormat");
            xw.WriteAttributeString("ss", "Format", null, "Short Date");
            xw.WriteEndElement(); //End NumberFormat
            xw.WriteStartElement("Borders");
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Bottom");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Left");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Right");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteStartElement("Border");
            xw.WriteAttributeString("ss", "Position", null, "Top");
            xw.WriteAttributeString("ss", "LineStyle", null, "Continuous");
            xw.WriteAttributeString("ss", "Weight", null, "1");
            xw.WriteAttributeString("ss", "Color", null, "#000000");
            xw.WriteEndElement(); //End Border
            xw.WriteEndElement(); //End Borders
            xw.WriteEndElement(); //End Style

            xw.WriteEndElement(); //End Styles
            xw.Flush();
        }

        /// <summary>
        /// Provides the column. ordinal number to use for the sheet name.
        /// If not set then the default table names are used.
        /// </summary>
        public int SheetNameColumnOrdinal
        {
            get
            {
                return sheetNameColumnOrdinal;
            }
            set
            {
                sheetNameColumnOrdinal = value;
            }
        }
        /// <summary>
        /// Set default filename.  Do not specify extension.
        /// </summary>
        public string DefaultFilename
        {
            get
            {
                return defaultFilename;
            }
            set
            {
                defaultFilename = value;
            }
        }

        ///-------------------------------------------------------------------------------------------------
        /// <summary>   Gets or sets the full pathname of the file. </summary>
        ///
        /// <value> The full pathname of the file. </value>
        ///-------------------------------------------------------------------------------------------------

        public string FilePath
        {
            get
            {
                return mFilePath;
            }
            set
            {
                mFilePath = value;
            }
        }
    }
}
