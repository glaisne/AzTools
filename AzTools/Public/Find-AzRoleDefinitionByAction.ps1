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
function Find-AzRoleDefinitionByAction
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([OutputType])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $Action
    )

    Begin
    {
    }
    Process
    {
        Write-Warning "This cmdlet 'Find-AzRoleDefinitionByAction' should be considered BETA it may not work as expected"
        $Action = $Action.TrimEnd('*')
        $Roles = get-azRoleDefinition

        foreach ($Role in $Roles)
        {
            Write-Verbose "Searching $($Role.Name)"
            foreach ($RoleAction in $Role.Actions)
            {
                if ($RoleAction -like "*$Action*")
                {
                    Write-Verbose "Found: $RoleAction"
                    $Role
                    break
                }
            }
        }
    }
    End
    {
    }
}