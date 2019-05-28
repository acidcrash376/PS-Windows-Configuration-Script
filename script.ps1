##########
# Win 10 / Server 2012 Configuration Script
# Author: Acidcrash <nope@acidcrash.co.uk>
# Version: v1.3, 2019-05-28
# Source: https://github.com/acidcrash376/PS-Windows-Configuration-Script
##########

### Require Admin
Function RequireAdmin {
	If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
		Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -Verb RunAs
		Exit
	}
}

### Configure The NIC Interactive
Function Set-IPConfig {
	$interface = Read-Host -prompt "Please Enter the interface you want to configure..."
    $intindex = Get-NetAdapter | Where Name -Contains $interface | Select-Object -ExpandProperty InterfaceIndex
    if(Get-NetAdapter | Where Name -Contains $interface) #| Select-Object -ExpandProperty InterfaceIndex)
    {
    $ipaddr = Read-Host -Prompt "What IP address do you want to use..."
    $prefix = Read-Host -Prompt "Ommitting the slash ( / ) what slash notation subnet do you want to use..."
    $defgw = Read-Host -Prompt "What is the IP of the gateway..."
    $dnsserver = Read-Host -Prompt "What is the IP of the DNS Server you want to use..."
    Write-Host "`n`nIP Address: $ipaddr/$prefix Gateway: $defgw DNS: $dnsserver`n"

    $confirmation = Read-Host "                                  `nAre these details correct? [y]es [n]o [c]ancel"
        if ($confirmation -eq 'y')
        {
        Write-Host "Proceeding..."
        Set-NetIPInterface -InterfaceIndex $intindex -Dhcp Enabled
        Remove-NetRoute -InterfaceIndex $intindex -DestinationPrefix 0.0.0.0/0 -Confirm:$false
        New-NetIPAddress -InterfaceIndex $intindex -AddressFamily IPv4 -IPAddress $ipaddr -PrefixLength $prefix -DefaultGateway $defgw
        Set-DnsClientServerAddress -InterfaceIndex $intindex -ServerAddresses $dnsserver
        }
        elseif ($confirmation -ne 'y') 
        {
            if ($confirmation -eq 'n')
            {
            Write-Host "Please run again..."
            Start-Sleep -s 2
            Set-IPConfig
            }
            elseif ($confirmation -eq 'c')
            {
            Write-Host "Exiting..."
            Exit
            }
        }
    }
    else
    {
    Write-Host "No interface with that name..."
    Start-Sleep -s 2
    Set-IPConfig
    }

}
### Configure the NIC use this to call within the script
function Set-IPConfig_Complete {
    Set-IPConfig
    Write-Host "Configuration of Network complete"
}

### Set the Hostname
Function Set-HostName {
	Write-Output "Setting the Host Name..."
#	$hostname = Get-WmiObject Win32_ComputerSystem
    $hostname = hostname
    $name = Read-Host -Prompt "Please Enter the ComputerName you want to use."
#    $hostname.Rename($name)
    Rename-Computer $name
    Write-Host "New hostname is $name"
}

### Enable RDP
Function Enable-RDP {
	Write-Output "Enabling RDP..."
	Set-ItemProperty ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\‘ -Name “fDenyTSConnections” -Value 0
    Set-ItemProperty ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\‘ -Name “UserAuthentication” -Value 1
    Enable-NetFirewallRule -DisplayGroup “Remote Desktop”
}

### Set-Lang
Function Set-Lang {
	Write-Output "Setting the Language..."
    Set-WinUILanguageOverride -Language en-GB
    $LangList = Get-WinUserLanguageList
    $MarkedLang = $LangList | where LanguageTag -eq "en-US"
    $LangList.Remove($MarkedLang)
    Set-WinUserLanguageList $LangList -Force
    Write-Host "***Language is now en-GB and en-US has been removed"
}

### Enable Firewall ICMP Rule
Function Enable-Firewall_ICMP {
    Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In-NoScope"
    Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-Out-NoScope"
    Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In_1"
    Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-Out_1"
}

### Wait for key press
Function WaitForKey {
	Write-Output "`nPress any key to continue..."
	[Console]::ReadKey($true) | Out-Null
}

### Restart computer
Function Restart {
	Write-Output "Restarting..."
	Restart-Computer
}

RequireAdmin
Set-HostName
Set-IPConfig_Complete
Enable-RDP
Set-Lang
Enable-Firewall_ICMP

WaitForKey
