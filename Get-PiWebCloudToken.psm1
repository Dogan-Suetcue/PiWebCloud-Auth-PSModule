$global:ERROR_REPORT_PATH = "$($PSScriptRoot)\Error.log"
$global:TOKEN_PATH = "$($PSScriptRoot)\token.json"

$global:REDIRECT_URI = "urn:ietf:wg:oauth:2.0:oob"
$global:SCOPE = "piweb email offline_access"
$global:CLIENT_ID = @{
    Name = "client_id"
    Value = "f1ddf74a-7ed1-4963-ab60-a1138a089791"
}
$global:CLIENT_SECRET = @{
    Name = "client_secret"
    Value = "d2940022-7469-4790-9498-776e3adac79f"
}

function Get-PiWebCloudToken ([string]$databaseInstanceId) {
    Get-PSAuthClientModule

    if (Test-Path -Path $global:TOKEN_PATH) {
        $token = Get-Content -Path $global:TOKEN_PATH | ConvertFrom-Json

        if (([System.DateTime]::Now -ge $token.expiry_datetime) -and ($token.scope.Contains("offline_access"))) {
            return Update-PiWebCloudToken $token
        }
        else {
            return $token
        }
    }
    else {
        return New-PiWebCloudToken $global:TOKEN_PATH
    }
}

function Get-PSAuthClientModule {
    if (Get-Module -Name PSAuthClient -ListAvailable) {
        Import-Module -Name PSAuthClient -MinimumVersion 1.1.1 -MaximumVersion 1.1.1
    }
    else {
        try {
            Install-Module -Name PSAuthClient -MinimumVersion 1.1.1 -MaximumVersion 1.1.1 -Scope CurrentUser -Force
            Import-Module -Name PSAuthClient -MinimumVersion 1.1.1 -MaximumVersion 1.1.1
        }
        catch {
            Write-Error "Failed to install PSAuthClient module. Please contact your system administrator for assistance."
            exit    
        }
    }
}

function Update-PiWebCloudToken ([PSCustomObject]$token, [string]$databaseInstanceId) {
    try {
        $openIdConfiguration = Get-OpenIdConfiguration $databaseInstanceId
        $token | Add-Member -MemberType NoteProperty -Name "uri" -Value $openIdConfiguration.token_endpoint
        $token | Add-Member -MemberType NoteProperty -Name $global:CLIENT_ID.Name -Value $global:CLIENT_ID.Value
        $token = Invoke-OAuth2TokenEndpoint -uri $token.uri -client_id $token.client_id -refresh_token $token.refresh_token -scope $token.scope
        Set-Content -Path $tokenPath -Value ($token | ConvertTo-Json)
        return $token   
    }
    catch {
        Set-Content -Path $global:ERROR_REPORT_PATH -Value $Error
    }
}

function New-PiWebCloudToken ([string]$tokenPath, [string]$databaseInstanceId) {
    try {
        $openIdConfiguration = Get-OpenIdConfiguration $databaseInstanceId

        $authorization_endpoint = $openIdConfiguration.authorization_endpoint
        $token_endpoint = $openIdConfiguration.token_endpoint
        $parameters = @{
            client_id        = $global:CLIENT_ID.Value
            scope            = $global:SCOPE
            redirect_uri     = $global:REDIRECT_URI
            uri              = $authorization_endpoint
        }

        $response = Invoke-OAuth2AuthorizationEndpoint @parameters

        $parameters = $response
        $parameters.Add("uri", $token_endpoint)
        $parameters.Add($global:CLIENT_SECRET.Name, $global:CLIENT_SECRET.Value)
        $token = Invoke-OAuth2TokenEndpoint @parameters

        Set-Content -Path $tokenPath -Value ($token | ConvertTo-Json)

        return $token
    }
    catch {
        Set-Content -Path $global:ERROR_REPORT_PATH -Value $Error
    }
}

function Get-OpenIdConfiguration ([string]$databaseInstanceId) {
    try {
        $issuerUrl = "https://piwebcloud-service.metrology.zeiss.com/$($databaseInstanceId)/OAuthServiceRest/oauthTokenInformation"
        $response = Invoke-RestMethod -Method Get -Uri $issuerUrl
    
        $openIdUrl = "$($response.openIdAuthority)/.well-known/openid-configuration"
        return Invoke-RestMethod -Method Get -Uri $openIdUrl   
    }
    catch {
        Set-Content -Path $global:ERROR_REPORT_PATH -Value $Error
    }
}

Export-ModuleMember -Function Get-PiWebCloudToken