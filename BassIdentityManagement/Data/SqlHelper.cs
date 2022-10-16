using Dapper;
using BassIdentityManagement.Entities;
using BassIdentityManagement.Utilities;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

namespace BassIdentityManagement.Data
{
   /* SQL Server return error code
                        case -2:   // Client Timeout
                        case 701:  // Out of Memory
                        case 1204: // Lock Issue 
                        case 1205: // >>> Deadlock Victim
                        case 1222: // Lock Request Timeout
                        case 2627: // Primary Key Violation
                        case 8645: // Timeout waiting for memory resource 
                        case 8651: // Low memory condition
   */
public static class SqlHelper
    {
        public static T GetRecord<T>(string spName, List<ParameterInfo> parameters)
        {
            T objRecord = default(T);

            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    DynamicParameters p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                         p.Add("@" + param.ParameterName, param.ParameterValue);
                    }                
                    objRecord = SqlMapper.Query<T>(objConnection, spName, p, commandType: CommandType.StoredProcedure).FirstOrDefault();
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
                return objRecord;
            }
        }
        
        public static List<T> GetRecords<T>(string spName, List<ParameterInfo> parameters)
        {
            List<T> recordList = new List<T>();
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
               try
                {
                    objConnection.Open();
                    DynamicParameters p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }               
                    recordList = SqlMapper.Query<T>(objConnection, spName, p, commandTimeout: 90, commandType: CommandType.StoredProcedure).AsList();
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<T> GetIRPRecords<T>(string spName, List<ParameterInfo> parameters)
        {
            List<T> recordList = new List<T>();
            using (SqlConnection objConnection = new SqlConnection(Utils.PATSConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    DynamicParameters p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }
                    recordList = SqlMapper.Query<T>(objConnection, spName, p, commandTimeout: 90, commandType: CommandType.StoredProcedure).AsList();
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static string ExecuteOutputParam(string spName, DynamicParameters parameters)
        {
            //T recordList = new T();
            string record = string.Empty;
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                try
                {
                    objConnection.Open();                              
                    record = SqlMapper.Query(objConnection, spName, parameters, commandTimeout: 90, commandType: CommandType.StoredProcedure).SingleOrDefault();
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return record;
        }
        public static List<dynamic> GetMultiSets<dynamic>(string spName, List<ParameterInfo> parameters, int Len)
        {
            List<dynamic> recordList = new List<dynamic>();
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                objConnection.Open();
                DynamicParameters p = null;
                if (parameters != null)
                {
                    p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }
                }
                try
                {
                    using (var multipleResults = SqlMapper.QueryMultiple(objConnection, spName, p, commandType: CommandType.StoredProcedure))
                    {
                        while (!multipleResults.IsConsumed)
                        {
                            recordList.Add((dynamic)multipleResults.Read());
                        }
                        //return rs;
                        //for(int i = 0; i< Len; i++)
                        //{
                        //    recordList.Add(multipleResults.Read());
                        //}
                    }
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<object> GetMultiRecordsets<T>(string spName, List<ParameterInfo> parameters, List<string> ObjectSets, int dbc)
        {
            List<object> recordList = new List<object>();
            var ut = new Utils(dbc);
            using (SqlConnection objConnection = new SqlConnection(ut.ConnectString))
            {
                objConnection.Open();
                DynamicParameters p = null;
                if (parameters != null)
                {
                    p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }
                }
                try
                {
                    using (var multipleResults = SqlMapper.QueryMultiple(objConnection, spName, p, commandType: CommandType.StoredProcedure))
                    {
                        for (int i = 0; i < ObjectSets.Count; i++)
                        {
                            switch (ObjectSets[i])
                            {
                                case "ActiveUsers":
                                    {
                                        var set = multipleResults.Read<ActiveUserList>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                
                                case "Facilities":
                                    {
                                        var set = multipleResults.Read<Facility>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "CaseNoteTypes":
                                    {
                                        var set = multipleResults.Read<CaseNoteType>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "Episode":
                                    {
                                        var set = multipleResults.Read<LoadedEpisode>();
                                        recordList.Add(set.FirstOrDefault());
                                        break;
                                    }
                                case "BHRIRP":
                                    {
                                        var set = multipleResults.Read<BHRIRPData>();
                                        recordList.Add(set.FirstOrDefault());
                                        break;
                                    }
                                case "IdentifiedBarriersToIntervention":
                                    {
                                        var set = multipleResults.Read<IdentifiedBarriersToIntervention>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "BarrierFrequency":
                                    {
                                        var set = multipleResults.Read<BarrierFrequency>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "BHRIRPAdditionInfo":
                                    {
                                        var set = multipleResults.Read<BHRIRPAdditionInfo>();
                                        recordList.Add(set.FirstOrDefault());
                                        break;
                                    }
                            }
                        }
                    }
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally { 
                   objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<dynamic> GetMultiPATSSets<dynamic>(string spName, List<ParameterInfo> parameters, int Len)
        {
            List<dynamic> recordList = new List<dynamic>();
            using (SqlConnection objConnection = new SqlConnection(Utils.PATSConnectionString()))
            {
                objConnection.Open();
                DynamicParameters p = null;
                if (parameters != null)
                {
                    p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }
                }
                try
                {
                    using (var multipleResults = SqlMapper.QueryMultiple(objConnection, spName, p, commandType: CommandType.StoredProcedure))
                    {
                        for (int i = 0; i < Len; i++)
                        {
                            if (i == 0)
                            {
                                recordList.Add((dynamic)multipleResults.Read<BHRIRPData>());
                            }
                            else
                            {                 
                                recordList.Add((dynamic)multipleResults.Read());
                            }
                        }
                    }
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<object> GetInmateDetails<T>(string spName, List<ParameterInfo> parameters, List<string> ObjectSets)
        {
            List<object> recordList = new List<object>();
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                objConnection.Open();
                DynamicParameters p = null;
                if (parameters != null)
                {
                    p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }
                }
                try
                {
                    using (var multipleResults = SqlMapper.QueryMultiple(objConnection, spName, p, commandType: CommandType.StoredProcedure))
                    {
                        for (int i = 0; i < ObjectSets.Count; i++)
                        {
                            switch (ObjectSets[i])
                            {
                                case "DerivedSomsData":
                                    {
                                        var set = multipleResults.Read<DerivedSomsData>();
                                        recordList.Add(set.FirstOrDefault());
                                        break;
                                    }

                                case "InmateProfileData":
                                    {
                                        var set = multipleResults.Read<InmateProfileData>();
                                        recordList.Add(set.FirstOrDefault());
                                        break;
                                    }
                                case "Episodes":
                                    {
                                        var set = multipleResults.Read<Episodes>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "Counties":
                                    {
                                        var set = multipleResults.Read<County>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "Facilities":
                                    {
                                        var set = multipleResults.Read<Facility>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "Outcomes":
                                    {
                                        var set = multipleResults.Read<OutcomeType>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "Genders":
                                    {
                                        var set = multipleResults.Read<Gender>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "EpisodeAcpDshTypes":
                                    {
                                        var set = multipleResults.Read<EpisodeAcpDshType>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "EpisodeMdoSvpTypes":
                                    {
                                        var set = multipleResults.Read<EpisodeMdoSvpType>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "EpisodeMedReleaseTypes":
                                    {
                                        var set = multipleResults.Read<EpisodeMedReleaseType>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "Destinations":
                                    {
                                        var set = multipleResults.Read<LookUpTable>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "ApplicationFlags":
                                    {
                                        var set = multipleResults.Read<ApplicationFlags>().FirstOrDefault();
                                        recordList.Add(set);
                                        break;
                                    }
                                case "Applications":
                                    {
                                        var set = multipleResults.Read<ApplicationData>();
                                        recordList.Add(set.ToList());
                                        break;
                                    }
                                case "ApplicationData":
                                    {
                                        var set = multipleResults.Read<ApplicationData>().FirstOrDefault(); 
                                        recordList.Add(set);
                                        break;
                                    }
                                //case "SomsReleaseDates":
                                //    {
                                //        var set = multipleResults.Read<ReleaseDateChanged>();
                                //        recordList.Add(set.ToList());
                                //        break;
                                //    }
                            }
                        }
                    }
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static int GetIntRecord<T>(string spName, List<ParameterInfo> parameters)
        {
            int intRecord = 0;
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    DynamicParameters p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }

                    using (var reader = SqlMapper.ExecuteReader(objConnection, spName, p, commandType: CommandType.StoredProcedure))
                    {
                        if (reader != null && reader.Read())
                        {
                            intRecord = Convert.ToInt32(reader[0].ToString());
                        }
                    }
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return intRecord;
        }
        public static int ExecuteQuery(string spName, List<ParameterInfo> parameters)
        {
            int success = 0;
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    DynamicParameters p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                        p.Add("@" + param.ParameterName, param.ParameterValue);
                    }
                    success = SqlMapper.Execute(objConnection, spName, p, commandType: CommandType.StoredProcedure);
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return success;
        }
        public static int ExecuteQueryWithIntOutputParam(string spName, List<ParameterInfo> parameters)
        {
            int success = 0;
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                try { 
                    objConnection.Open();
                    DynamicParameters p = new DynamicParameters();
                    foreach (var param in parameters)
                    {
                       p.Add("@" + param.ParameterName, param.ParameterValue);
                    }              
                   success = SqlMapper.Execute(objConnection, spName, p, commandType: CommandType.StoredProcedure);
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally {
                    objConnection.Close();
                }
            }
            return success;
        }
        public static int ExecuteQueryWithReturnValue(string SqlQery, int dbc)
        {
            int newId = 0;
            var ut = new Utils(dbc);
            using (SqlConnection objConnection = new SqlConnection(ut.ConnectString))
            {
                try
                {
                    objConnection.Open();
                    newId = objConnection.QuerySingle<int>(SqlQery);
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return newId;
        }
        public static int ExecuteCommand(string query, int dbc)
        {
            int success = 0;
            Utils ut = new Utils(dbc); 
            using (SqlConnection objConnection = new SqlConnection(ut.ConnectString))
            {
                try
                {
                    objConnection.Open();
                    success = SqlMapper.Execute(objConnection, query, commandType: CommandType.Text);                  
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return success;
        }
        public static int ExecutePATSCommand(string query)
        {
            int success = 0;
            using (SqlConnection objConnection = new SqlConnection(Utils.PATSConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    success = SqlMapper.Execute(objConnection, query, commandType: CommandType.Text);
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return success;
        }
        public static List<T> ExecuteCommands<T>(string query, int dbc)
        {
            List<T> recordList = new List<T>();
            Utils ut = new Utils(dbc);
            using (SqlConnection objConnection = new SqlConnection(ut.ConnectString))
            {
                try
                {
                    objConnection.Open();
                    recordList = SqlMapper.Query<T>(objConnection, query, commandType: CommandType.Text).AsList();
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<T> ExecutePATSCommands<T>(string query)
        {
            List<T> recordList = new List<T>();
            using (SqlConnection objConnection = new SqlConnection(Utils.PATSConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    recordList = SqlMapper.Query<T>(objConnection, query, commandType: CommandType.Text).AsList();
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<object> ExecuteMultipleAppCommands(string query)
        {
            List<object> recordList = new List<object>();
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    var multi = objConnection.QueryMultiple(query);
                    {                        
                        recordList.Add(multi.Read<Facility>().ToList());
                        recordList.Add(multi.Read<OutcomeType>().ToList());
                        recordList.Add(multi.Read<ApplicationData>().FirstOrDefault());
                    };
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<object> ExecuteCommandsWithReturnList<T>(string query)
        {
            List<object> recordList = new List<object>();
            using (SqlConnection objConnection = new SqlConnection(Utils.ConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    var multi = objConnection.QueryMultiple(query);
                    {                        
                       recordList.Add(multi.Read<DerivedSomsData>().FirstOrDefault());
                       recordList.Add(multi.Read<InmateProfileData>().FirstOrDefault());
                       recordList.Add(multi.Read<Episodes>().ToList());
                       recordList.Add(multi.Read<County>().ToList());
                       recordList.Add(multi.Read<Facility>().ToList());
                       recordList.Add(multi.Read<Gender>().ToList());
                       recordList.Add(multi.Read<EpisodeAcpDshType>().ToList());
                       recordList.Add(multi.Read<EpisodeMdoSvpType>().ToList());
                       recordList.Add(multi.Read<EpisodeMedReleaseType>().ToList());
                       recordList.Add(multi.Read<LookUpTable>().ToList());     
                    }
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                   objConnection.Close();
                }
            }
            return recordList;
        }
        public static List<object> ExecutePATSCommandsWithIRP(string query)
        {
            List<object> recordList = new List<object>();
            using (SqlConnection objConnection = new SqlConnection(Utils.PATSConnectionString()))
            {
                try
                {
                    objConnection.Open();
                    var multi = objConnection.QueryMultiple(query);
                    {
                        recordList.Add(multi.Read<IRPSet>().ToList());
                        recordList.Add(multi.Read<int>().FirstOrDefault());
                    }
                }
                catch (SqlException sqlEx)
                {
                    throw sqlEx;
                }
                catch (Exception err)
                {
                    throw err;
                }
                finally
                {
                    objConnection.Close();
                }
            }
            return recordList;
        }
    }
}

