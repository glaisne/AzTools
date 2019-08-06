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
function Test-AzNetworkSecurityGroupInUse
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([boolean])]
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
            Position = 0)]
        [string]
        $Name
    )

    Begin
    {
    }
    Process
    {
        try
        {
            $NSG = get-azNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $Name
        }
        catch
        {
            throw $_
        }

        if ($NSG.subnets.id -eq $null -and $NSG.networkinterfaces.id -eq $null)
        {
            return $False
        }
        Else
        {
            return $true
        }
    }
    
    End
    {
    }
}