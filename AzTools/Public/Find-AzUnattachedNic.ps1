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
function Find-AzUnattachedNic
{
    [CmdletBinding()]
    Param
    (
    )

    foreach ($Nic in Get-AzNetworkInterface)
    {
        if ([string]::IsNullOrEmpty($Nic.VirtualMachine.Id))
        {
            $Nic
        }
    }
}