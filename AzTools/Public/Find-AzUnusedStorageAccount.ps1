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
function Find-AzUnusedStorageAccount
{
    [CmdletBinding()]
    Param
    (
    )

    Begin
    {
    }
    Process
    {
        foreach ($Sa in get-azStorageAccount)
        {
            if ($sa | Test-AzStorageAccountEmpty)
            {
                $sa
            }
        }
    }
    End
    {
    }
}