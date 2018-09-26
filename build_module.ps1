If ($env:APPVEYOR_REPO_BRANCH -ne 'production') {
    Write-Host "Not production branch. Not building..."
    exit
}

Publish-Module -Name .\PSWCMA -NuGetApiKey $env:NuGetApiKey