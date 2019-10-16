. "$PSScriptRoot\..\aztools\public\Get-ResourceGroupNameFromId.ps1"

Describe 'Get-ResourceGroupNameFromId tests' {
    Context 'Context' {
        beforeAll {
            $GoodId = [PSCustomObject]@{
                Id = '/subscriptions/0e2b2f6e-4937-47d5-ba9b-8de7297e057c/resourceGroups/MyResourceGroupName'
            }

            $GoodResourceId = [PSCustomObject]@{
                ResourceId = '/subscriptions/0e2b2f6e-4937-47d5-ba9b-8de7297e057c/resourceGroups/MyResourceGroupName'
            }

            $BadResoruceId = [PSCustomObject]@{
                ResourceId = '/subscriptions/0e2b2f6e-4937-47d5-ba9b-8de7297e057c/ResourceGroupName/MyResourceGroupName'
            }

            $BadId = [PSCustomObject]@{
                Id = '/subscriptions/0e2b2f6e-4937-47d5-ba9b-8de7297e057c/ResourceGroupName/MyResourceGroupName'
            }
        }

        IT 'GoodId should return "MyResourceGroupName"' {
            $GoodId | Get-ResourceGroupNameFromId | should be  'MyResourceGroupName'
        }
        
        IT 'GoodId should return "MyResourceGroupName"' {
            $GoodResourceId | Get-ResourceGroupNameFromId | should be  'MyResourceGroupName'
        }

        IT 'BadId should return `$null' {
            $BadId | Get-ResourceGroupNameFromId | should be $null
        }
        
        IT 'BadResoruceId should return `$null' {
            $BadResoruceId | Get-ResourceGroupNameFromId | should be $null
        }
    }
}