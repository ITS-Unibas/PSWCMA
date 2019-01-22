using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net;
using System.IO;
using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Management.Automation;
using System.Collections.ObjectModel;

namespace PSWCMA.ModuleClasses
{
    class Configuration
    {
        private string url { get; }
        private string path { get; }
        private string branchName { get; }
        private bool testing { get; }
        private const string gitExec = "C:\\Program Files\\Git\\bin\\git.exe";
        private string cloneDir { get; }
        public Configuration(string url, string path, string branchName, bool testing)
        {
            this.url = url;
            this.path = path;
            this.branchName = branchName;
            this.testing = testing;
            cloneDir = Path.Combine(path, "Configuration");
        }

       
        public void runConfigurations(IList<ADGroup.Group> groups)
        {
            downloadConfigurations();
            IList<string> grpNames = new List<string>();
            foreach(ADGroup.Group group in groups)
            {
                grpNames.Add(group.Name);
            }
            updateLCM(groups.Count(), grpNames);

            //get all downloaded configuration to compare it with actual fetched groups
            string[] configs = Directory.GetDirectories(cloneDir);
            IList<string> configList = new List<string>(configs);
            //delete .git directory
            string gitDir = Path.Combine(cloneDir, ".git");
            if (configList.Contains<string>(gitDir))
            {
                configList.Remove(gitDir);
            }

            //add only this config path to list which should be processed
            IList<string> temp = new List<string>();
            foreach(string config in configList)
            {
                foreach (string grp in grpNames)
                {
                    if(new DirectoryInfo(config).Name == grp)
                    {
                        temp.Add(config);
                    }
                }
            }
            configList = temp;

            bool hasConfigurations = false;
            using (PowerShell ps = PowerShell.Create())
            {
                string cmd = "Get-DscConfiguration -ErrorAction SilentlyContinue";
                ps.AddScript(cmd);
                Collection<PSObject> pso = ps.Invoke();
                hasConfigurations = pso.Count > 0;
            }

            if (grpNames.Count() == 1)
            {
                string configPath = Path.Combine(configList.ElementAt(0), new DirectoryInfo(configList.ElementAt(0)).Name + ".ps1");
                if (FileHashOperations.filehasChanged(path, configPath) || !hasConfigurations)
                {

                    //compile configurations
                    Collection<PSObject> pso;
                    using (PowerShell ps = PowerShell.Create())
                    {
                        string cmd = "Invoke-Expression " + configPath;
                        ps.AddScript(cmd);
                        pso = ps.Invoke();
                    }

                    if (pso.Count > 0)
                    {
                        //start dsc configuration job and stop job if still running
                        using (PowerShell ps = PowerShell.Create())
                        {
                            string cmd = "Start-DscConfiguration -Path " + configList.ElementAt(0) + " -ComputerName localhost -ErrorAction Stop";
                            ps.AddScript(cmd);
                            ps.Invoke();
                            string jobId = pso[0].Properties["Id"].Value.ToString();
                            ps.Commands.Clear();
                            cmd = "Wait-Job -Id " + jobId + " -Timeout 900";
                            ps.AddScript(cmd);
                            pso = ps.Invoke();
                            string state = pso[0].Properties["State"].Value.ToString();
                            if (state == "Completed")
                            {
                                cmd = "Stop-Job -Id " + jobId;
                                ps.Commands.Clear();
                                ps.AddScript(cmd);
                                ps.Invoke();
                            }
                        }
                    }
                }
            }
            else
            {
                Collection<PSObject> pso;
                //compile and publish each dsc configuration to LCM before starting dsc configuration
                foreach (string config in configList)
                {
                    string configPath = Path.Combine(config, new DirectoryInfo(config).Name + ".ps1");
                    if (FileHashOperations.filehasChanged(path, configPath) || !hasConfigurations)
                    {
                        using (PowerShell ps = PowerShell.Create())
                        {
                            string cmd = "Invoke-Expression " + configPath;
                            ps.AddScript(cmd);
                            pso = ps.Invoke();
                        }

                        if (pso.Count > 0)
                        {
                            using (PowerShell ps = PowerShell.Create())
                            {
                                string cmd = "Publish-DscConfiguration -Path " + config + " -ComputerName localhost -ErrorAction Stop";
                                ps.AddScript(cmd);
                                ps.Invoke();
                            }
                        }
                    }

                }

                //start dsc configuration job and stop job if still running
                using (PowerShell ps = PowerShell.Create())
                {
                    string cmd = "Start-DscConfiguration -UseExisting -ComputerName localhost -ErrorAction Stop";
                    ps.AddScript(cmd);
                    pso = ps.Invoke();
                    string jobId = pso[0].Properties["Id"].Value.ToString();
                    ps.Commands.Clear();
                    cmd = "Wait-Job -Id " + jobId + " -Timeout 900";
                    ps.AddScript(cmd);
                    pso = ps.Invoke();
                    string state = pso[0].Properties["State"].Value.ToString();
                    if (state == "Completed")
                    {
                        cmd = "Stop-Job -Id " + jobId;
                        ps.Commands.Clear();
                        ps.AddScript(cmd);
                        ps.Invoke();
                    }

                }

            }

            //clean up pending dsc configuration if there are any
            using (PowerShell ps = PowerShell.Create())
            {
                string cmd = "Get-DscLocalConfigurationManager";
                ps.AddScript(cmd);
                Collection<PSObject> pso = ps.Invoke();
                if(pso[0].Properties["LCMState"].Value.ToString() == "PendingConfiguration")
                {
                    ps.Commands.Clear();
                    cmd = "Remove-DscConfigurationDocument -Stage Pending";
                    ps.AddScript(cmd);
                    ps.Invoke();
                }
            }

            FileHashOperations.updateFileHashes(path, configList);
            Console.Write("finished running command");
            
        }

        private void downloadConfigurations()
        {
            //pull or clone given git repo
            if (checkConnection())
            {
                if (Directory.Exists(cloneDir))
                {
                    gitCmdExec("-C " + cloneDir + " pull");
                }
                else
                {
                    gitCmdExec("clone " + url + " " + cloneDir);
                }

                if (testing)
                {
                    gitCmdExec("-C " + cloneDir + " pull origin " + branchName);
                    gitCmdExec("-C " + cloneDir + " checkout " + branchName);
                }
            }

        }

        private void updateLCM(int configCount, IList<string> configNames)
        {
            //create LCM configuration and apply it
            string LCMDir = Path.Combine(path, "LCM");
            string LCMPath = Path.Combine(LCMDir, "CCM-LCM.ps1");
            if(!Directory.Exists(LCMDir))
            {
                var dir = Directory.CreateDirectory(LCMDir);
            }

            if(File.Exists(LCMPath))
            {
                File.Delete(LCMPath);
            }

            using (StreamWriter file = File.CreateText(LCMPath))
            {
                file.WriteLine("[DSCLocalConfigurationManager()]");
                file.WriteLine("configuration LCMConfig");
                file.WriteLine("{");
                file.WriteLine("Node localhost");
                file.WriteLine("{");
                file.WriteLine("Settings");
                file.WriteLine("{");
                file.WriteLine("ConfigurationModeFrequencyMins = 15");
                file.WriteLine("ConfigurationMode = \"ApplyAndAutoCorrect\"");
                file.WriteLine("RefreshMode = \"Push\"");
                file.WriteLine("RebootNodeIfNeeded = $FALSE");
                file.WriteLine("ActionAfterReboot = \"ContinueConfiguration\"");
                file.WriteLine("AllowModuleOverWrite = $FALSE");
                file.WriteLine("StatusRetentionTimeInDays = \"180\"");
                file.WriteLine("RefreshFrequencyMins = \"30\"");
                file.WriteLine("}");
                if(configCount > 1)
                {
                    foreach(string configName in configNames)
                    {
                        file.WriteLine("PartialConfiguration " + configName);
                        file.WriteLine("{");
                        file.WriteLine("RefreshMode = \"Push\"");
                        file.WriteLine("}");
                    }
                }
                file.WriteLine("}");
                file.WriteLine("}");
                file.WriteLine("");
                file.WriteLine("& LCMConfig -OutputPath " + LCMDir);

            }

            using (PowerShell ps = PowerShell.Create())
            {
                string cmd = "Invoke-Expression " + LCMPath;
                ps.AddScript(cmd);
                ps.Invoke();
            }

            using (PowerShell ps = PowerShell.Create())
            {
                string cmd = "Set-DscLocalConfigurationManager -Path " + LCMDir + " -Force";
                ps.AddScript(cmd);
                ps.Invoke();
            }
        }

        private bool checkConnection()
        {
            //check if git server is up and running
            string[] split = url.Split('/');
            string uri = split[0] + "//" + split[2];
            HttpWebRequest request = (HttpWebRequest) WebRequest.Create(uri);
            request.Timeout = 15000;
            try
            {
                using (HttpWebResponse response = (HttpWebResponse) request.GetResponse())
                {
                    return response.StatusCode == HttpStatusCode.OK;

                }
            } catch (WebException e)
            {
                Console.Write(e.Message);
                return false;
            }
        }

        private void gitCmdExec(string arg)
        {
            using (Process process = new Process())
            {
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.FileName = gitExec;
                process.StartInfo.Arguments = arg;
                process.StartInfo.CreateNoWindow = true;
                process.Start();
                process.WaitForExit();
            }
        }
    }
}
