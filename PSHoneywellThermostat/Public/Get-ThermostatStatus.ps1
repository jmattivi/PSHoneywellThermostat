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
	Get-ThermostatStatus -zoneid 1234

#>

function Get-ThermostatStatus
{
    [CmdletBinding()]
    Param ([parameter(position = 1, mandatory = $true)]
        [String]$zoneid)

    ####Settings
    $loginurl = 'https://mytotalconnectcomfort.com/portal/'
    $devicestatusurl = 'https://mytotalconnectcomfort.com/portal/Device/CheckDataSession/'

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

    #Send request for status

    $statusresult = Invoke-RestMethod -Uri $($devicestatusurl + $zoneid) -Method Get -Headers $headers2 -WebSession $websession

    $objStatus = new-object psobject
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Zone Name' -Value $zone.ZoneName
    $objStatus | Add-Member -MemberType NoteProperty -Name 'System Mode' -Value $statusresult.latestData.uiData.SystemSwitchPosition
    $objStatus | Add-Member -MemberType NoteProperty -Name 'System Running' -Value $statusresult.latestData.uiData.EquipmentOutputStatus
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Indoor Temperature' -Value $statusresult.latestData.uiData.DispTemperature
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Cool Setpoint' -Value $statusresult.latestData.uiData.CoolSetpoint
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Heat Setpoint' -Value $statusresult.latestData.uiData.HeatSetpoint
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Temporary Hold Until' -Value $statusresult.latestData.uiData.TemporaryHoldUntilTime
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Permanent Hold Until' -Value $statusresult.latestData.uiData.VacationHoldUntilTime
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Status Cool' -Value $statusresult.latestData.uiData.StatusCool
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Status Heat' -Value $statusresult.latestData.uiData.StatusHeat
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Fan Mode' -Value $statusresult.latestData.fanData.fanMode
    $objStatus | Add-Member -MemberType NoteProperty -Name 'Fan Running' -Value $statusresult.latestData.fanData.fanIsRunning

    Write-Output $objStatus
}