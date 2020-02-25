<#
.SYNOPSIS
    This function takes in an array or object and outputs it as a menu
    and then returns the selection as the result

.DESCRIPTION
    This function takes in an array or object and outputs it as a menu
    and then returns the selection as the result

.NOTES
    Author: LegoBenny aka Forrest (https://github.com/legoBenny)

.EXAMPLE
    gci "C:\scripts\VirtScripts\includes" | Get-MenuSelection
    Get-MenuSelection -MenuItems $(get-datacenter 123456-DC | get-cluster)
    Get-MenuSelection -MenuItems $(get-process | select -expandProperty ProcessName)
    Get-MenuSelection -MenuItems @("Apple","Bananna","Cherry") -MenuTitle "My Wonderful Fruit Menu" -MenuMessage "Please enter the number of the fruit you want"

.EXAMPLE
    get-vm | Get-MenuSelection

    Please select from the following options:
    0. vm-web.abcdef.com
    1. vm-db.abcdef.com
    2. vm-web2.abcdef.com
    3. vmapp2.abcdef.com
    4. vmdb1.abcdef.com
    5. vmdb2.abcdef.com
    6. s2fqaapp.abcdef.com

    Selection Number: 4

    Name                 PowerState Num CPUs MemoryGB
    ----                 ---------- -------- --------
    vmdb1.abcdef.com     PoweredOff 4        16.000
#>
function Get-MenuSelection {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][object[]]$MenuItems,
        [Parameter()][string]$MenuTitle = "Please select from the following options",
        [Parameter()][string]$MenuMessage = "Selection Number"
    )
    begin{
        $items = @()
        Write-Host "`r`n$($menuTitle):"
    }
    process{
        $items += $MenuItems # get the items from the pipe and put them in an array
        foreach ($item in $MenuItems) {
            write-host "  $($items.indexof($item)+1). $item"
        }
    }
    end{
        try{$selectNum = [int](read-host "`r`n$MenuMessage")}
        catch{
            Write-Host "Invalid Selection: Selection must be an integer." -fore red;
            Get-MenuSelection -MenuItems $items -MenuTitle $menuTitle -MenuMessage $MenuMessage
            break
        }

        if (!($selectNum -ge 1 -and $selectNum -le ($items.count))) {
            write-host "Invalid Selection: Selection must be between 1 and $($items.count)." -fore red
            Get-MenuSelection -MenuItems $items -MenuTitle $menuTitle -MenuMessage $MenuMessage
            break
        }else{
            $result = $items[$($selectNum - 1)]
            return $result
        }
    }
}
