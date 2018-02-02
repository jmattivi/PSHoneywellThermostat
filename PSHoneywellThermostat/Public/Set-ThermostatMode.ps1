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
	Set-ThermostatMode -zoneid 1234 -mode EmHeat

#>

function Set-ThermostatMode
{
    [CmdletBinding()]
    Param (
        [parameter(position = 1, mandatory = $true)]
        [String]$zoneid,
        [parameter(position = 2, mandatory = $true)]
        [ValidateSet('Heat', 'EmHeat', 'Cool', 'Off')]
        [String]$mode
    )

    ####Settings
    $loginurl = 'https://mytotalconnectcomfort.com/portal/'
    $devicecontrolurl = 'https://mytotalconnectcomfort.com/portal/Device/SubmitControlScreenChanges'

    $user = ""
    $pass = ""

    Switch ($mode)
    {
        'Cool'
        {
            $modeid = 3
        }
        'Heat'
        {
            $modeid = 1
        }
        'EmHeat'
        {
            $modeid = 0
        }
        'Off'
        {
            $modeid = 2
        }
    }

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

    #Setup payload
    $body = ConvertTo-JSON @{
        "DeviceID"       = $zoneid;
        "SystemSwitch"   = $modeid;
        "HeatSetpoint"   = $null;
        "CoolSetpoint"   = $null;
        "HeatNextPeriod" = $null;
        "CoolNextPeriod" = $null;
        "StatusHeat"     = $null;
        "StatusCool"     = $null;
        "FanMode"        = $null
    }

    #Create Headers
    $headers3 = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers3.Add("X-Requested-With", "XMLHttpRequest")
    $headers3.Add("Cookie", $cookiestring)
    $headers3.Add("Content-Type", "application/json; charset=UTF-8")

    #Send request to apply mode
    $setresult = Invoke-RestMethod -Uri $devicecontrolurl -Method Post -Body $body -Headers $headers3 -WebSession $websession

    if ($setresult.Success -eq 1)
    {
        Write-Output "Successfully set mode to $mode"
    }
}