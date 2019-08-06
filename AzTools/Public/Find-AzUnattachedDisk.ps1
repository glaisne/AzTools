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
function Find-AzUnattachedDisk
{
    [CmdletBinding()]
    Param
    (
    )

    foreach ($disk in get-AzDisk)
    {
        if ([string]::IsNullOrEmpty($disk.ManagedBy))
        {
            $Disk
        }
    }
}