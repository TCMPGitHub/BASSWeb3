using Microsoft.AspNet.Identity;

namespace BassIdentityManagement.Entities
{
    public class RoleInfo : IRole
    {
        public string Id { get; set; }
        public string Name { get; set; }
    }
}