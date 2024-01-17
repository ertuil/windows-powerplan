$current_power_plan = $(powercfg.exe /getactivescheme) |% {$_.split(" ")[2]};

$user_power_plan_uuid = "305a6627-c8b9-4c90-bfe1-4a42aeeb0288"
$system_balanced_uuid = "381b4222-f694-41f0-9685-ff5bb260df2e"


if ($current_power_plan -eq $user_power_plan_uuid)
{
    powercfg.exe /setactive $system_balanced_uuid
    Write-Output "Change into Balanced Mode";
    # Set-ScreenRefreshRate -frequency 60
}
else
{
    powercfg.exe /setactive $user_power_plan_uuid
    # Set-ScreenRefreshRate -frequency 144
    Write-Output "Into Long Lifetime Mode"; # get into Long Life-time Mode
}