function Get-OutsideTemperature
{
    <#
    .NOTES
    	AUTHOR: 	Jon Mattivi
    	COMPANY: 
    	CREATED DATE: 2017-12-04

    .SYNOPSIS
        Integrates with the weather.gov API to query the current temperature.
        
    .DESCRIPTION
        API for weather.gov uses latitude and longitude hardcoded for Danville, PA

    .EXAMPLE
    	Get-OutsideTemperature

    #>
    [CmdletBinding()]
    Param (
    )

    #$url = "https://api.weather.gov/points/40.96342,-76.6127329"
    $url = "https://api.weather.gov/gridpoints/CTP/111,70/forecast/hourly"
    $result = Invoke-RestMethod -Method Get -Uri $url

    $currenttemp = ($result.properties.periods | Select -First 1).temperature

    return $currenttemp
}
