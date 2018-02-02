function Get-OutsideTemperature
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2017-12-04

    .SYNOPSIS
        Integrates with the Accuweather API to query the current temperature.
        
    .DESCRIPTION
        API key is hardcoded in the parameter
        Default location is set for Danville,PA

    .PARAMETER apikey

    .PARAMETER location
    	    
    .EXAMPLE
    	Get-OutsideTemperature

    #>
    [CmdletBinding()]
    Param (
        [parameter(position = 1, mandatory = $false)]    
        [String]$apikey = "",
        [parameter(position = 2, mandatory = $false)]
        [ValidateSet('Danville,PA')]
        [String]$location = 'Danville,PA'
    )

    SWITCH ($location)
    {
        'Danville,PA'
        {
            $locationid = "335323"
        }
    }

    $arrtemp = @()

    $url = "http://dataservice.accuweather.com/currentconditions/v1/$locationid`?apikey=$apikey&details=True"
    $tempresult = Invoke-RestMethod -Uri $url -Method Get
    
    $currenttemp = $tempresult.Temperature.Imperial.Value
    $objzone = new-object psobject
    $objzone | Add-Member -MemberType NoteProperty -Name 'TempDescription' -Value "Current"
    $objzone | Add-Member -MemberType NoteProperty -Name 'TempValue' -Value $currenttemp
    $arrtemp += $objzone

    $realfeel = $tempresult.RealFeelTemperature.Imperial.Value
    $objzone = new-object psobject
    $objzone | Add-Member -MemberType NoteProperty -Name 'TempDescription' -Value "RealFeel"
    $objzone | Add-Member -MemberType NoteProperty -Name 'TempValue' -Value $realfeel
    $arrtemp += $objzone

    Write-Output $arrtemp
}