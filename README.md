# PiWeb Cloud API Authentication PowerShell Module

This PowerShell module contains the Get-PiWebCloudToken function that allows you to retrieve a PiWebCloud token. The module uses the [PSAuthClient](https://github.com/alflokken/PSAuthClient) module to perform authorization and authentication against the PiWebCloud OAuth2 service. The token can be used for authentication with the [PiWeb Cloud API](https://zeiss-piweb.github.io/PiWeb-Api/general).

Please note that the token is stored in plain text in the token.json file. You are responsible for encrypting the file yourself.

## Prerequisites

Before you can use this module, you need to install the PSAuthClient module. To do this, run the following command in PowerShell as an administrator:

```powershell
Install-Module -Name PSAuthClient -MinimumVersion 1.1.1 -MaximumVersion 1.1.1 -Scope CurrentUser -Force
```

## Usage

The following example shows how to fetch all parts from the database.

```powershell
Import-Module -Name .\Get-PiWebCloudToken.psm1

$databaseIntanceId = "7752a068-16bb-456c-850c-db9291599a45"
$token = Get-PiWebCloudToken $databaseIntanceId

function Get-Parts ([PSCustomObject]$token, [string]$databaseIntanceId) {
    $headers = @{
        Authorization = "Bearer $($token.access_token)"
    }
    $parts = Invoke-RestMethod -Method Get -Uri "https://piwebcloud-service.metrology.zeiss.com/$($databaseIntanceId)/dataServiceRest/parts" -Headers $headers
    $parts
}

Get-Parts $token $databaseIntanceId
```

Further information on using the PiWeb API can be found on the official site [here](https://zeiss-piweb.github.io/PiWeb-Api/general).

## License

[MIT](https://choosealicense.com/licenses/mit/)
