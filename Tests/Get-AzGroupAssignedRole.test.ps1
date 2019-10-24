. "$PSScriptRoot\..\aztools\public\Get-AzGroupAssignedRole.ps1"

Describe 'Get-AzGroupAssignedRole tests' {
    mock -CommandName get-azSubscription -MockWith { return [pscustomobject]@{
            id             = '11111111-1111-1111-1111-111111111111'
            name           = 'AzureSubscriptionName'
            State          = 'enabled'
            SubscriptionId = '11111111-1111-1111-1111-111111111111'
        }
    }

    mock -CommandName Get-azAdGroup -MockWith { return [pscustomobject]@{
            Id          = '11111111-1111-1111-1111-111111111111'
            displayname = 'Azure-SubName-Evn (role)'
            ObjectType  = 'Group'
        }
    }
        
    mock -CommandName Select-azSubscription -mockWith { }
    
    mock -commandName Test-azCurrentSubscription -MockWith { return $true }

    Context 'Successful subscription access.' {
        IT 'get all subscriptions doesn''t throw' {
            { Get-AzGroupAssignedrole -AllSubscriptions -Groupname 'Azure-SubName-Evn (role)' } | should not throw
            Assert-MockCalled  get-azSubscription 1
        }

        IT 'get a specific subscription doesn''t throw' {
            { Get-AzGroupAssignedrole -SubscriptionName 'AzureSubscriptionName' -Groupname 'Azure-SubName-Evn (role)' } | should not throw
            Assert-MockCalled  get-azSubscription 1
        }
        
        IT 'get subscription id doesn''t throw' {
            { Get-AzGroupAssignedrole -SubscriptionId '11111111-1111-1111-1111-111111111111' -Groupname 'Azure-SubName-Evn (role)' } | should not throw
            Assert-MockCalled  get-azSubscription 1
        }

        IT 'No subscription parameter is provided, should not throw' {
            { Get-AzGroupAssignedrole -Groupname 'Azure-SubName-Evn (role)' } | should not throw
        }
    }
    
    context 'Failed subscription access' {
        mock -CommandName get-azSubscription -MockWith { throw 'error' }
        
        IT 'get all subscriptions doesn''t throw' {
            { Get-AzGroupAssignedrole -AllSubscriptions -Groupname 'Azure-SubName-Evn (role)' -WarningAction 'silentlycontinue' } | should not throw
            Assert-MockCalled  get-azSubscription 1

            $result = Get-AzGroupAssignedrole -SubscriptionName 'AzureSubscriptionName' -Groupname 'Azure-SubName-Evn (role)' -WarningAction 'silentlycontinue'
            $result | should benullorempty
        }

        IT 'get a specific subscrition which doesn''t exist shows a warning' {
            { Get-AzGroupAssignedrole -SubscriptionName 'AzureSubscriptionName' -Groupname 'Azure-SubName-Evn (role)' -WarningAction 'silentlycontinue' } | should not throw
            Assert-MockCalled  get-azSubscription 1

            $result = Get-AzGroupAssignedrole -SubscriptionName 'AzureSubscriptionName' -Groupname 'Azure-SubName-Evn (role)' -WarningAction 'silentlycontinue'
            $result | should benullorempty
        }
        
        IT 'get subscription id doesn''t throw' {
            { Get-AzGroupAssignedrole -SubscriptionId '11111111-1111-1111-1111-111111111111' -Groupname 'Azure-SubName-Evn (role)' -WarningAction 'silentlycontinue' } | should not throw
            Assert-MockCalled  get-azSubscription 1

            $result = Get-AzGroupAssignedrole -SubscriptionName 'AzureSubscriptionName' -Groupname 'Azure-SubName-Evn (role)' -WarningAction 'silentlycontinue'
            $result | should benullorempty
        }
        
    }
}
