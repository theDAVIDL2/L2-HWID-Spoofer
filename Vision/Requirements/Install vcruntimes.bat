@echo off

color d

echo.
echo Installing requirements...

start /wait vcredist2015_2017_2019_2022_x86.exe /passive /norestart
start /wait vcredist2015_2017_2019_2022_x64.exe /passive /norestart
start /wait dxwebsetup.exe /q


echo.
echo Installation completed successfully
exit