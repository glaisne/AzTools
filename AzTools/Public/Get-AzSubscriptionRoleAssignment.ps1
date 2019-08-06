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
function Get-AzSubscriptionRoleAssignment
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([OutputType])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Name",
            Position = 0)]
        [string]
        $SubscriptionName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Id",
            Position = 0)]
        [string]
        $SubscriptionID,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "All",
            Position = 0)]
        [switch]
        $All,
        
        # Specify credentials for this CmdLet
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $AADCredential = [System.Management.Automation.PSCredential]::Empty

    )

    Begin
    {
        switch ($PsCmdlet.ParameterSetName)
        {
            "All" 
            {
                Write-Progress -Activity 'Gathering all Subscriptions' 
                $Subscriptions = get-AzSubscription
                break
            }
            "Name" 
            {
                $Subscriptions = foreach ($N in $SubscriptionName)
                {
                    get-AzSubscription -SubscriptionName $N
                }
                break
            }
            "Id"
            {
                $Subscriptions = foreach ($I in $SubscriptionID)
                {
                    get-AzSubscription -SubscriptionId $I
                }
                break
            }
        }

        function AssignmentResult
        {
            [PSCustomObject][Ordered] @{
                DisplayName    = [string]::Empty
                ObjectId       = [string]::Empty
                Role           = [string]::Empty
                Scope          = [string]::Empty
                AssignmentType = [string]::Empty
                GroupName      = [string]::Empty
            }
            
        }
    
    
    }
    Process
    {
        $i = 0
        foreach ($subscription in $Subscriptions)
        {
            # Get Subscription information
            $SubscriptionName = $Subscription.Name
            $SubscriptionId = $Subscription.Id

            $PrecentComplete = $([math]::round($($i / $Subscriptions.count * 100), 2))
            Write-Progress -Id 0 -Activity "Processing Subscription $SubscriptionName`..." -Status "$PrecentComplete %" -PercentComplete $PrecentComplete        
            
            # Try up to 10 times to swich to the specific subscription
            $TryCount = 0
            while (-Not $(Test-AzCurrentSubscription -Id $SubscriptionId) -or $TryCount -gt 10)
            {
                try
                {
                    $null = Select-AzSubscription -SubscriptionId $SubscriptionId -erroraction Stop
                }
                catch
                {
                    $err = $_
                    Write-Warning "Failed to select Azure RM Subscription by subscriptionName $Subscription : $($err.exception.message)"
                }
                $TryCount++
            }
        
            # Test if we are in the proper subscription context
            if ($(get-Azcontext).subscription.id -ne $SubscriptionId)
            {
                Write-warning "Failed to set the proper context : ($($(get-Azcontext).subscription.name))"
                continue
            }
            else
            {
                Write-Verbose "[$(Get-Date -format G)] Set the proper context $($(get-Azcontext).subscription.name)"
            }
        
            
            $RoleDefinitionNames = get-azroleassignment |Select RoleDefinitionName -unique | % RoleDefinitionName
        
            $PotentialOwners = [System.Collections.ArrayList]::new()

            $AllAssignments = Get-AzRoleAssignment
        
            foreach ($RoleDefinitionName in $RoleDefinitionNames)
            {
                
                $Assignees = $AllAssignments | ? {$_.roleDefinitionName -eq $RoleDefinitionName}
        
                foreach ($Assignee in $Assignees)
                {
                    switch ($assignee.ObjectType)
                    {
                        'Group'
                        {
                            # Get the members of the gorup
                            Write-Verbose "Assignee.DisplayName = $($Assignee.DisplayName)"
                            $group = Get-AzADGroup -ObjectId $Assignee.ObjectId

                            if (($Group | measure).count -gt 1)
                            {
                                Write-Error "Group DisplayName ($($Assignee.DisplayName)) is ambiguous"
                            }

                            foreach ($groupMember in $group | Get-AzADGroupmember )
                            {
                                $Assignment                = AssignmentResult
                                $Assignment.DisplayName    = $GroupMember.DisplayName
                                $Assignment.ObjectId       = $GroupMember.ObjectId
                                $Assignment.Role           = $assignee.RoleDefinitionName
                                $Assignment.Scope          = $Assignee.Scope
                                $Assignment.AssignmentType = $assignee.ObjectType
                                $Assignment.GroupName      = $group.DisplayName

                                
                                $Assignment
                            }
                        }
                        'User'
                        {
                            $user = Get-AzAdUser -DisplayName $Assignee.DisplayName
        
                            $Assignment                = AssignmentResult
                            $Assignment.DisplayName    = $Assignee.DisplayName
                            $Assignment.ObjectId       = $Assignee.ObjectId
                            $Assignment.Role           = $assignee.RoleDefinitionName
                            $Assignment.AssignmentType = 'Direct'

                            $Assignment
                        }
                        'ServicePrincipal'
                        {
                            $user = Get-AzADServicePrincipal -DisplayName $Assignee.DisplayName
        
                            $Assignment                = AssignmentResult
                            $Assignment.DisplayName    = $Assignee.DisplayName
                            $Assignment.ObjectId       = $Assignee.ObjectId
                            $Assignment.Role           = $assignee.RoleDefinitionName
                            $Assignment.AssignmentType = 'Direct'

                            $Assignment
                        }
                        default
                        {
                            Write-Warning "Attempting to handle '$($assignee.ObjectType)' assignment for ($($Assignee.DisplayName))`."

                            $Assignee | fl * -force | out-string -stream | % { Write-Warning $_ }
        
                            $Assignment = AssignmentResult
                            $Assignment.Role = $assignee.RoleDefinitionName
                            $Assignment.AssignmentType = 'Direct'

                            if ([string]::IsNullOrEmpty($Assignee.DisplayName))
                            {
                                $Assignment.DisplayName = $Assignee.ObjectId
                            }
                            else
                            {
                                $Assignment.DisplayName = $Assignee.DisplayName
                            }

                            $Assignment
                        }
                    }
                }
            }
            $i++
        }
    }
    End
    {
    }
}