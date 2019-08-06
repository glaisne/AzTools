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
function Find-AzUnattachedPublicIP
{
    [CmdletBinding()]
    Param
    (
    )

    # get all the nics
    $SubscriptionUsedPublicIPs = % {
        foreach ($rg in Get-AzResourceGroup)
        {
            Get-AzVirtualNetworkGateway -ResourceGroupName $rg.ResourceGroupName | % IpConfigurations | % publicIpAddress | % id
        }
        ((Get-AzNetworkInterface |? {$_.IpConfigurations.publicIpAddress -ne $null}).IpConfigurations).publicIpAddress | % id
        (Get-AzApplicationGateway | % FrontendIpConfigurationsText | convertfrom-json).PublicIPAddress.id
        (Get-AzLoadBalancer).FrontendIpConfigurations.publicipaddress.id
    }

    $SubscriptionPublicIPs = Get-AzPublicIpAddress

    foreach ($SubscriptionPublicIP in $SubscriptionPublicIPs)
    {
        if ($SubscriptionPublicIP.id -notin $SubscriptionUsedPublicIPs)
        {
            $SubscriptionPublicIP
        }
    }
}