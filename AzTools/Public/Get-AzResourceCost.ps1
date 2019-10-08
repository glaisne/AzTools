<#
.Synopsis
Gets the cost of the resource over the course of the last number of days specified by the Days parameter
.DESCRIPTION
This script the the total cost of a given resource over the last specified number of days. The default
number of days is 30.
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet
#>
function get-AzResourceCost
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $Id,

        [Parameter(Mandatory = $false,
            Position = 1)]
        [int]
        $Days = 30
    )

    Begin
    {
    }

    process
    {
        $StartDate = [datetime]::now.AddDays((-1 * $Days)).ToShortDateString()
        $EndDate = [datetime]::now.ToShortDateString()
        $double = Get-AzConsumptionUsageDetail -StartDate $StartDate -EndDate $EndDate -InstanceId $Id | % PretaxCost | measure -sum | % sum
        
        [math]::Round($double, 2)
    }
    
    End
    {
    }

}
