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
function Get-AppGatewayFrontendAddresses
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

    $publicIpId = $AppGateway | % frontendIPConfigurations | % publicIpAddress | % id

    if ($publicIpId)
    {
        $Name = $publicIpId.split('/')[-1]
        $ResourceGroupName = Get-ResourceGroupNameFromId -idString $publicIpId
        $publicIP = Get-publicIPAddressPublicIP -PublicIPAddress (get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $Name)
    }

    @( $($AppGateway | % PrivateIPAddress) + $publicIP )
}
