Function Install-Git {

    <# 

      .SYNOPSIS
      Installs or updates git for windows.
      .DESCRIPTION
      Borrowed heavily from https://github.com/PowerShell/vscode-powershell/blob/develop/scripts/Install-VSCode.ps1. Sourcecode available at https://github.com/tomlarse/Install-Git
      Install and run with Install-Script Install-Git; Install-Git.ps1
      .EXAMPLE
      Install-Git.ps1
      .NOTES
      This script is licensed under the MIT License:
      Copyright (c) Microsoft Corporation.
      Permission is hereby granted, free of charge, to any person obtaining a copy
      of this software and associated documentation files (the "Software"), to deal
      in the Software without restriction, including without limitation the rights
      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the Software is
      furnished to do so, subject to the following conditions:
      The above copyright notice and this permission notice shall be included in all
      copies or substantial portions of the Software.
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
      SOFTWARE.
  #>
    [Cmdletbinding()]
    Param()
    if (!($IsLinux -or $IsOSX)) {

        $gitExePath = "C:\Program Files\Git\bin\git.exe"

        #Added TLS negotiation Fork jmangan68
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

        foreach ($asset in (Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest).assets) {
            if ($asset.name -match 'Git-\d*\.\d*\.\d*.\d*-64-bit\.exe') {
                $dlurl = $asset.browser_download_url
                $newver = $asset.name
            }
        }

        try {
            $ProgressPreference = 'SilentlyContinue'

            if (!(Test-Path $gitExePath)) {
                Write-Verbose "`nDownloading latest stable git..." 
                Write-Log -Level INFORMATION -Message "Downloading latest stable git..."
                Remove-Item -Force $env:TEMP\git-stable.exe -ErrorAction SilentlyContinue
                Invoke-WebRequest -Uri $dlurl -OutFile $env:TEMP\git-stable.exe

                Write-Verbose "`nInstalling git..." 
                Write-Log -Level INFORMATION -Message "Installing git..."
                Start-Process -Wait $env:TEMP\git-stable.exe -ArgumentList /silent
            }
            else {
                $updateneeded = $false
                Write-Log -Level INFORMATION -Message "git is already installed. Check if possible update..."
                Write-Verbose "`ngit is already installed. Check if possible update..." 
                (git version) -match "(\d*\.\d*\.\d*)" | Out-Null
                $installedversion = $matches[0].split('.')
                $newver -match "(\d*\.\d*\.\d*)" | Out-Null
                $newversion = $matches[0].split('.')

                if (($newversion[0] -gt $installedversion[0]) -or ($newversion[0] -eq $installedversion[0] -and $newversion[1] -gt $installedversion[1]) -or ($newversion[0] -eq $installedversion[0] -and $newversion[1] -eq $installedversion[1] -and $newversion[2] -gt $installedversion[2])) {
                    $updateneeded = $true
                }

                if ($updateneeded) {
                    Write-Log -Level INFORMATION -Message "Update available. Downloading latest stable git..."
                    Write-Verbose "`nUpdate available. Downloading latest stable git..." 
                    Remove-Item -Force $env:TEMP\git-stable.exe -ErrorAction SilentlyContinue
                    Invoke-WebRequest -Uri $dlurl -OutFile $env:TEMP\git-stable.exe

                    Write-Log -Level INFORMATION -Message "Installing update..."
                    Write-Verbose "`nInstalling update..." 
                    $sshagentrunning = get-process ssh-agent -ErrorAction SilentlyContinue
                    if ($sshagentrunning) {
                        Write-Log -Level WARNING -Message "Killing ssh-agent..."
                        Write-Verbose "`nKilling ssh-agent..." 
                        Stop-Process $sshagentrunning.Id
                    }

                    Start-Process -Wait $env:TEMP\git-stable.exe -ArgumentList /silent
                }
                else {
                    Write-Log -Level INFORMATION -Message "No update available. Already running latest version..."
                    Write-Verbose "`nNo update available. Already running latest version..." 
                }

            }
            Write-Log -Level INFORMATION -Message "Installation complete!"
            Write-Verbose "`nInstallation complete!`n`n" -ForegroundColor Green
        }
        finally {
            #Refresh der PATH environment variable
            foreach($level in "Machine","User") {
                [Environment]::GetEnvironmentVariables($level).GetEnumerator() | % {
                   # For Path variables, append the new values, if they're not already in there
                   if($_.Name -match 'Path$') {
                      $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select -unique) -join ';'
                   }
                   $_
                } | Set-Content -Path { "Env:$($_.Name)" }
             }
            $ProgressPreference = 'Continue'
        }
    }
    else {
        Write-Error "This script is currently only supported on the Windows operating system."
    }
}