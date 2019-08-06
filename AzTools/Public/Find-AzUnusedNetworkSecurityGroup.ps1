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
function Find-AzUnusedNetworkSecurityGroup
{
    [CmdletBinding()]
    Param
    (
    )

    Foreach ($NSG in Get-AzNetworkSecurityGroup)
    {
        if (-Not ($NSG | Test-AzNetworkSecurityGroupInUse))
        {
            $NSG
        }
    }
}