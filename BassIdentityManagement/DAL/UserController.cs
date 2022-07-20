using BassIdentityManagement.Data;
using BassIdentityManagement.Entities;
using System.Collections.Generic;

namespace BassIdentityManagement.DAL
{
    public static class UserController
    {
        public static int NewUser(ApplicationUser objUser)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "UserID", ParameterValue = objUser.UserID });
            parameters.Add(new ParameterInfo() { ParameterName = "UserName", ParameterValue = objUser.UserName });
            parameters.Add(new ParameterInfo() { ParameterName = "Email", ParameterValue = objUser.Email });
            //parameters.Add(new ParameterInfo() { ParameterName = "Password", ParameterValue = objUser.Password });
            //parameters.Add(new ParameterInfo() { ParameterName = "Status", ParameterValue = objUser.Status });
            int success = SqlHelper.ExecuteQuery("NewUser", parameters);
            return success;
        }
        public static int DeleteUser(ApplicationUser objUser)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "UserID", ParameterValue = objUser.UserID });
            int success = SqlHelper.ExecuteQuery("DeleteUser", parameters);
            return success;
        }

        public static ApplicationUser GetUser(int userId)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "UserID",
                                                 ParameterValue = userId });
            ApplicationUser oUser = SqlHelper.GetRecord<ApplicationUser>("spGetUser", parameters);
            return oUser;
        }

        public static ApplicationUser GetUserByUsername(string userName)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "Username", ParameterValue = userName });
            ApplicationUser oUser = SqlHelper.GetRecord<ApplicationUser>("spGetUserByUsername", parameters);
            return oUser;
        }
        
        public static int UpdateUser(ApplicationUser objUser)
        {
            List<ParameterInfo> parameters = new List<ParameterInfo>();
            parameters.Add(new ParameterInfo() { ParameterName = "Email", ParameterValue = objUser.Email });
            int success = SqlHelper.ExecuteQuery("UpdateUser", parameters);
            return success;
        }
        public static int UpdateLoginFailure(int UserID, int logins)
        {
            var query = string.Empty;
            if (logins == 0)
            {
                query = string.Format("Update dbo.[User] Set LoginFailures ={0}, LastLoginDate = GetDate() Where UserID ={1}", logins, UserID);
            }
            else
            {
                query = string.Format("Update dbo.[User] Set LoginFailures ={0} Where UserID ={1}", logins, UserID);
            }
            return SqlHelper.ExecuteCommand(query, 1);
        }

        public static int RecordPageLoad(int UserID, string Controller, string Action, string Method, string strIp)
        {
            return SqlHelper.ExecuteCommand(
              string.Format("INSERT INTO dbo.PageLoad(UserID,Controller,Action,Method,DateTimeOffset,IpAddress) VALUES({0},'{1}','{2}','{3}',GetDate(), {4})", UserID, Controller, Action, Method, strIp), 1);
        }
    }
}
