using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Collections;
using System.DirectoryServices;
using System.IO;
using Newtonsoft.Json;

namespace PSWCMA.ModuleClasses
{
    public class ADGroup
    {
        public string filter { get; }
        public string adServer { get; }
        public string user { get; }
        public string pw { get; }
        public string filePath { get; }
        public string baseLine { get; }

        private IList<Group> adGroups { get; set; }
        private string cachePath { get; }
        public ADGroup(string filter, string adServer, string user, string pw, string filePath, string baseLine)
        {
            this.filter = filter;
            this.adServer = adServer;
            this.user = user;
            this.pw = pw;
            this.filePath = filePath;
            this.baseLine = baseLine;
            adGroups = new List<Group>();
            cachePath = Path.Combine(this.filePath, "GroupCache.json");
        }

        public IList<Group> fetchGroups()
        {
            bool online = true;
            try
            {
                DirectoryEntry directoryEntry = new DirectoryEntry("LDAP://" + adServer + ":636");
                string dnFilter = "(&(objectCategory=computer)(objectClass=computer)(cn=" + System.Environment.MachineName + "))";
                DirectorySearcher directoryObject = new DirectorySearcher(directoryEntry, dnFilter);
                string dn = (directoryObject.FindOne().Properties["distinguishedname"])[0].ToString();
                string groupFilter = "(&(member:1.2.840.113556.1.4.1941:=" + dn + ")(SamAccountName=" + filter + "))";
                directoryObject = new DirectorySearcher(directoryEntry, groupFilter);
                directoryObject.PropertiesToLoad.Add("SAMAccountName");
                foreach (SearchResult result in directoryObject.FindAll())
                {
                    var entry = result.GetDirectoryEntry();
                    adGroups.Add(new Group(entry.Properties["SAMAccountName"].Value.ToString()));
                }
            }
            catch
            {
                online = false;
            }

            if (online || File.Exists(filePath))
            {
                //save cache
                adGroups.Add(new Group(baseLine));
                saveGroupCache();
                
            }
            else
            {
                //load cache
                adGroups = loadGroupCache();
                
            }

            return adGroups;
        }

        private void saveGroupCache()
        {
            if (!File.Exists(cachePath))
            {
                FileStream f = File.Create(cachePath);
                f.Close();

            }
            string json = JsonConvert.SerializeObject(adGroups, Formatting.Indented);
            File.WriteAllText(cachePath, json);
        }

        private IList<Group> loadGroupCache()
        {
            string json = File.ReadAllText(cachePath);
            IList<Group> groups = JsonConvert.DeserializeObject<List<Group>>(json);

            return groups;
        }

        public class Group
        {
            public string Name { get; }
            public Group(string name)
            {
                this.Name = name;
            }
        }
    }
}
