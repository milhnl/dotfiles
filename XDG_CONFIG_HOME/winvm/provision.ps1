#!/usr/bin/env pwsh

#Install chocolatey
function Sync-Path {
    $env:PATH = "$((Get-ItemProperty -Path `
        'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' `
        -Name 'PATH').Path);$((Get-ItemProperty -Path 'HKCU:\Environment' `
        -Name 'PATH').Path)"
}

if ((Get-Command "choco.exe" -ErrorAction SilentlyContinue) -eq $null) {
    iex ((New-Object System.Net.WebClient).DownloadString(`
        'https://chocolatey.org/install.ps1'))
    Sync-Path
}

#Install packages
choco install -y --no-progress git dotnetcore-sdk nodejs
Sync-Path

#Set hostname
if (!($env:ComputerName -eq "$env:HOSTNAME")) {
    Rename-Computer -NewName "$env:HOSTNAME"
}

#Enable RDP
Set-Itemproperty `
    -Path 'HKLM:/System/CurrentControlSet/Control/Terminal Server' `
    -Name 'fDenyTSConnections' -Type 'DWord' -Value 0 -Force
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
(Get-WmiObject -class Win32_TSGeneralSetting `
    -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'" `
    ).SetUserAuthenticationRequired(0)

#Enable SSH
Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0"
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd
New-NetFirewallRule -DisplayName 'SSH Inbound' `
    -Profile @('Domain', 'Private', 'Public') -Direction Inbound `
    -Action Allow -Protocol TCP -LocalPort @('22')
New-Item -ItemType Directory -Force -Path .ssh
"$env:PUBKEY" | Out-File -Encoding utf8 -Append `
    $env:ProgramData/ssh/administrators_authorized_keys
icacls $env:ProgramData\ssh\administrators_authorized_keys `
    /inheritance:r /grant "SYSTEM:(F)" /grant "BUILTIN\Administrators:(F)"

#Enable and provision WSL
$reboot = (Enable-WindowsOptionalFeature -NoRestart -Online `
    -FeatureName Microsoft-Windows-Subsystem-Linux).RestartNeeded
if ($reboot) {
    echo "Reboot & Provision again to continue WSL installation"
} else {
    echo "Installing wsl"
    #Download and install Alpine
    if (!(Test-Path "$ENV:APPDATA/Alpine/Alpine.exe")) {
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
        (new-object System.Net.WebClient).DownloadFile(
            'https://github.com/yuk7/AlpineWSL/releases/download/3.15.0-0/' +
            'Alpine.zip', "$HOME/Downloads/Alpine.zip")
        Expand-Archive "$HOME/Downloads/Alpine.zip" "$ENV:APPDATA/Alpine"
        $sc = (New-Object -ComObject ("WScript.Shell")).CreateShortcut(
            "$ENV:USERPROFILE/Desktop/Alpine.lnk")
        $sc.TargetPath = "$ENV:APPDATA/Alpine/Alpine.exe"
        $sc.IconLocation = "$ENV:APPDATA/Alpine/Alpine.exe, 0"
        $sc.Save()
    }

    "`nexit`n" | & "$ENV:APPDATA/Alpine/Alpine.exe"
    wsl.exe -u root -- sh -euxc "
        printf '[automount]\nenabled=true\noptions=metadata\n' >/etc/wsl.conf
        cd && umount /mnt/c && mount -t drvfs C: /mnt/c -o metadata ||:
        apk add git
        echo >/root/.profile
        >>/root/.profile printf '%s\n' \
            '[ -d /home/mil/.local/dot/.git ] \\' \
            '    || git clone https://milhnl@github.com/milhnl/dotfiles \\' \
            '        /home/mil/.local/dot' \
            '/home/mil/.local/dot/PREFIX/src/roles/init' \
            'chown -R mil:wheel /home/mil/.local' \
            'sudo -u mil /home/mil/.local/dot/PREFIX/src/roles/home' \
            'printf \\[user\\]\\\\ndefault=mil\\\\n >>/etc/wsl.conf' \
            'echo exec su mil >/root/.profile' \
            'exec su mil'
    "

    Register-ScheduledTask -Force -TaskName "WSL SSHD" `
        -Action (New-ScheduledTaskAction -Execute "wsl.exe" `
            -Argument ('-- sh -c ' + `
                '"mkdir -p /run/sshd; /usr/sbin/sshd -p 23"')) `
        -Trigger (New-ScheduledTaskTrigger -AtStartup) `
        -Principal (New-ScheduledTaskPrincipal -UserId (whoami) `
            -LogonType S4U -RunLevel Highest) `
        -Settings (& {
            $tmp = New-ScheduledTaskSettingsSet `
                -AllowStartIfOnBatteries `
                -DontStopIfGoingOnBatteries `
                -StartWhenAvailable
            $tmp.CimInstanceProperties.Item("MultipleInstances").Value = 3
            $tmp
        })

    #This allows interacting with the active Windows GUI session
    "wsl.exe -- sh -c ""pkill /usr/sbin/sshd; /usr/sbin/sshd -p 23""" `
        | Out-File $([Environment]::GetFolderPath("Startup") `
            + "\WSL SSHD.bat") -Encoding ascii

    netsh interface portproxy add v4tov6 listenport=24 connectaddress=[::1] `
        connectport=23
    New-NetFirewallRule -DisplayName 'WSL SSH Inbound' `
        -Profile @('Domain', 'Private', 'Public') -Direction Inbound `
        -Action Allow -Protocol TCP -LocalPort @('24')
}
