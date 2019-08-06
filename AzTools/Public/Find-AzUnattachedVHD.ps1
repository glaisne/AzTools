<#
.Synopsis
Short description
.DESCRIPTION
modified from "https://docs.microsoft.com/en-us/azure/virtual-machines/windows/find-unattached-disks"
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet
#>
function Find-AzUnattachedVHD
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
    )

    $storageAccounts = Get-AzStorageAccount
    foreach ($storageAccount in $storageAccounts)
    {
        $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
        $StorageAccountSize = Get-AzStorageAccountSize -ResourceGroupName $storageAccount.ResourceGroupName -StorageAccountName $storageAccount.StorageAccountName
        $StorageAccountCost = $StorageAccount | Get-AzResourceCost
        # $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
        $containers = Get-AzStorageContainer -Context $storageAccount.context
        foreach ($container in $containers)
        {
            $blobs = Get-AzStorageBlob -Container $container.Name -Context $storageAccount.context
            #Fetch all the Page blobs with extension .vhd as only Page blobs can be attached as disk to Azure VMs
            $blobs | Where-Object {$_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd')} | ForEach-Object { 
                #If a Page blob is not attached as disk then LeaseStatus will be unlocked
                if ($_.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked')
                {
                    $VHDPercentOfWhole = [math]::round(($_.Length / $StorageAccountSize),2)
                    [PSCustomObject][ordered] @{
                        ResourceGroupName          = $storageAccount.ResourceGroupName
                        StorageAccountName         = $storageAccount.StorageAccountName
                        StorageAccountCost         = $StorageAccountCost 
                        ContainerName              = $Container.Name
                        Name                       = $_.Name
                        Length                     = $_.Length
                        URI                        = $_.ICloudBlob.Uri.AbsoluteUri
                        PresentageOfStorageAccount = $VHDPercentOfWhole
                        '30DayCost'                = $StorageAccountCost * $VHDPercentOfWhole
                    }
                }
            }
        }
    }
}