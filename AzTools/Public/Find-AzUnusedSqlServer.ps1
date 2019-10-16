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
function Find-AzUnusedSqlServer
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
    )

    Begin
    {
    }
    Process
    {
        foreach ($sqlServer in get-azSqlServer)
        {
            if ($sqlServer | Test-AzSQLServerHasDatabase)
            {
                $sqlServer
            }
        }
    }
    End
    {
    }
}