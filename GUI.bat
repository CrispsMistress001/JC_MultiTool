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


for /f "tokens=1-3 delims= " %%a in ("%HTAreply%") do (
    if "%%a"=="1" (
        call :run_backup "%%b" "%%c"
    ) else if "%%a"=="2" (
        call :function_b "%%b" "%%c"
    ) else if "%%a"=="3" (
        call :function_c "%%b" "%%c"
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

echo Running backup for %customerName% from source drive letter %sourceDrive%...

set "destinationRoot=D:\Backup"
set backupDate=%date:~0,2%_%date:~3,2%_%date:~6,4%
set destinationPath=%destinationRoot%\%customerName% %backupDate%
if not exist "%destinationPath%" (
    @REM powershell -Command "New-Item -ItemType Directory -Path '%destinationPath%'"
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
@REM set "options=/e /DCOPY:DAT /R:10 /W:0 /NP /TEE"

@REM echo %options%
@REM echo %sourcePath% "%destinationPath%" %options%

robocopy %sourcePath% "%destinationPath%" %options%
goto :eof


:function_b
echo Function B was called
goto :eof

:function_c
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
    // container.innerHTML = `
    //     <label for="source-drive">Source Drive letter:</label>
    //     <input type="text" id="source-drive" name="source-drive"><br><br>
    //     <label for="customer-name">Customer name:</label>
    //     <input type="text" id="customer-name" name="customer-name"><br><br>
    //     <button onclick="backup();">Back up</button>
    // `;
    document.getElementById('backup_func').style.display="block";
}

function backup(){
    var sourceDrive = document.getElementById("source-drive").value;
    var customerName = document.getElementById("customer-name").value;
    // TODO: Add backup logic here
    closeHTA("1 " + sourceDrive +" "+ customerName);
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
        font-size:30px;
    }
    #backup_func{
        display: none;
    }
</STYLE>
</HEAD>
<BODY>
    <div id="container">
        <button onclick="showBackupInputs();">Run Back up</button>
        <button onclick="closeHTA(2);">Windows Optimization</button>
        <button onclick="closeHTA(3);">System Corruption Scan</button>

    </div>
    <div id="backup_func">
        <label for="source-drive">Source Drive letter:</label>
        <input type="text" id="source-drive" name="source-drive"><br><br>
        <label for="customer-name">Customer name:</label>
        <input type="text" id="customer-name" name="customer-name"><br><br>
        <button onclick="backup();">Back up</button>
    </div>
</BODY>
</HTML>