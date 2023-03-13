@echo off

echo Running backup script with administrator privileges...
echo.
:: Check if script is running with administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Script is running with administrative privileges
) else (
    echo Requesting administrative privileges...
    powershell Start-Process "%0" -Verb runAs
    exit
)

:run_backup
set /p sourceDrive=Enter the source drive letter (e.g. D):
set /p customerName=Enter the customer name:

set destinationRoot=D:\Backup
set backupDate=%date:~10,4%_%date:~4,2%_%date:~7,2%
set destinationPath=%destinationRoot%\%customerName%

if not exist "%destinationPath%" (
    mkdir "%destinationPath%"
)

set sourcePath=%sourceDrive%:\Users
set log=%destinationPath%\Backup.log
set options=/E /ZB /COPY:DAT /DCOPY:T /MT:8 /R:3 /W:10 /LOG:%log% /NP /TEE

robocopy "%sourcePath%" "%destinationPath%" %options%


pause