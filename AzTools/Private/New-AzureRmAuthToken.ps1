# taken from: https://keithbabinec.com/2018/10/11/how-to-call-the-azure-rest-api-from-powershell/

function New-AzureRmAuthToken
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = 'Please provide the AAD client application ID.')]
        [System.String]
        $AadClientAppId,
        
        [Parameter(Mandatory = $true, HelpMessage = 'Please provide the AAD client application secret.')]
        [System.String]
        $AadClientAppSecret,

        [Parameter(Mandatory = $true, HelpMessage = 'Please provide the AAD tenant ID.')]
        [System.String]
        $AadTenantId
    )
    Process
    {
        # auth URIs
        $aadUri = 'https://login.microsoftonline.com/{0}/oauth2/token'
        $resource = 'https://management.core.windows.net'

        # load the web assembly and encode parameters
        $null = [Reflection.Assembly]::LoadWithPartialName('System.Web')
        $encodedClientAppSecret = [System.Web.HttpUtility]::UrlEncode($AadClientAppSecret)
        $encodedResource = [System.Web.HttpUtility]::UrlEncode($Resource)

        # construct and send the request
        $tenantAuthUri = $aadUri -f $AadTenantId
        $headers = @{
            'Content-Type' = 'application/x-www-form-urlencoded';
        }

        $bodyParams = @(
            "grant_type=client_credentials",
            "client_id=$AadClientAppId",
            "client_secret=$encodedClientAppSecret",
            "resource=$encodedResource"
        )

        $body = [System.String]::Join("&", $bodyParams)

        Invoke-RestMethod -Uri $tenantAuthUri -Method POST -Headers $headers -Body $body

    }
}
