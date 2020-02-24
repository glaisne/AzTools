<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.NOTES
    General notes
#>
function Get-AzRbacRole
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [Alias()]
    [OutputType([PSCustomObject])]
    Param (
        # Param1 help description
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Role")] 
        $RoleName,
        
        # Param2 help description
        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All,
        
        # Param3 help description
        [Parameter(ParameterSetName = 'SubscriptionName')]
        [String[]]
        $SubscriptionName,
        
        # Param3 help description
        [Parameter(ParameterSetName = 'SubscriptionId')]
        [String[]]
        $SubscriptionId,

        [parameter(Mandatory = $False)]
        [ValidateSet("Assignments", "UsersOnly", "AssignmentsWithGroupMembers")]
        [string]
        $ResultOptions = 'AssignmentsWithGroupMembers'
    )
    
    begin
    {
        function NewReturnObject
        {
            [PSCustomObject][Ordered]@{
                SubscriptionId    = [string]::Empty
                SubscriptionName  = [string]::Empty
                Role              = [string]::Empty
                Type              = [string]::Empty
                UserPrincipalName = [string]::Empty
                DisplayName       = [string]::Empty
                Id                = [string]::Empty
                MemberOf          = [string]::Empty
            }
            
        }
    }
    
    process
    {
        Write-Verbose "[$(Get-Date -format G)] Getting Subscriptions"
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $SubscriptionPool = Get-azSubscription
                break
            }
            'SubscriptionName'
            {
                $SubscriptionPool = [System.Collections.ArrayList]::new()
                foreach ($SubName in $SubscriptionName)
                {
                    try
                    {
                        $Sub = Get-azSubscription -SubscriptionName $SubName -ErrorAction Stop
                        $null = $SubscriptionPool.Add($Sub)
                    }
                    catch
                    {
                        $err = $_
                        Write-Warning "Failed to access Subscription ($SubName) : $($err.exception.Message)"
                    }
                }
                $SubscriptionPool = $SubscriptionPool.ToArray()
                break
            }
            'SubscriptionId'
            {
                $SubscriptionPool = [System.Collections.ArrayList]::new()
                foreach ($SubId in $SubscriptionId)
                {
                    try
                    {
                        $Sub = Get-azSubscription -SubscriptionId $SubId -ErrorAction Stop
                        $null = $SubscriptionPool.Add($Sub)
                    }
                    catch
                    {
                        $err = $_
                        Write-Warning "Failed to access Subscription ($SubId) : $($err.exception.Message)"
                    }
                }
                $SubscriptionPool = $SubscriptionPool.ToArray()
                break
            }
            Default { Throw 'could not find parameter name set.' }
        }

        foreach ($Subscription in $SubscriptionPool)
        {
            #
            #    Connect to the subscriptoin
            #


            Write-Verbose "[$(Get-Date -format G)] Subscription: $($Subscription.Name)"
            # Get Subscription information
            [string] $SubscriptionName = $Subscription.Name
            [string] $SubscriptionId = $Subscription.Id

            # Try up to 10 times to swich to the specific subscription
            $TryCount = 0
            while (-Not $(Test-azCurrentSubscription -Id $SubscriptionId) -or $TryCount -gt 10)
            {
                try
                {
                    Write-Verbose "[$(Get-Date -format G)] Selecting Azure Subscription $SubscriptionName"
                    $null = Select-azSubscription -SubscriptionId $SubscriptionId -erroraction Stop
                }
                catch
                {
                    $err = $_
                    Write-Warning "Failed to select Azure RM Subscription by subscriptionName $SubscriptionName : $($err.exception.message)"
                }
                $TryCount++
                start-sleep -Seconds 10
            }

            # Test if we are in the proper subscription context
            if ($(get-azcontext).subscription.id -ne $SubscriptionId)
            {
                Write-warning "Failed to set the proper context : ($($(get-azcontext).subscription.name))"
                continue
            }
            else
            {
                Write-Verbose "[$(Get-Date -format G)] Set the proper context $($(get-azcontext).subscription.name)"
            }


            #
            #    Get RBAC users
            #

            Write-Verbose "[$(Get-Date -format G)] Getting RBAC permissions for the role $RoleName under subscription $SubscriptionName"
            $Assignments = $null
            try
            {
                $Param1 = @{
                    RoleDefinitionName = $RoleName
                }
                $Assignments = Get-azRoleAssignment @Param1 -ErrorAction 'Stop'
            }
            catch
            {
                $err = $_
                Write-Warning "Failed to get Role Assignment ($RoleName) in subscription $($SubscriptionName) : $($Err.exection.Message)"
            }

            foreach ($Assignment in $Assignments)
            {
                switch ($Assignment.ObjectType)
                {
                    'group'
                    {
                        if ($ResultOptions -match "(^Assignments$|^AssignmentsWithGroupMembers%)")
                        {
                            $Group = Get-azAdGroup -ObjectId $Assignment.ObjectId 

                            $Return = NewReturnObject
                            $Return.SubscriptionName = $SubscriptionName
                            $Return.SubscriptionId   = $SubscriptionId
                            $Return.Role              = $Assignment.RoleDefinitionName
                            $Return.Type             = $Assignment.ObjectType
                            $Return.DisplayName      = $Group.DisplayName
                            $Return.Id               = $Group.Id
                            $Return
                        }

                        if ($ResultOptions -match "(^UsersOnly$|^AssignmentsWithGroupMembers%)")
                        {
                            # Get the members of the group
                            foreach ($User in Get-azADGroupMember -GroupObjectId $Assignment.ObjectId | sort displayName)
                            {
                                $Return = NewReturnObject
                                $Return.SubscriptionId    = $SubscriptionId
                                $Return.SubscriptionName  = $SubscriptionName
                                $Return.Role              = $Assignment.RoleDefinitionName
                                $Return.Type              = 'User'
                                $Return.UserPrincipalName = $User.userPrincipalName
                                $Return.DisplayName       = $User.DisplayName
                                $Return.Id                = $User.Id
                                $Return.memberOf          = $Assignment.DisplayName
                                $Return
                            }
                        }
                    }
                    'User'
                    {
                        $User = Get-AzADUser -ObjectId $Assignment.ObjectId | select Type, UserPrincipalName, DisplayName, Id
                        
                        $Return = NewReturnObject
                        $Return.SubscriptionId    = $SubscriptionId
                        $Return.SubscriptionName  = $SubscriptionName
                        $Return.Role              = $Assignment.RoleDefinitionName
                        $Return.Type              = $Assignment.ObjectType
                        $Return.UserPrincipalName = $User.userPrincipalName
                        $Return.DisplayName       = $User.DisplayName
                        $Return.Id                = $User.Id
                        $Return
                    }
                    'ServicePrincipal'
                    {
                        $ServicePrincipalName = Get-AzADServicePrincipal -ObjectId $Assignment.ObjectId
                        
                        $Return = NewReturnObject
                        $Return.SubscriptionId    = $SubscriptionId
                        $Return.SubscriptionName  = $SubscriptionName
                        $Return.Role              = $Assignment.RoleDefinitionName
                        $Return.Type              = $Assignment.ObjectType
                        $Return.UserPrincipalName = $ServicePrincipalName.userPrincipalName
                        $Return.DisplayName       = $ServicePrincipalName.DisplayName
                        $Return.Id                = $ServicePrincipalName.Id
                        $Return.memberOf          = $Assignment.DisplayName
                        $Return
                    }
                    Default 
                    {
                        $Return = NewReturnObject
                        $Return.SubscriptionId    = $SubscriptionId
                        $Return.SubscriptionName  = $SubscriptionName
                        $Return.Role              = $Assignment.RoleDefinitionName
                        $Return.Type              = $Assignment.ObjectType
                        $Return.UserPrincipalName = $Assignment.SignInName
                        $Return.DisplayName       = $Assignment.DisplayName
                        $Return.Id                = $Assignment.ObjectId
                        $Return
                    }
                }
            }
        }
    }
    
    end
    {
    }
}
