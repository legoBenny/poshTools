function Format-TableWithBorders {
    <#
    .SYNOPSIS
        This function takes in an array or object and outputs it as a ascii table
        with borders. The columns are auto-sized similar to Format-Table -autosize.

    .DESCRIPTION
        This function takes in an array or object and outputs it as a ascii table
        with borders. The columns are auto-sized similar to Format-Table -autosize.

    .NOTES
        Author: Forrest (https://github.com/legoBenny)

    .PARAMETER -InputObject <PSObject>
            Specifies the objects to format. Enter a variable that contains the objects, or type a command or expression that gets the objects.

    .PARAMETER -Property <Object[]>
            Specifies the object properties that appear in the display and the order in which they appear. Type one or more property names (separated
            by commas).

            If you omit this parameter, the properties that appear in the display depend on the object being displayed. The parameter name ( Property )
            is optional.
    .INPUTS
        System.Management.Automation.PSObject
            You can pipe any object to Format-Table .

    .OUTPUTS
        System.Object.String
            Format-TableWithBorders returns a String in table format.


    .EXAMPLE
    PS C:\> Format-TableWithBorders -inputObject $(Get-Process w*) -Property Handles, NPM, PM, CPU, Id, ProcessName

    +---------+-------+----------+-------------+--------+------------------------+
    | Handles | NPM   | PM       | CPU         | Id     | ProcessName            |
    +---------+-------+----------+-------------+--------+------------------------+
    |      96 |  8792 |  1388544 |    0.671875 |    604 | wininit                |
    |     183 |  9296 |  1912832 |       0.125 |  78408 | winlogon               |
    |     156 |  8480 |  1925120 |    0.109375 |  86512 | winlogon               |
    |     201 | 10384 |  2228224 |    0.203125 | 123864 | winlogon               |
    |      99 |  7944 |  5570560 |    3.328125 |   7988 | winpty-agent           |
    |      99 |  7536 |  1949696 |    13.28125 |  69272 | winpty-agent           |
    |      99 |  7672 |  2117632 |       3.625 | 104604 | winpty-agent           |
    |    1653 | 23768 | 30568448 | 42133.53125 |   3336 | WmiPrvSE               |
    |     142 | 11056 |  1904640 |   54.328125 |   2488 | wrapper-windows-x86-32 |
    +---------+-------+----------+-------------+--------+------------------------+

    .EXAMPLE
    PS C:\> Get-ChildItem *.log | Format-TableWithBorders -Property mode,LastWriteTime,Length,Name,VersionInfo

    +--------+------------------------+--------+----------------------------+-----------------------------------------------------+
    | Mode   | LastWriteTime          | Length | Name                       | VersionInfo                                         |
    +--------+------------------------+--------+----------------------------+-----------------------------------------------------+
    | -a---- | 10/14/2019 12:57:42 PM |    792 | -20191014-125647.log       | File: C:\-20191014-125647.log; InternalName: ;  ... |
    | -a---- |  10/14/2019 1:02:00 PM |    792 | -20191014-130156.log       | File: C:\-20191014-130156.log; InternalName: ;  ... |
    | -a---- | 10/14/2019 12:55:10 PM |   7885 | 123456-20191014-124219.log | File: C:\123456-20191014-124219.log; InternalNa ... |
    +--------+------------------------+--------+----------------------------+-----------------------------------------------------+

    .EXAMPLE
    PS C:\> Get-ChildItem *.log | ftb

    +------------------------+--------+----------------------------+
    | LastWriteTime          | Length | Name                       |
    +------------------------+--------+----------------------------+
    | 10/14/2019 12:57:42 PM |    792 | -20191014-125647.log       |
    |  10/14/2019 1:02:00 PM |    792 | -20191014-130156.log       |
    | 10/14/2019 12:55:10 PM |   7885 | 953835-20191014-124219.log |
    +------------------------+--------+----------------------------+

    #>

    [alias("ftb")]
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][object[]]$inputObject,
        [Parameter(Mandatory = $false)][object]$Property
    )
    begin {
        $tBreak  = ""
        $tHeader = ""
        $tItem   = ""
        $objPropNames = [PSCustomObject][ordered]@{}
        $outputObject = @()
    }
    process {

        # Use the Property list parameter, if it is not supplied, then use DefaultDisplayPropertySet if the object has one
        if($Property){
            $inputObject = $inputObject | Select-Object -property $Property
        }elseif($inputObject.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames){
            $defaultDisplayProperties = ($inputObject | Select-Object -first 1).PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames
            $inputObject = $inputObject | Select-Object -property $defaultDisplayProperties
        }

        # get a list of the property names
        if ($objPropNames.length -le 0) {
            $objPropNames = $inputObject[0].PSObject.Properties | Select-Object name,@{n="Longest";e={$_.name.Length}}
        }

        # find the length of the longest item for each property (including the name of the property)
        foreach($obj in $inputObject){
            foreach ($propName in $objPropNames) {
                foreach ($item in $obj."$($propName.name)") {
                    if ($item.tostring() -match "\r\n") {
                        # if its a multi-line string, then get the length of the first line
                        if($item.tostring().indexof("`r`n") + 4 -ge $propName.Longest){
                            $propName.Longest =  [int]$item.tostring().indexof("`r`n") + 4
                        }
                    }elseif ($item.tostring().Length -gt $propName.Longest) {
                        $propName.Longest = $item.tostring().Length
                    }
                }
            }
            $outputObject +=$obj
        }
    }
    end {
        # format the header and table line breaks
        foreach ($propName in $objPropNames) {
            $tBreak += "+-$('-'*$propName.longest)-"
            $tHeader += "| $($propName.name.PadRight($propName.longest,' ')) "
        }
        $tBreak += "+" # end the table line break
        $tHeader += "|`r`n" # end the header line

        # format the line for each item
        foreach ($item in $outputObject) {
            foreach ($prop in $objPropNames) {
                if ($null -eq $item."$($prop.name)"){ # null value: fill with whitespace
                    $tItem += "| $(" ".PadRight($prop.longest,' ')) "
                }elseif($item."$($prop.name)".tostring() -match "\r\n"){ # multi-line string or multi-part object: shorten and justify left
                    $shortValue = ($item."$($prop.name)".tostring().replace("`r`n","; ") -replace "\s+"," ").subString(0,$propName.longest - 4)
                    $tItem += "| $("$shortValue ...".PadRight($prop.longest,' ')) "
                }elseif($item."$($prop.name)".gettype().name -eq "String") { # string: justify left
                    $tItem += "| $($item."$($prop.name)".PadRight($prop.longest,' ')) "
                }else { # non-string: most likely a number, therefore, justify right
                    $tItem += "| $($item."$($prop.name)".tostring().PadLeft($prop.longest,' ')) "
                }
            }
            $tItem += "|`r`n" # end the line
        }

        # put it all together
        $output = "$tBreak`r`n" + $tHeader + "$tBreak`r`n" + $tItem + $tBreak
        return $output
    }
}
