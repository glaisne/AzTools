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
function Test-AzVirtualNetworkUnused
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([OutputType])]
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
        $Name
    )

    begin
    {

    }
    process
    {
        try
        {
            $VN = get-azVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction Stop
        }
        catch
        {
            throw $_
        }

        $VNUnused = $True
        foreach ($SubNet in $VN.Subnets)
        {
            if (($SubNet.IpConfigurations | measure | % count) -gt 0)
            {
                $VNUnused = $False
                break
            }
        }

        $VNUnused
    }
    end
    {
    
    }
}