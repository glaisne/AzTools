<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
function Get-AzWebAppBackupInformation {
    [CmdletBinding()]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Name
    )
    
    begin {
    }
    
    process {
        Get-azWebApp -Name $Name | Get-azWebAppBackupConfiguration

        Get-azWebApp -Name $Name | Get-azWebAppBackupList | sort Finished -desc | select ResourceGroupName, Name, Slot, StorageAccountUrl, blobName, PackupStatus, BackupSizeInBytes, Created, Finished, Log, CorrelationId
    }
    
    end {
    }
}