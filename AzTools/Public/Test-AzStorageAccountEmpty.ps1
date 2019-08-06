<#
.Synopsis
Tests if an Azure Storage Account is empty
.DESCRIPTION
Check each type of storage available (blob, table, queue, File) to see if there is anything there.

.NOTES
ToDo: Need to deal with connection issues
Example error:
--------------------------------------------------------------------------------------------------
Get-AzStorageShare : A connection attempt failed because the connected party did not properly respond after a period of time, or established connection failed because connected host has failed to respond.
At C:\Program Files\PowerShell\Modules\AzTools\Public\Test-AzStorageAccountEmpty.ps1:70 char:20
+         if (($sa | Get-AzStorageShare))
+                    ~~~~~~~~~~~~~~~~~~
+ CategoryInfo          : CloseError: (:) [Get-AzStorageShare], StorageException
+ FullyQualifiedErrorId : StorageException,Microsoft.WindowsAzure.Commands.Storage.File.Cmdlet.GetAzureStorageShare
--------------------------------------------------------------------------------------------------
#>
function Test-AzStorageAccountEmpty
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
        try
        {
            $sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        }
        catch
        {
            throw $_
        }

        # If there is a blob, then the Storage Account is not empty
        if (($sa | Get-AzStorageContainer))
        {
            # Make sure at least one container has a blob
            foreach ($saContainer in $sa | Get-AzStorageContainer)
            {
                if ($saContainer | get-azstorageblob)
                {
                    return $false
                }
            }
        }     

        # If there is a table, then the Storage Account is not empty
        if (($sa | Get-AzStorageTable))
        {
            return $False
        }

        # If there is a queue, then the Storage Account is not empty
        if (($sa | Get-AzStorageQueue))
        {
            return $False
        }

        # If there is a file share, then the Storage Account is not empty
        if (($sa | Get-AzStorageShare))
        {
            return $False
        }
        
        $True
    }
    End
    {
    }
}
