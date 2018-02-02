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
	Set-ThermostatStatus -location LivingRoom -mode Heat

.EXAMPLE
	Set-ThermostatStatus -location RecRoom -mode EmHeat

#>

$gmailcreds = 

Write-Output (Get-Date).ToLocalTime()

$temps = Get-OutsideTemperature
$currenttemp = ($temps | ? {$_.TempDescription -eq "Current"}).TempValue
$realfeeltemp = ($temps | ? {$_.TempDescription -eq "RealFeel"}).TempValue
Write-Output "RealFeel Temperature:  $realfeeltemp F"

$zones = Get-ThermostatZones
foreach ($zone in $zones)
{
    if ($currenttemp -ge 35) #Set to Heat mode
    {
        if (((Get-ThermostatStatus -zoneid $zone.zoneid).'System Mode') -eq 0)
        {
            try
            {
                Set-ThermostatMode -zoneid $zone.zoneid -mode Heat -ErrorAction Stop
            
                $mail_body = "The mode has been updated due to temperature change.  Current temperature is $currenttemp.  RealFeel temperature is $realfeeltemp"
                Send-MailMessage -SmtpServer smtp.gmail.com -Port 587 -Credential $Gmailcreds `
                    -UseSsl -From "azure.automation.service@gmail.com" -To "email@gmail.com" `
                    -Subject "Thermostat Mode Changed to Heat" -body $mail_body
            }
            catch
            {
                $mail_body = "Failed to set the mode to Heat.  Current temperature is $currenttemp.  RealFeel temperature is $realfeeltemp"
                Send-MailMessage -SmtpServer smtp.gmail.com -Port 587 -Credential $Gmailcreds `
                    -UseSsl -From "azure.automation.service@gmail.com" -To "email@gmail.com" `
                    -Subject "Thermostat Failed To Set Mode To Heat" -body $mail_body
                throw "Error setting thermostat to Heat"
            }
        }
        else
        {
            Write-Output "System mode is already set to Heat"
        }
    }
    elseif ($currenttemp -lt 35) #Set to EmHeat mode
    {
        if (((Get-ThermostatStatus -zoneid $zone.zoneid).'System Mode') -eq 1)
        {
            try
            {
                Set-ThermostatMode -zoneid $zone.zoneid -mode EmHeat -ErrorAction Stop

                $mail_body = "The mode has been updated due to temperature change.  Current temperature is $currenttemp.  RealFeel temperature is $realfeeltemp"
                Send-MailMessage -SmtpServer smtp.gmail.com -Port 587 -Credential $Gmailcreds `
                    -UseSsl -From "azure.automation.service@gmail.com" -To "email@gmail.com" `
                    -Subject "Thermostat Mode Changed to EmHeat" -body $mail_body
            }
            catch
            {
                $mail_body = "Failed to set the mode to EmHeat.  Current temperature is $currenttemp.  RealFeel temperature is $realfeeltemp"
                Send-MailMessage -SmtpServer smtp.gmail.com -Port 587 -Credential $Gmailcreds `
                    -UseSsl -From "azure.automation.service@gmail.com" -To "email@gmail.com" `
                    -Subject "Thermostat Failed To Set Mode To EmHeat" -body $mail_body
                throw "Error setting thermostat to EmHeat"
            }
        }
        else
        {
            Write-Output "System mode is already set to EmHeat"
        }
    
    }
}