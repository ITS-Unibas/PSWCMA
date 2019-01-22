using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using Microsoft.Win32;
using PSWCMA.ModuleClasses;

namespace PSWCMA
{
    [Cmdlet(VerbsLifecycle.Install, "Configurations")]
    public class InstallConfigurations : Cmdlet
    {
        private const string configPath = "Software\\PSWCMA";
        private string adServer = "";
        private string adFilter = "";
        private string baseLine = "";
        private string filePath = "";
        private string gitServer = "";
        private string ldapUser = "";
        private string ldapPassword = "";
        private string testBranch = "";
        private string testGroup = "";
        ADGroup groups;
        Configuration configuration;


        protected override void BeginProcessing()
        {
            base.BeginProcessing();
            RegistryKey rk = Registry.LocalMachine;
            RegistryKey sk = rk.OpenSubKey(configPath);
            if (sk != null)
            {
                adServer = sk.GetValue("ActiveDirectory").ToString();    
                adFilter = sk.GetValue("AdFilter").ToString();
                baseLine = sk.GetValue("BaseLineConfig").ToString();
                filePath = sk.GetValue("FilePath").ToString();
                gitServer = sk.GetValue("Git").ToString();
                ldapUser = sk.GetValue("LDAPUserName").ToString();
                ldapPassword = sk.GetValue("LDAPPassword").ToString();
                testBranch = sk.GetValue("TestBranchName").ToString();
                testGroup = sk.GetValue("TestGroup").ToString();
            }
            groups = new ADGroup(adFilter, adServer, ldapUser, ldapPassword, filePath, baseLine);
            configuration = new Configuration(gitServer, filePath, testBranch, testBranch != "");
        }

        protected override void ProcessRecord()
        {
            IList<ADGroup.Group> grpList  = groups.fetchGroups();
            configuration.runConfigurations(grpList);

        }
    }
}
