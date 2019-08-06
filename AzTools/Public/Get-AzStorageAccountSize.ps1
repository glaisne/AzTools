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
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        $context = $storageAccount.Context
        
        $listOfBLobs = foreach ($Container in get-azStorageContainer -Context $context)
        {
            Get-AzStorageBlob -Container $Container.Name -Context $context 
        }

        # zero out our total
        $length = 0

        # this loops through the list of blobs and retrieves the length for each blob
        #   and adds it to the total
        $listOfBlobs | ForEach-Object {$length = $length + $_.Length}

        $length
    }
    End
    {
    }
}
