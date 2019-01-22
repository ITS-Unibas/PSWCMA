using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;

namespace PSWCMA.Pre_Requisits
{
    public static class PackageManagementInstaller
    {
        public static bool installPSPackagemgmt()
        {
            using (PowerShell ps = PowerShell.Create())
            {
                string command = "Install-Module PackageManagement -RequiredVersion '1.2.2' -Force -ErrorAction Stop";
                ps.AddScript(command);
                var result = ps.Invoke();

            }

            using (PowerShell ps = PowerShell.Create())
            {
                string command = "Get-InstalledModule -Name PackageManagement -RequiredVersion '1.2.2' -ErrorAction SilentlyContinue";
                ps.AddScript(command);
                var result = ps.Invoke();
                return result.Count > 0;
            }
        } 
    }
}
