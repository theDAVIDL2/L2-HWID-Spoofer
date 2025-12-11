@echo off
:repeat
cls
Title Serial Checker

echo [+] Disk Serial's
echo.
powershell -Command "Get-PhysicalDisk | ForEach-Object { 'Model: ' + $_.FriendlyName + ' - Serial: ' + ($_.SerialNumber -join '') }"

echo [+] CPU
echo.
powershell -Command "Get-CimInstance Win32_Processor | ForEach-Object { 'Name: ' + $_.Name + ' - ID: ' + $_.ProcessorId + ' - Part Number: ' + $_.PartNumber }"

echo [+] BaseBoard
echo.
powershell -Command "Get-CimInstance Win32_BaseBoard | ForEach-Object { 'Manufacturer: ' + $_.Manufacturer + ' - Serial: ' + $_.SerialNumber }"

echo [+] BIOS
echo.
powershell -Command "Get-CimInstance Win32_BIOS | ForEach-Object { 'Manufacturer: ' + $_.Manufacturer + ' - Serial: ' + $_.SerialNumber }"

echo [+] smBIOS
echo.
powershell -Command "Get-CimInstance Win32_ComputerSystemProduct | ForEach-Object { 'Name: ' + $_.Name + ' - UUID: ' + $_.UUID }"

echo [+] MAC
echo.
powershell -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { 'Name: ' + $_.Name + ' - MAC: ' + $_.MacAddress }"

echo.
echo Press any key to recheck
pause >nul
goto repeat
