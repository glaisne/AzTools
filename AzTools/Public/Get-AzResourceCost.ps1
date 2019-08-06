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
