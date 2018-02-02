<#
.NOTES
	AUTHOR: 	Jon Mattivi
	COMPANY: 
	CREATED DATE: 2017-12-04

.SYNOPSIS
	Integrates with the Honeywell Total Connect Comfort site to check and configure thermostat settings

.PARAMETER mode
	    System Modes
        EmHeat: 0
        Heat:   1
        Off:    2
        Cool:   3
.EXAMPLE
	Get-ThermostatZones

#>

function Get-ThermostatZones
{
    [CmdletBinding()]
    Param ()

    ####Settings
    $loginurl = 'https://mytotalconnectcomfort.com/portal/'
    $locationurl = 'https://mytotalconnectcomfort.com/portal/Locations'

    $user = ""
    $pass = ""

    #Login
    #Create headers
    $headers1 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers1.Add("Content-Type", "application/x-www-form-urlencoded")

    #Login payload
    $body = @{
        "UserName"   = "$user";
        "Password"   = "$pass";
        "timeOffset" = "300"
    }

    $loginresult = Invoke-WebRequest -Uri $loginurl -Method Post -Body $body -SessionVariable websession -MaximumRedirection 0 -ErrorAction SilentlyContinue

    if (!($loginresult.StatusCode -eq "302"))
    {
        throw "Error logging in to the Honeywell portal!"
    }

    #Save auth cookies
    $cookiestring = $null
    $cookies = $websession.Cookies.GetCookies($loginurl)

    foreach ($cookie in $cookies)
    {
        if ($cookie.Value -ne "")
        {
            $cookiestring += "$($cookie.name)=$($cookie.value); "
        }
        else
        {
            $cookiestring += "$($cookie.name)=; "
        }
    }
    $cookiestring = $cookiestring.TrimEnd("; ")

    #Create headers
    $headers2 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers2.Add("X-Requested-With", "XMLHttpRequest")
    $headers2.Add("Cookie", $cookiestring)

    #Send request for location information
    $locationresult = Invoke-WebRequest -Uri $locationurl -Method Get -Headers $headers2 -WebSession $websession
    $locationid = $locationresult.AllElements.'data-id' | ? {$_.Length -gt 0}

    #Send request for zone information
    $zonesurl = "https://mytotalconnectcomfort.com/portal/$locationid/Zones"
    $zonesresult = Invoke-WebRequest -Uri $zonesurl -Method Get -Headers $headers2 -WebSession $websession

    $regexzonename = [regex] '(?<=(location-name">))(\w|\d|\n|[\/]| )+?(?=(<\/div))'
    $regexzoneid = [regex] '(?<=(data-id="))(\w|\d|\n|[\/]| )+?(?=(">))'

    $parsedzonetables = $zonesresult.AllElements | ? {$_.tagname -eq "table"}
    $zonenames = $parsedzonetables.innerHTML | Select-String -Pattern ($regexzonename.ToString()) -AllMatches | % {$_.Matches} | % {$_.Value}
    $zoneids = $parsedzonetables.innerHTML | Select-String -Pattern ($regexzoneid.ToString()) -AllMatches | % {$_.Matches} | % {$_.Value}

    $arrzones = @()
    $i = 0
    do
    {
        $objzone = new-object psobject
        $objzone | Add-Member -MemberType NoteProperty -Name 'ZoneID' -Value $zoneids[$i]
        $objzone | Add-Member -MemberType NoteProperty -Name 'ZoneName' -Value $zonenames[$i]
        $arrzones += $objzone
        $i++
    } until ($i -eq $zonenames.Length)

    Write-Output $arrzones
}