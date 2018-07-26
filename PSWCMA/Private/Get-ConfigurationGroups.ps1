Function Get-ConfigurationGroups {
    <#
      .Synopsis
      Reads Groups from AD where this computer is included

      .Description
      Reads Groups from AD where this computer is included

      .Parameter Filter
      Filter for samAccoutnName of the CCM Groups. Accepts Alias 'F'. Default "*ccm*"

      .Parameter LDAPPath
      AD which should be searched in. Accepts Alias 'AD'. Default "UNIBASEL.ADS.UNIBAS.CH"

      .Outputs
      System.String Array. Get-LDAPGroup returns an string array with all config groups. Can return null
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [alias('F')]
        [string]$Filter,
        [Parameter(Mandatory = $true)]
        [alias('AD')]
        [string]$ADServer,
        [Parameter(Mandatory = $true)]
        $Path,
        [Parameter(Mandatory = $true)]
        $BaseLine
    )
    begin {
        $Localhost = hostname
        $Groups = New-Object System.Collections.ArrayList
        $isOnline = $false
    }
    process {
        try {
            $DN = (Get-ADComputer $Localhost -Server $ADServer).DistinguishedName
            Write-Verbose "Distinguished Name of localhost is $DN"
            Get-ADGroup -LDAPFilter "(&(member:1.2.840.113556.1.4.1941:=$DN)(SamAccountName=$Filter))" -Properties member | Select-Object Name | ForEach-Object { $Groups.Add($_) | Out-Null }
            Write-Verbose "Computer is in the following Groups $Groups"
            $isOnline = $true

        }
        catch {
            Write-Warning "Unable to get Groups from AD for this computer $Localhost"
        }

    }
    end {
        $BaseLineObject = New-Object -TypeName psobject -Property @{
            Name = $BaseLine
        }
        $Groups.Add($BaseLineObject) | Out-Null
        Write-Debug $isOnline
        if ($isOnline) {
            Save-GroupCache -Data $Groups -Path $Path
        }
        elseif (!(Test-Path -Path $Path)) {
            Save-GroupCache -Data $Groups -Path $Path
        }
        else {
            $Groups = Get-GroupCache -Path $Path
        }
        return $Groups
    }
}
