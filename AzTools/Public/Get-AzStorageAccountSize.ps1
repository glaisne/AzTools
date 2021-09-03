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
function Get-AzStorageAccountSize
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $ResourceGroupName,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]
        $StorageAccountName
    )

    Begin
    {
    }
    Process
    {
        # Build the ID of the storage account
        $Context = Get-AzContext

        $BaseId = '/subscriptions/{0}/resourceGroups/{1}/providers/{2}/storageAccounts/{3}'
        $id = $BaseId -f $context.subscription.id, $ResourceGroupName, 'Microsoft.Storage', $StorageAccountName

        Write-Verbose "Checking if Storage Account with Id $Id exists."

        try
        {
            $storageAccount = Get-AzResource -ODataQuery "`$Filter=ResourceId eq '$id'" -ErrorAction Stop
        }
        catch
        {
            $err = $_
            Write-Warning "Unable to find Storage Account ($ResourceGroupName/$StorageAccountName) as ARM resource."
        }

        if (-not $storageAccount)
        {
            Write-Verbose "Trying to find storage account ($ResourceGroupName/$StorageAccountName) as Classic resource."

            $id = $id.Replace("/providers/Microsoft.Storage/storageAccounts/", "/providers/Microsoft.ClassicStorage/storageAccounts/")

            Write-Verbose "Checking if Storage Account with Id $Id exists."
            
            try
            {
                $storageAccount = Get-AzResource -ODataQuery "`$Filter=ResourceId eq '$id'" -ErrorAction Stop
            }
            catch
            {
                $err = $_
                Write-Warning "Unable to find Storage Account ($ResourceGroupName/$StorageAccountName) as Classic resource."
            }

            if ($storageAccount)
            {
                Write-Warning "Storage Account ($ResourceGroupName/$StorageAccountName) is a Classic resoruce. Storage Account size only accounts for Blobs in this case."
            }
        }

        if (-not $storageAccount)
        {
            throw "Unable to access Storage account in resource group '$ResourceGroupName' with name '$StorageAccountName'"
        }

        $Size = get-azmetric -resourceId $id -MetricName 'UsedCapacity' | % data  | % Average

        if ([string]::IsNullOrEmpty($Size))
        {
            0
        }
        else
        {
            $Size
        }
    }
    End
    {
    }
}
