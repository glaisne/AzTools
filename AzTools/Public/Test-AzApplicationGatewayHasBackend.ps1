<#
.Synopsis
Short description
.DESCRIPTION
Long description
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet
#>
function Test-AzApplicationGatewayHasBackend
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $Name,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]
        $ResourceGroupName
    )
    
    try
    {
        $AppGateway = get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $Name
    }
    catch
    {
        throw $_
    }

    if ($AppGateway)
    {
        if (Get-AppGatewayBackendAddresses -AppGateway $AppGateway)
        {
            $True
        }
        else
        {
            $False
        }
    }
    else
    {
        Write-Error "No Application Gateway could be found."
    }
}