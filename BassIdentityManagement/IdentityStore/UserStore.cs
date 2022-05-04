using BassIdentityManagement.DAL;
using BassIdentityManagement.Entities;
using Microsoft.AspNet.Identity;
using System;
using System.Threading.Tasks;

namespace BassIdentityManagement.IdentityStore
{
    public class UserStore : IUserStore<ApplicationUser, int>
    {
        #region IUserStore
        public Task CreateAsync(ApplicationUser user)
        {
            if (user != null)
            {
                return Task.Factory.StartNew(() =>
                {
                     UserController.NewUser(user);
                });
            }
            throw new ArgumentNullException("user");
        }

        public Task DeleteAsync(ApplicationUser user)
        {
            if (user != null)
            {
                return Task.Factory.StartNew(() =>
                {
                    UserController.DeleteUser(user);
                });
            }
            throw new ArgumentNullException("user");
        }

        public void Dispose()
        {

        }

        public Task<ApplicationUser> FindByIdAsync(int userId)
        {
            if (userId > 0)
            {
                return Task.Factory.StartNew(() =>
                {
                    return UserController.GetUser(userId);
                });
            }
            throw new ArgumentNullException("userId");
        }

        public Task<ApplicationUser> FindByNameAsync(string userName)
        {
            if (!string.IsNullOrEmpty(userName))
            {
                return Task.Factory.StartNew(() =>
                {
                    return UserController.GetUserByUsername(userName);
                });
            }
            throw new ArgumentNullException("userName");
        }

        public ApplicationUser FindByName(string userName)
        {
            if (!string.IsNullOrEmpty(userName))
            {
                return UserController.GetUserByUsername(userName);
            }
            throw new ArgumentNullException("userName");
        }
        public Task<string> GetPasswordHashAsync(ApplicationUser user)
        {
            return Task.FromResult(user.PasswordHash);
        }

        public Task<bool> SetPasswordHashAsync(ApplicationUser user, string passwordHash)
        {
            user.PasswordHash = passwordHash;
            return Task.FromResult(true);
        }

        public Task<int> GetLoginFailureAsync(ApplicationUser user)
        {
            return Task.FromResult<int>(user.LoginFailures);
        }

        public Task UpdateAsync(ApplicationUser user)
        {
            if (user != null)
            {
                return Task.Factory.StartNew(() =>
                {
                    return UserController.UpdateUser(user);
                });
            }
            throw new ArgumentNullException("userName");
        }
        #endregion
    }
}
