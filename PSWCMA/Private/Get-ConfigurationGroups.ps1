Function Get-ConfigurationGroups {
    <#
      .Synopsis
      Reads Groups from AD where this computer is included

      .Description
      Reads Groups with the correct prefix recursivly from AD where this computer is included.

      .Parameter Filter
      Filter for samAccoutnName of the CCM Groups. Accepts Alias 'F'.

      .Parameter ADServer
      AD which should be searched in. Accepts Alias 'AD'.

      .Parameter BaseLine
      Name of the baseline config which also should be returned as group and saved to cache. Accepts Alias 'B'.

      .Outputs
      System.Array. Get-LDAPGroup returns an string array with all config groups. Can return null
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
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [alias('B')]
        [string]$BaseLine
    )
    begin {
        $Localhost = hostname
        $Groups = New-Object System.Collections.ArrayList
        $isOnline = $false
    }
    process {
        try {
            #Get Distinguished Name of the current computer
            $DN = (Get-ADComputer $Localhost -Server $ADServer).DistinguishedName
            Write-Verbose "Distinguished Name of localhost is $DN"
            #Search for groups with the specific filter for this computer and adds alls matches to the arraylist
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
        #Adds baseline group to the arraylist
        $Groups.Add($BaseLineObject) | Out-Null
        Write-Debug $isOnline
        #if the there could be established a connection to the AD or the cache is not existing, the group cache will be saved. If not cache will be read
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
