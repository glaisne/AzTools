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
function Find-AzUnusedVirtualNetwork
{
    [CmdletBinding()]
    Param
    (
    )

    foreach ($VN in get-AzVirtualNetwork)
    {
        if ($VN | Test-AzVirtualNetworkUnused)
        {
            $VN
        }
    }
}