using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using Microsoft.Win32;
using System.Collections;
using System.IO;
using System.Security.Cryptography;
using System.Security;
using PSWCMA.Pre_Requisits;

namespace PSWCMA
{

    [Cmdlet(VerbsCommon.New, "AgentConfiguration")]
    public class NewAgentConfiguration : Cmdlet
    {
        [Parameter(Mandatory = true)]
        public string LDAPFilter { get; set; }

        [Parameter(Mandatory = true)]
        public string ActiveDirectory { get; set; }

        [Parameter(Mandatory = true)]
        public string Git { get; set; }

        [Parameter(Mandatory = true)]
        public string FilePath { get; set; }

        [Parameter(Mandatory = true)]
        public string BaseLine { get; set; }

        [Parameter(Mandatory = true)]
        public string LDAPUser { get; set; }

        [Parameter(Mandatory = true)]
        public string LDAPPassword { get; set; }

        public string TestGroup { get; set; } = "";

        public string TestBranchName { get; set; } = "";

        private string regPath;
        private string regPathAppwiz;
        private string version = "0.0";

        protected override void BeginProcessing()
        {
            base.BeginProcessing();
            //TODO: TEST PREREQ
            regPath = "HKEY_LOCAL_MACHINE\\Software\\PSWCMA";
            regPathAppwiz = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\PSWCMA";
            PowerShell ps = PowerShell.Create();
            ps.AddScript("Get-InstalledModule -Name \"PSWCMA\" | Select-Object -ExpandProperty Version");
            var tempVersion = ps.Invoke();
            if (tempVersion.Count > 0)
            {
                version = tempVersion[0].BaseObject.ToString();
            }
            
            WriteObject("finished begin");
            ps.Dispose();
        }

        protected override void ProcessRecord()
        {
            if(Directory.Exists(FilePath))
            {
                Directory.Delete(FilePath, true);
            }
            Directory.CreateDirectory(FilePath);
            //TODO: Secure Password --> go the C# way ;)
            //string keyFilepath = Path.Combine(FilePath, "secure.key");
            //var key = new byte[32];
            //RNGCryptoServiceProvider.Create().GetBytes(key);
            //var file = File.Create(keyFilepath);
            //file.Close();
            //using (System.IO.StreamWriter writer = new StreamWriter(@keyFilepath))
            //{
            //    foreach (byte b in key)
            //    {
            //        writer.WriteLine(b);
            //    }
            //}
            //Object securedPw = null;
            //using (PowerShell ps = PowerShell.Create())
            //{
            //    string convertCmd = "ConvertTo-SecureString -AsPlainText " + LDAPPassword + " -Force | ConvertFrom-SecureString -Key " + key;
            //    ps.AddScript(convertCmd);
            //    securedPw = ps.Invoke();

            //}
            Registry.SetValue(regPath, "FilePath", FilePath, RegistryValueKind.String);
            Registry.SetValue(regPath, "Git", Git, RegistryValueKind.String);
            Registry.SetValue(regPath, "ActiveDirectory", ActiveDirectory, RegistryValueKind.String);
            Registry.SetValue(regPath, "LDAPUserName", LDAPUser, RegistryValueKind.String);
            Registry.SetValue(regPath, "LDAPPassword", LDAPPassword, RegistryValueKind.String);
            Registry.SetValue(regPath, "AdFilter", LDAPFilter, RegistryValueKind.String);
            Registry.SetValue(regPath, "BaseLineConfig", BaseLine, RegistryValueKind.String);
            Registry.SetValue(regPath, "TestGroup", TestGroup, RegistryValueKind.String);
            Registry.SetValue(regPath, "TestBranchName", TestBranchName, RegistryValueKind.String);

            WriteObject("Module Config written");

            Registry.SetValue(regPathAppwiz, "Comments", "PowerShell Windows Configuration Management Agent", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "Contact", "University of Basel - ITS", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "DisplayVersion", version, RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "NoModify", "1", RegistryValueKind.DWord);
            Registry.SetValue(regPathAppwiz, "NoRemove", "1", RegistryValueKind.DWord);
            Registry.SetValue(regPathAppwiz, "Publisher", "University of Basel - ITS", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "SystemComponent", "0", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "URLInfoAbout", "www.unibas.ch", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "DisplayName", "PSWCMA", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "InstallLocation", "C:\\Program Files\\WindowsPowerShell\\Modules\\PSWCMA", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "UninstallString", "\"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" -NoProfile -WindowStyle Hidden -command \" & { Import - Module PSWCMA; Uninstall - CMAgent}\"", RegistryValueKind.String);
            Registry.SetValue(regPathAppwiz, "DisplayIcon", "%SystemRoot%\\System32\\SHELL32.dll,238", RegistryValueKind.ExpandString);
            WriteObject("Appwiz written");

            bool isGitInstalled = GitInstaller.installGit();
            if(isGitInstalled)
            {
                WriteObject("Git installed");
            }

            bool isPkgMgtmInstalled = PackageManagementInstaller.installPSPackagemgmt();
            if(isPkgMgtmInstalled)
            {
                WriteObject("Package Management installed");
            }
        }
    }

      
}
