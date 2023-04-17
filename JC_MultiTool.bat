<!-- :: Batch section
@echo off

echo Running backup script with administrator privileges...
:: Check if script is running with administrative privileges
net session >nul 2>&1

if %errorLevel% == 0 (
    echo Script is running with administrative privileges
) else (
    echo Requesting administrative privileges...
    powershell Start-Process -FilePath powershell.exe -Verb runAs -ArgumentList '-Command', 'Start-Process "%~dpnx0" -Verb runAs'
    exit
)
:main

cls


echo Select an option:
for /F "delims=" %%a in ('mshta.exe "%~F0"') do set "HTAreply=%%a"
echo End of HTA window, reply: "%HTAreply%"
@REM pause


for /f "tokens=1-4 delims= " %%a in ("%HTAreply%") do (
    if "%%a"=="1" (
        call :run_backup %%b %%c %%d
    ) else if "%%a"=="2" (
        call :Optimization
    ) else if "%%a"=="3" (
        call :Corruption_Scan %%b
    ) else (
        goto :loop_end
    )
)
:loop_end

pause
goto :eof


:run_backup

set "sourceDrive=%~1"
set "customerName=%~2"
set "Destination=%~3"


echo Running backup for %customerName% from source drive letter %sourceDrive% onto %Destination% drive...

set "destinationRoot=%Destination%:\Backup"
set backupDate=%date:~0,2%_%date:~3,2%_%date:~6,4%
set destinationPath=%destinationRoot%\%customerName% %backupDate%
if not exist "%destinationPath%" (
    mkdir "%destinationPath%"
)

@REM @echo on

start "" "%destinationPath%"
:: unfortunately have to open file explorer due to windows bug or some sort which does not actually make a file
:: for use until you open it up in explorer orrrr the robocopy does not see it

timeout /t 1 >nul


set sourcePath="%sourceDrive%:\Users"
set log="%destinationPath%\Backup.log"

if not exist "%destinationPath%\Backup.log" (
  echo File doesn't exist. Creating file...
  echo This is a new file. > "%destinationPath%\Backup.log"
  echo File created.
) else (
  echo File already exists.
)

set "options=/E /ZB /COPY:DAT /DCOPY:T /MT:8 /R:3 /W:10 /LOG:%log% /NP /TEE"

robocopy %sourcePath% "%destinationPath%" %options%
goto :eof

:: BELOW IS FOR SYSTEM OPTIMIZATION
:Optimization
echo Disabling Fast Startup
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f
powercfg /hibernate off
echo Done!

echo Setting services to manual

setlocal enabledelayedexpansion

set services=vmictimesync vmicrdv vmicvmsession vmicheartbeat vmicshutdown vmicguestinterface vmickvpexchange HvHost HpTouchpointAnalyticsService HPSysInfoCap HPNetworkCap HPDiagsCap HPAppHelperCap QWAVE RtkBtManServ WpnService cbdhsvc_48486de CaptureService_48486de BcastDVRUserService_48486de PerfHost SEMgrSvc edgeupdatem MicrosoftEdgeElevationService edgeupdate iphlpsvc BthAvctpSvc Browser BthAvctpSvc EntAppSvc SCardSvr ALG RetailDemo FontCache wisvc lmhosts SysMain seclogon WPDBusEnum PcaSvc PrintNotify PhoneSvc WpcMonSvc MSDTC AJRouter stisvc gupdatem gupdate fhsvc Fax WerSvc ndu XboxGipSvc XboxNetApiSvc XblGameSave XblAuthManager WSearch WMPNetworkSvc TrkWks SharedAccess RemoteRegistry RemoteAccess NetTcpPortSharing MapsBroker lfsvc dmwappushservice DPS DiagTrack diagnosticshub.standardcollector.service

for %%i in (%services%) do (
  sc query "%%i" >nul 2>&1 && (
    sc config "%%i" start= demand
    @REM echo Service "%%i" set to manual.
  ) || (
    echo Service "%%i" not found.
  )
)

echo All services set to manual.

reg add "HKLM\Software\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f
reg add "HKLM\Software\Policies\Microsoft\Windows\GameBar" /v "AllowGameBar" /t REG_DWORD /d "0" /f
reg add "HKLM\System\CurrentControlSet\Services\XboxLiveAuthManager" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\System\CurrentControlSet\Services\XboxNetApiSvc" /v "Start" /t REG_DWORD /d "4" /f

echo Disabled Xbox live and Game Bar 

:: OH GOD THE LONG PEROFRMANCE BOOST XDDDD CAN BE ALSO GOOD FOR GAMING MACHINES

echo enabling auto-complete in Run Dialog 
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "Append Completion" /t REG_SZ /d "yes" /f
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoComplete" /v "AutoSuggest" /t REG_SZ /d "yes" /f
echo reducing dump file size
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d 3 /f

echo Disabling Remote Assistance
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d 0 /f
echo Disabling shaking to minimize
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d 1 /f

REG DELETE "HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" /f
REG DELETE "HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" /f

echo Changing duration of crashed/non-responding programs take to close and more
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
REG ADD "HKEY_CURRENT_USER\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_SZ /d "1000" /f
REG ADD "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "0" /f

echo Disabling link tracking
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "LinkResolveIgnoreLinkInfo" /t REG_DWORD /d 1 /f
echo Disabling automatic network folder searching
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d 1 /f
echo Disabling tracking of shortcuts and their targets
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d 1 /f

REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f

sc stop "dmwappushservice"

sc config "RemoteRegistry" start= disabled

REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DiagTrack"

echo Disabling wifi Sense
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotspotReporting" /v value /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v value /t REG_DWORD /d 0 /f

echo:
echo Optimizations completed!

:: END OF THAT MATTINGGGGG

goto :eof

:Corruption_Scan

set "drive=%~1"

if "%drive%" == "" (
    echo No drive letter provided.
    goto end
)

echo Starting Corruption Scan

if /i "%drive%" == "C" (
    echo Running checkdisk on %drive%...
    chkdsk %drive%: /scan
    if %errorlevel% neq 0 (
        echo Error running checkdisk on %drive%.
        goto end
    )
    echo Running SFC on %drive%...
    sfc /scannow
    echo Running DISM on %drive%...
    dism /online /cleanup-image /restorehealth
    echo Running SFC again on %drive%...
    sfc /scannow
) else (
    echo Running checkdisk on %drive% externally...
    cmd /c "chkdsk %drive%: /f /r"
    if %errorlevel% neq 0 (
        echo Error running checkdisk on %drive%.
        goto end
    )
    echo Running SFC on %drive% externally...
    cmd /c "sfc /scannow /offbootdir=%drive%:\ /offwindir=%drive%:\Windows"
    echo Running DISM on %drive% externally...
    cmd /c "dism /image:%drive%:\ /cleanup-image /restorehealth"
    echo Running SFC again on %drive% externally...
    cmd /c "sfc /scannow /offbootdir=%drive%:\ /offwindir=%drive%:\Windows"
)

:end
echo finished.
pause
goto :eof


:function_d
echo Function C was called
goto :eof
-->


<HTML>
    <HEAD>
        <HTA:APPLICATION>
    
        <TITLE>HTA Buttons</TITLE>
        <SCRIPT language="JavaScript">
        window.resizeTo(500,350);
    
        function closeHTA(reply){
            var fso = new ActiveXObject("Scripting.FileSystemObject");
            fso.GetStandardStream(1).WriteLine(reply);
            window.close();
        }
    
        function showBackupInputs(){
            var container = document.getElementById("container");
            container.style.display="none";
            document.getElementById('backup_func').style.display="block";
        }
    
        function backup(){
            var sourceDrive = document.getElementById("source_drive").options[source_drive.selectedIndex].value;
            var destinationDrive = document.getElementById("destination_drive").options[destination_drive.selectedIndex].value;
            var customerName = document.getElementById("customer-name").value;
            // TODO: Add backup logic here
            closeHTA("1 " + sourceDrive +" "+ customerName + " " + destinationDrive);
        }
    
        function Corruption(){
            var sourceDrive2 = document.getElementById("source_drive2").options[source_drive2.selectedIndex].value;
            // TODO: Add backup logic here
            //console.log(sourceDrive2);
            closeHTA("3 " + sourceDrive2);
        }
    
        function showCorruptionInputs(){
            var container = document.getElementById("container");
            container.style.display="none";
            document.getElementById('corruption_id').style.display="block";

        }
        </SCRIPT>
        <STYLE>
            body{
                margin: 0;
                left: 0;
            }
            #container{
    
                display: inline-block;
                border: 1px solid #ccc;
                padding: 10px;
                margin: 10px;
                vertical-align: top;
                width: 100%;
                text-align:center;
            }
            button{
                margin:5px;
                width:30%;
                height:70px;
                overflow:visible;
                font-size:2vw;
            }
            #backup_func{
                display: none;
                text-align: center;
                border: 1px solid #ccc;
    
            }
            select {
                font-size: 130%;
            }
            label{
                font-size: 130%;
                vertical-align: middle;
                height:20%;
    
            }
            input{
                font-size: 130%;
                height:20%;
    
            }
    
        </STYLE>
    </HEAD>
    <BODY>
        <div id="container">
            <button onclick="showBackupInputs();">Run Back up</button>
            <button onclick="closeHTA(2);">Windows Optimization</button>
            <button onclick="showCorruptionInputs();">System Corruption Scan</button>
            <button onclick="closeHTA(4);">Install Apps</button>
            <button onclick="closeHTA(5);">Setup Desktop</button>
            
        </div>
        <div id="backup_func">
            <label for="source_drive">Source Drive letter:</label>
            <select id="source_drive">
                <option value="C">C:</option>
                <option value="D">D:</option>
                <option value="E">E:</option>
                <option value="F">F:</option>
                <option value="G">G:</option>
                <option value="H">H:</option>
                <option value="I">I:</option>
                <option value="J">J:</option>
                <option value="K">K:</option>
                <option value="L">L:</option>
                <option value="M">M:</option>
                <option value="N">N:</option>
                <option value="O">O:</option>
                <option value="P">P:</option>
                <option value="Q">Q:</option>
                <option value="R">R:</option>
                <option value="S">S:</option>
                <option value="T">T:</option>
                <option value="U">U:</option>
                <option value="V">V:</option>
                <option value="W">W:</option>
                <option value="X">X:</option>
                <option value="Y">Y:</option>
                <option value="Z">Z:</option>
            </select> <br>
            <label for="destination_drive">Destination Drive:</label>
            <select id="destination_drive">
                <option value="C">C:</option>
                <option value="D">D:</option>
                <option value="E">E:</option>
                <option value="F">F:</option>
                <option value="G">G:</option>
                <option value="H">H:</option>
                <option value="I">I:</option>
                <option value="J">J:</option>
                <option value="K">K:</option>
                <option value="L">L:</option>
                <option value="M">M:</option>
                <option value="N">N:</option>
                <option value="O">O:</option>
                <option value="P">P:</option>
                <option value="Q">Q:</option>
                <option value="R">R:</option>
                <option value="S">S:</option>
                <option value="T">T:</option>
                <option value="U">U:</option>
                <option value="V">V:</option>
                <option value="W">W:</option>
                <option value="X">X:</option>
                <option value="Y">Y:</option>
                <option value="Z">Z:</option>
            </select><br>
            <label for="customer-name">Customer name:</label>
            <input type="text" id="customer-name" name="customer-name"><br><br>
            <button onclick="backup();">Back up</button>
        </div>

        <div id="corruption_id" style="display:none;">
            <label for="source_drive2">Drive letter:</label>
            <select id="source_drive2">
                <option value="C">C:</option>
                <option value="D">D:</option>
                <option value="E">E:</option>
                <option value="F">F:</option>
                <option value="G">G:</option>
                <option value="H">H:</option>
                <option value="I">I:</option>
                <option value="J">J:</option>
                <option value="K">K:</option>
                <option value="L">L:</option>
                <option value="M">M:</option>
                <option value="N">N:</option>
                <option value="O">O:</option>
                <option value="P">P:</option>
                <option value="Q">Q:</option>
                <option value="R">R:</option>
                <option value="S">S:</option>
                <option value="T">T:</option>
                <option value="U">U:</option>
                <option value="V">V:</option>
                <option value="W">W:</option>
                <option value="X">X:</option>
                <option value="Y">Y:</option>
                <option value="Z">Z:</option>
            </select> <br>
            <button onclick="Corruption();">Run Corruption Check</button>
        </div>

    </BODY>
    </HTML>