using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using ExcelExport;
using System.Xml;

namespace ExcelExport
{
    ///-------------------------------------------------------------------------------------------------
    /// <summary>   ExportToExcel. </summary>
    ///
    /// <remarks>   Pdelosreyes, 12/22/2015. </remarks>
    ///-------------------------------------------------------------------------------------------------

    public partial class StoredProcedures
    {
        [Microsoft.SqlServer.Server.SqlProcedure]
        /// <summary>
        /// Export a stored procedure into Excel 
        ///
        /// @SqlXml = XML representation of stored procedure parameters
        ///     eg. 
        /// </summary>
        /// <param name="procName">        Stored Procedure name to execute (+ schema : 'dbo') </param>
        /// <param name="filePath">   Path to excel output file </param>
        /// <param name="fileName">        name of excel file </param>
        /// <param name="SqlXml">   XML representation of stored procedure parameters </param>
        /// <returns> Excel file written to disk. </returns>
        public static void ExportToExcel(SqlString procName, SqlString filePath, SqlString fileName, SqlXml xmlParams)
        {
            DataSet exportData = new DataSet();

            //check for empty parameters

            if (procName.Value == string.Empty)
                throw new Exception("Procedure name value is missing.");

            if (filePath.Value == string.Empty)
                throw new Exception("Missing file path location.");

            if (fileName.Value == string.Empty)
                throw new Exception("Missing name of file.");

            using (SqlConnection conn = new SqlConnection("context connection=true"))
            {
                SqlCommand getOutput = new SqlCommand();

                getOutput.CommandText = procName.ToString(); ;
                getOutput.CommandType = CommandType.StoredProcedure;
                getOutput.CommandTimeout = 120;

                //To allow for multiple parameters, xml is used
                //and must then be parsed to set up the paramaters
                //for the command object.
                using (XmlReader parms = xmlParams.CreateReader())
                {
                    while (parms.Read())
                    {
                        if (parms.Name == "param")
                        {
                            string paramName;
                            paramName = parms.GetAttribute("name");

                            string paramValue;
                            paramValue = parms.GetAttribute("value");

                            getOutput.Parameters.AddWithValue(paramName, paramValue);
                        }
                    }
                }

                getOutput.Connection = conn;

                conn.Open();
                SqlDataAdapter da = new SqlDataAdapter(getOutput);
                da.Fill(exportData);
                conn.Close();
            }

            ExcelExportUtility exportUtil = new ExcelExportUtility(fileName.ToString(), filePath.ToString());
            //This allows for flexible naming of the tabs in the workbook
            exportUtil.SheetNameColumnOrdinal = 0;
            exportUtil.Export(exportData);
        }
    }
}
