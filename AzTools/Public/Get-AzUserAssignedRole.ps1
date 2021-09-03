#Requires -Version 6

<#
.SYNOPSIS
    finds a users Assignment Role in an Azure Subscription (at the subscription level).
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.NOTES
    History:
    Version     Who             When            What
    1.0         Gene Laisne     05/25/2018      - Initial version made
    1.1         Gene Laisne     10/25/2018      - Added the skipping of groups (by Id) which have already been checked
                                                - Better progress bar informition for groups.


    # ToDo: Make it so $Username can take an array of usernames from the pipeline.
    # ToDo: Add a progress bar for each assignment within a role.

#>
function Get-AzUserAssignedRole
{
    [CmdletBinding(DefaultParameterSetName = 'AllSubscriptions')]
    [Alias()]
    [OutputType([PSCustomObject])]
    Param (
        # The username field can be the Azure AD ObjectId, DisplayName of a search string for the DisplayName field or the user principal name.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("User", "Samaccountname", "ObjectId")] 
        [string]
        $Username,
        
        # Use this switch to search all accessable subscriptions.
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = 'AllSubscriptions')]
        [Alias("All")]
        [switch]
        $AllSubscriptions,
        
        # A single subscription name or an array of subscription names
        [Parameter(ParameterSetName = 'SubscriptionName')]
        [String[]]
        $SubscriptionName,
        
        # A single subscription id or an array of subscription names
        [Parameter(ParameterSetName = 'SubscriptionId')]
        [String[]]
        $SubscriptionId,

        [Parameter()]
        [string]
        $RoleName  
    )
    
    begin
    {
        $GuidRegex = "^[{(]?[0-9A-F]{8}[-]?([0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$"

        function CreateReturnPSObject ($RoleAssignment, $Username, $RMADUser, $SubscriptionName)
        {
            $Object = [PSCustomObject] [Ordered] @{
                UserPrincipalName  = $RMADUser.UserPrincipalName
                DisplayName        = $RMADUser.DisplayName
                Name               = $Username    
                RoleDefinitionName = $RoleAssignment.RoleDefinitionName
                Group              = $RoleAssignment.ObjectType -eq 'Group'
                User               = $RoleAssignment.ObjectType -eq 'User'
                GroupName          = $(If ($RoleAssignment.ObjectType -eq 'Group') { $RoleAssignment.DisplayName })
                RoleAssignmentId   = $RoleAssignment.RoleAssignmentId
                SubscriptionName   = [string]::empty 
                Scope              = $RoleAssignment.Scope.trim()
            }

            if ($RoleAssignment -and $RoleAssignment.Scope -and -not [string]::IsNullOrEmpty($RoleAssignment.Scope.trim()))
            {
                try
                {
                    $SubscriptionId = Get-SubscriptionIdFromId -idString $RoleAssignment.Scope.trim() -errorAction 'Stop'
                    $Object.SubscriptionName = Get-SubscriptionNameFromId -ID $SubscriptionId -errorAction 'Stop'
                }
                catch
                {
                    $Err = $_
                    Write-Warning "Failed to set SubscriptionName on return object."
                    $RoleAssignment | fl * -force | out-string -stream | ? { -not [string]::IsNullOrEmpty($_) } | % { Write-Warning "[$(Get-Date -format G)] CreateReturnPSObject: `$RoleAssignment: $_" }
                    $Object | fl * -force | out-string -stream | ? { -not [string]::IsNullOrEmpty($_) } | % { Write-Warning "[$(Get-Date -format G)] CreateReturnPSObject: `$Object: $_" }
                }
                $Object
            }
            else
            {
                Write-Warning "CreateReturnPSObject: RoleAssignment scope is invalid"
                $RoleAssignment | fl * -force | out-string -stream | ? { -not [string]::isnullOrEmpty($_) } | % { Write-Warning "    $_" }
            }
        }

        $GroupIdsUserIsNotAMemberOf = [System.Collections.ArrayList]::new()
        $GroupIdsUserIsAMemberOf = [System.Collections.ArrayList]::new()
    }
    
    process
    {
        Write-Verbose "[$(Get-Date -format G)] Getting Subscriptions"
        
        $SubscriptionPool = [System.Collections.ArrayList]::new()
        
        switch ($PSCmdlet.ParameterSetName)
        {
            'AllSubscriptions'
            {
                $SubscriptionPool.AddRange(@($(Get-azSubscription)))
                break
            }
            'SubscriptionName'
            {
                
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
                # $SubscriptionPool = $SubscriptionPool.ToArray()
                break
            }
            'SubscriptionId'
            {
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
                # $SubscriptionPool = $SubscriptionPool.ToArray()
                break
            }
            Default { Throw 'could not find parameter name set.' }
        }

        $RMADUser = $null

        # See if the username passed in is an ObjectId for a user.
        if ($username.trim() -match $GuidRegex)
        {
            # This is a GUID and so we assume it is an ObjectId
            Write-Verbose "[$(Get-Date -format G)] username passed in is a GUID."
            Write-Verbose "[$(Get-Date -format G)] Trying to identify user by ObjectId"
            try
            {
                $RMADUser = Get-azAdUser -ObjectId $Username -ErrorAction Stop
            }
            catch
            {
                $err = $_
                Write-Warning "Failed attempting to access RM AD User with GUID : $($err.exception.message)"
            }
        }

        # The provided username is not a GUID, or we failed to get the user by GUID (ObjectId)
        if ($username.trim() -notmatch $GuidRegex -or $RMADUser -eq $null)
        {
            Write-Verbose "[$(Get-Date -format G)] Trying to identify user by SearchString ($Username)"
            try
            {
                $RMADUser = Get-azAdUser -SearchString $Username -ErrorAction Stop
            }
            catch
            {
                $err = $_
                Write-Warning "Failed attempting to access RM AD User with SearchString : $($err.exception.message)"
            }
        }

        # Try UPN
        if ($RMADUser -eq $null -or ($RMADUser | measure).count -gt 1)
        {
            Write-Verbose "[$(Get-Date -format G)] Trying to identify user by UserPrincipalName ($Username)"
            try
            {
                $RMADUser = Get-azAdUser -UserPrincipalName $Username -ErrorAction Stop
            }
            catch
            {
                $err = $_
                Write-Warning "Failed attempting to access RM AD User with UserPrincipalName : $($err.exception.message)"
            }
        }

        # Try DisplayName
        if ($RMADUser -eq $null -or ($RMADUser | measure).count -gt 1)
        {
            Write-Verbose "[$(Get-Date -format G)] Trying to identify user by DisplayName ($Username)"
            try
            {
                $RMADUser = Get-azAdUser -DisplayName $Username -ErrorAction Stop
            }
            catch
            {
                $err = $_
                Write-Warning "Failed attempting to access RM AD User with DisplayName : $($err.exception.message)"
            }
        }

        # going for a deep search now!

        if ($RMADUser -eq $null -or ($RMADUser | measure).count -gt 1)
        {
            Write-Verbose "[$(Get-Date -format G)] Failed to get the user by traditional means. Doing a deep search now. Please wait."
            Write-Verbose "[$(Get-Date -format G)] Getting all users."
            $AllUsers = get-azaduser | select UserPrincipalName, MailNickname, Id

            foreach ($user in $AllUsers)
            {
                if ($user.MailNickname -eq $Username.trim() -and -not [string]::IsNullOrEmpty($user.id))
                {
                    try
                    {
                        $RMADUser = Get-azAdUser -ObjectId $user.id -ErrorAction Stop
                    }
                    catch
                    {
                        $err = $_
                        Write-Warning "Failed attempting to access RM AD User with MailNickname : $($err.exception.message)"
                    }
                }

                if ($user.UserPrincipalName -like "$($Username.trim())@*" -and $RMADUser -eq $null -and -not [string]::IsNullOrEmpty($user.id))
                {
                    try
                    {
                        $RMADUser = Get-azAdUser -ObjectId $user.id -ErrorAction Stop
                    }
                    catch
                    {
                        $err = $_
                        Write-Warning "Failed attempting to access RM AD User with UserPrincipalName (alias only) : $($err.exception.message)"
                    }
                }

                if ($RMADUser -ne $null)
                {
                    break
                }
            }
        }

        # if we still haven't found the user, write a warning
        if ($RMADUser -eq $null -or ($RMADUser | measure).count -gt 1)
        {
            Write-Warning "Failed to access user ($username) in Azure AD. Continuing, but results may be incomplete."
        }


        #
        #    Loop through each subscription looking for the user
        #
        
        
        $i = 0
        foreach ($subscription in $SubscriptionPool)
        {
            $PrecentComplete = $([math]::round($($i / $SubscriptionPool.count * 100), 2))
            Write-Progress -Id 0 -Activity "Processing user $Username in Subscription $($Subscription.Name)`..." -Status "$PrecentComplete %" -PercentComplete $PrecentComplete
        
        
            #
            #    select the subscription
            #
                   

            # Get Subscription information
            $Subscription_Name = $Subscription.Name
            $Subscription_Id = $Subscription.Id
            
            Write-Verbose "[$(Get-Date -format G)] Subscription: $Subscription_Name"
        
            # if ($SubscriptionName -in $SubscriptionExclusionList)
            # {
            #     Continue
            # }
        
            # Try up to 10 times to swich to the specific subscription
            $TryCount = 0
            while (-Not $(Test-azCurrentSubscription -Id $Subscription_Id) -or $TryCount -gt 10)
            {
                try
                {
                    Write-Verbose "[$(Get-Date -format G)] Attempting to set subscription context (Try $TryCount)"
                    $null = Select-azSubscription -SubscriptionId $Subscription_Id -erroraction Stop
                }
                catch
                {
                    $err = $_
                    Write-Warning "Failed to select Azure RM Subscription by subscriptionName $Subscription : $($err.exception.message)"
                }
                $TryCount++
            }
        
            # Test if we are in the proper subscription context
            if ($(get-azcontext).subscription.id -ne $Subscription_Id)
            {
                Write-warning "Failed to set the proper context : ($($(get-azcontext).subscription.name))"
                continue
            }
            else
            {
                Write-Verbose "[$(Get-Date -format G)] Set the proper context $($(get-azcontext).subscription.name)"
            }
        

            #
            #    get Roles with this user
            #

            
            $Properties = @('DisplayName', 'SignInName', 'RoleDefinitionName', 'Scope', 'RoleAssignmentId')

            $RoleAssignment = $null
            if ($RMADUser -ne $null -and ($RMADUser | measure).count -eq 1)
            {
                Write-Verbose "[$(Get-Date -format G)] Getting Role Assignment for user ID $($RMADUser.Id)"
                if ($PSBoundParameters.ContainsKey('RoleName'))
                {
                    $RoleAssignment = Get-azRoleAssignment -ObjectId $RMADUser.Id -RoleDefinitionName $RoleName | select $Properties
                }
                else
                {
                    $RoleAssignment = Get-azRoleAssignment -ObjectId $RMADUser.Id | select $Properties
                }
            }
            else
            {
                Write-Verbose "[$(Get-Date -format G)] Getting Role Assignment for User by DisplayName or SignInName ($Username)."
                if ($PSBoundParameters.ContainsKey('RoleName'))
                {
                    $RoleAssignment = Get-azRoleAssignment -RoleDefinitionName $RoleName -ObjectId $RMADUser.Id -RoleDefinitionName $RoleName | select $Properties
                }
                else
                {
                    $RoleAssignment = Get-azRoleAssignment | ? { $_.displayName -eq "$Username" -or $_.SignInName -like "$Username@*" } | select $Properties
                }
            }

            # Return our custom object with user and assignment information.
            if ($RoleAssignment -ne $null)
            {
                CreateReturnPSObject -RoleAssignment $RoleAssignment -Username $Username -RMADUser $RMADUser
            }

            
            #
            #    Check group memberships
            #

            Write-Verbose "[$(Get-Date -format G)] Checking group memberships..."
            if ($PSBoundParameters.ContainsKey('RoleName'))
            {
                $GroupAssignments = Get-azRoleAssignment -RoleDefinitionName $RoleName | ? { $_.ObjectType -eq 'Group' }
            }
            else
            {
                $GroupAssignments = Get-azRoleAssignment | ? { $_.ObjectType -eq 'Group' }
            }
            
            $j = 0
            Foreach ($Group in $GroupAssignments)
            {
                if ($Group.ObjectId -in $GroupIdsUserIsNotAMemberOf)
                {
                    Write-Verbose "[$(Get-Date -format G)] We already know the user is NOT a member of this group: '$($Group.DisplayName).'"
                    Continue
                }

                if ($Group.ObjectId -in $GroupIdsUserIsAMemberOf)
                {
                    Write-Verbose "[$(Get-Date -format G)] We already know the user is a member of this group: '$($Group.DisplayName).'"
                    CreateReturnPSObject -RoleAssignment $Group -Username $Username -RMADUser $RMADUser
                    Continue
                }

                $PrecentComplete = $([math]::round($($j / $(($GroupAssignments | measure).count) * 100), 2))
                Write-Progress -Id 1 -Activity "Processing Group assignment $($Group.DisplayName)`..." -Status "$PrecentComplete %" -PercentComplete $PrecentComplete

                $Role = $Group.RoleDefinitionName
                Write-Verbose "[$(Get-Date -format G)] Checking Group - Role: '$Role' - Group: '$($Group.DisplayName)'"

                $UserFoundInGroup = $False
                foreach ($GroupMember in Get-azADGroupMember -GroupObjectId $Group.ObjectId | sort displayName)
                {
                    Write-Verbose "[$(Get-Date -format G)]  - Group member: '$($GroupMember.displayName)'"
                    if ($RMADUser -ne $null -and ($RMADUser | measure).count -eq 1)
                    {
                        if ($GroupMember.id -eq $RMADUser.Id)
                        {
                            #Write-Verbose "[$(Get-Date -format G)]    - $($GroupMember.id) -eq $($RMADUser.Id)"
                            #$Group
                            CreateReturnPSObject -RoleAssignment $Group -Username $Username -RMADUser $RMADUser
                            $UserFoundInGroup = $True
                            #$null = $GroupIdsUserIsNotAMemberOf.Add($Group.ObjectId)
                            break
                        }
                        else 
                        {
                            #Write-Verbose "[$(Get-Date -format G)]    - $($GroupMember.id) -ne $($RMADUser.Id)"
                        }
                    }
                    else
                    {
                        if ($GroupMember.displayName -like "*$username*" -or `
                                $GroupMember.userPrincipalNAme -match "$Username@carbonite(|inc)\.com")
                        {
                            #$Group
                            CreateReturnPSObject -RoleAssignment $Group -Username $Username -RMADUser $RMADUser
                            $UserFoundInGroup = $True
                            break
                        }
                    }
                }

                if ($UserFoundInGroup)
                {
                    Write-Verbose "[$(Get-Date -format G)] We already know the user is NOT a member of this group: '$($Group.DisplayName).'"
                    $null = $GroupIdsUserIsAMemberOf.Add($Group.ObjectId)
                }
                else
                {
                    $null = $GroupIdsUserIsNotAMemberOf.Add($Group.ObjectId)
                }

                $j++
            }
            Write-progress -id 1 -Completed -Activity "Processing Group assignment $($Group.DisplayName)`..."

            $i++
        }
    }
    end
    {
    }
}