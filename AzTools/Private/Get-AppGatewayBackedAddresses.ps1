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
function Get-AppGatewayBackendAddresses
{
    [CmdletBinding()]
    Param   
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0)]
        [Microsoft.Azure.Commands.Network.Models.PSApplicationGateway]
        $AppGateway
    )

    $AppGateway | % backendaddresspools | % backendAddresses | % IpAddress
}
