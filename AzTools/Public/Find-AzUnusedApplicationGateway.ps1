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
function Find-AzUnusedApplicationGateway
{
    [CmdletBinding()]
    Param
    (
    )

    foreach ($AppGateway in get-AzApplicationGateway)
    {
        if (-not ($AppGateway | Test-AzApplicationGatewayHasBackend))
        {
            return $AppGateway
        }
        
        if (-not ($AppGateway | Test-AzApplicationGatewayHasFrontend))
        {
            return $AppGateway
        }
    }
}