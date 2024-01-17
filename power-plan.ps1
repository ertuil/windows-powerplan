function Set-ScreenRefreshRate
{ 
    param ( 
        [Parameter(Mandatory=$true)] 
        [int] $Frequency
    ) 

    $pinvokeCode = @"         
        using System; 
        using System.Runtime.InteropServices; 

        namespace Display 
        { 
            [StructLayout(LayoutKind.Sequential)] 
            public struct DEVMODE1 
            { 
                [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
                public string dmDeviceName; 
                public short dmSpecVersion; 
                public short dmDriverVersion; 
                public short dmSize; 
                public short dmDriverExtra; 
                public int dmFields; 

                public short dmOrientation; 
                public short dmPaperSize; 
                public short dmPaperLength; 
                public short dmPaperWidth; 

                public short dmScale; 
                public short dmCopies; 
                public short dmDefaultSource; 
                public short dmPrintQuality; 
                public short dmColor; 
                public short dmDuplex; 
                public short dmYResolution; 
                public short dmTTOption; 
                public short dmCollate; 
                [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] 
                public string dmFormName; 
                public short dmLogPixels; 
                public short dmBitsPerPel; 
                public int dmPelsWidth; 
                public int dmPelsHeight; 

                public int dmDisplayFlags; 
                public int dmDisplayFrequency; 

                public int dmICMMethod; 
                public int dmICMIntent; 
                public int dmMediaType; 
                public int dmDitherType; 
                public int dmReserved1; 
                public int dmReserved2; 

                public int dmPanningWidth; 
                public int dmPanningHeight; 
            }; 

            class User_32 
            { 
                [DllImport("user32.dll")] 
                public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE1 devMode); 
                [DllImport("user32.dll")] 
                public static extern int ChangeDisplaySettings(ref DEVMODE1 devMode, int flags); 

                public const int ENUM_CURRENT_SETTINGS = -1; 
                public const int CDS_UPDATEREGISTRY = 0x01; 
                public const int CDS_TEST = 0x02; 
                public const int DISP_CHANGE_SUCCESSFUL = 0; 
                public const int DISP_CHANGE_RESTART = 1; 
                public const int DISP_CHANGE_FAILED = -1; 
            } 

            public class PrimaryScreen  
            { 
                static public string ChangeRefreshRate(int frequency) 
                { 
                    DEVMODE1 dm = GetDevMode1(); 

                    if (0 != User_32.EnumDisplaySettings(null, User_32.ENUM_CURRENT_SETTINGS, ref dm)) 
                    { 
                        dm.dmDisplayFrequency = frequency;

                        int iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_TEST); 

                        if (iRet == User_32.DISP_CHANGE_FAILED) 
                        { 
                            return "Unable to process your request. Sorry for this inconvenience."; 
                        } 
                        else 
                        { 
                            iRet = User_32.ChangeDisplaySettings(ref dm, User_32.CDS_UPDATEREGISTRY); 
                            switch (iRet) 
                            { 
                                case User_32.DISP_CHANGE_SUCCESSFUL: 
                                { 
                                    return "Success"; 
                                } 
                                case User_32.DISP_CHANGE_RESTART: 
                                { 
                                    return "You need to reboot for the change to happen.\n If you feel any problems after rebooting your machine\nThen try to change resolution in Safe Mode."; 
                                } 
                                default: 
                                { 
                                    return "Failed to change the resolution"; 
                                } 
                            } 
                        } 
                    } 
                    else 
                    { 
                        return "Failed to change the resolution."; 
                    } 
                } 

                private static DEVMODE1 GetDevMode1() 
                { 
                    DEVMODE1 dm = new DEVMODE1(); 
                    dm.dmDeviceName = new String(new char[32]); 
                    dm.dmFormName = new String(new char[32]); 
                    dm.dmSize = (short)Marshal.SizeOf(dm); 
                    return dm; 
                } 
            } 
        } 
"@ # don't indend this line

    Add-Type $pinvokeCode -ErrorAction SilentlyContinue

    [Display.PrimaryScreen]::ChangeRefreshRate($frequency) 
}

function Get-ScreenRefreshRate
{
    $frequency = Get-WmiObject -Class "Win32_VideoController" | Select-Object -ExpandProperty "CurrentRefreshRate"

    return $frequency
}

function Get-BatteryStatus
{

    $battery_status = Get-CimInstance -ClassName Win32_Battery | Select-Object -Property DeviceID, BatteryStatus

    if ($battery_status.BatteryStatus -eq 2 -or $battery_status.BatteryStatus -eq 3)
    {
        $battery_status = "Charging"
    }
    else
    {
        $battery_status = "Battery"
    }
    return $battery_status
}

$current_battery_status =  Get-BatteryStatus;

if ($current_battery_status -eq "Charging")
{
  Write-Output 'Computer in charge';
  Write-Output 'Change monitor to 90Hz';
  Set-ScreenRefreshRate -Frequency 90;
  Write-Output 'Change brightness to 95%';
  (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1,95)
}
else
{
  # return runtime in hours:
  Write-Output 'Computer using battery';
  Write-Output 'Change monitor to 60Hz';
  Set-ScreenRefreshRate -Frequency 60;
  Write-Output 'Change brightness to 60%';
  (Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1,60)
}

# Read-Host -Prompt "Please enter a key to exit"