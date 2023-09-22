@echo off
setlocal enabledelayedexpansion
echo The source APKs are downloaded from discord cdn. They originate from apkmirror.
echo The JDK in use is also downloaded from discord cdn. It originates from zulu JDK.
echo Every file's integrity can be checked using checksums.
echo If you wish to abort, close this window.
echo.
pause
pushd "%~dp0"
mkdir "%localappdata%\revanced-cli\" > nul 2> nul
del "%localappdata%\revanced-cli\input.json" > nul 2> nul
powershell -command "Invoke-WebRequest 'https://raw.githubusercontent.com/taku-nm/auto-cli/main/input.json' -OutFile '%localappdata%\revanced-cli\input.json' -Headers @{'Cache-Control'='no-cache'}"
set "inputJson=%localappdata%\revanced-cli\input.json"
mkdir "%localappdata%\revanced-cli\keystore" > nul 2> nul
mkdir "%localappdata%\revanced-cli\apk_backups" > nul 2> nul
copy /y C:\revanced-cli-keystore\*.keystore "%localappdata%\revanced-cli\keystore" > nul 2> nul
rmdir /s /q revanced-cli-output > nul 2> nul
mkdir revanced-cli-output > nul 2> nul
cd revanced-cli-output
mklink /D "backups and more" "%localappdata%\revanced-cli\" > nul 2> nul
echo.
set batVersion=1.28
for /f %%i in ('powershell -command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).batVersion"') do ( set "jsonBatVersion=%%i" )
if /i '%batVersion%' == '%jsonBatVersion%' (
	echo  [92m Script up-to-date! [0m
) else (
	echo  [93m This script is likely outdated. Check https://github.com/taku-nm/auto-cli for new releases. [0m
)
:integ_failed
if exist "%localappdata%\revanced-cli\revanced-curl\" (
    echo  [92m cURL found! [0m
) else (
    echo [93m No cURL found... Downloading... [0m
	echo.
    powershell -command "Invoke-WebRequest 'https://curl.se/windows/dl-8.2.1_11/curl-8.2.1_11-win64-mingw.zip' -OutFile '%localappdata%\revanced-cli\curl.zip'"
	powershell -command "Expand-Archive '%localappdata%\revanced-cli\curl.zip' -DestinationPath '%localappdata%\revanced-cli\'"
	mkdir "%localappdata%\revanced-cli\revanced-curl\" > nul 2> nul
	copy /y "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\bin\*.*" "%localappdata%\revanced-cli\revanced-curl\*.*"  > nul 2> nul
	rmdir /s /q "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\"  > nul 2> nul
	del "%localappdata%\revanced-cli\curl.zip"
    echo.
)
if exist "%localappdata%\revanced-cli\revanced-jdk\" (
	echo  [92m JDK found! [0m
) else (
	echo [93m No JDK found... Downloading... [0m
	echo.
	"%localappdata%\revanced-cli\revanced-curl\curl.exe" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1149793623324504084/jdk.zip" --output "%localappdata%\revanced-cli\jdk.zip"
	powershell -command "Expand-Archive '%localappdata%\revanced-cli\jdk.zip' -DestinationPath '%localappdata%\revanced-cli'"
	del "%localappdata%\revanced-cli\jdk.zip"
	echo.
)
set "CURL=%localappdata%\revanced-cli\revanced-curl\curl.exe"
set "JDK=%localappdata%\revanced-cli\revanced-jdk\bin\java.exe"
set "KEYSTORE=%localappdata%\revanced-cli\keystore"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%CURL%' | Select-Object -ExpandProperty Hash"`) DO ( SET CURL_h=%%F )
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%JDK%' | Select-Object -ExpandProperty Hash"`) DO ( SET JDK_h=%%F )
set "comb_h=%CURL_h%%JDK_h%"
set "comp_h=7B27734E0515F8937B7195ED952BBBC6309EE1EEF584DAE293751018599290D1 6BB6621B7783778184D62D1D9C2D761F361622DD993B0563441AF2364C8A720B "
if /i "%comb_h%" == "%comp_h%" (
	echo  [92m cURL and JDK integrity validated! [0m
) else (
	echo  [93m cURL and JDK integrity damaged... Something must've become corrupted during the download [0m
	echo Deleting everyting and retrying...
	rmdir /s /q "%localappdata%\revanced-cli\revanced-curl\" > nul 2> nul
	rmdir /s /q "%localappdata%\revanced-cli\revanced-jdk\" > nul 2> nul
	echo.
	goto integ_failed
)
if exist "%localappdata%\revanced-cli\revanced-tools\" (
	call :checkTool cli
	set "CLI=%localappdata%\revanced-cli\revanced-tools\!fname!" > nul 2> nul
	call :checkTool patches
	set "PATCHES=%localappdata%\revanced-cli\revanced-tools\!fname!" > nul 2> nul
	call :checkTool integrations
	set "INTEGRATIONS=%localappdata%\revanced-cli\revanced-tools\!fname!" > nul 2> nul
	if !update! == 1 echo [93m Your ReVanced Tools are out of date or damaged... Re-downloading... [0m && rmdir /s /q "%localappdata%\revanced-cli\revanced-tools\" > nul 2> nul && goto update_jump
	if !update! == 0 goto start
) else (
	echo [93m No ReVanced Tools found... Downloading... [0m
	echo.
	:update_jump
	mkdir "%localappdata%\revanced-cli\revanced-tools\" > nul 2> nul
	call :fetchToolsJson "%inputJson%" cli
	call :downloadWithFallback "%localappdata%\revanced-cli\revanced-tools\!fname!" !link! !hash!
	set "CLI=%localappdata%\revanced-cli\revanced-tools\!fname!"
	call :fetchToolsJson "%inputJson%" patches
	call :downloadWithFallback "%localappdata%\revanced-cli\revanced-tools\!fname!" !link! !hash!
	set "PATCHES=%localappdata%\revanced-cli\revanced-tools\!fname!"
	call :fetchToolsJson "%inputJson%" integrations
	call :downloadWithFallback "%localappdata%\revanced-cli\revanced-tools\!fname!" !link! !hash!
	set "INTEGRATIONS=%localappdata%\revanced-cli\revanced-tools\!fname!"
)
:start
set "k=0"
echo.
for /f "tokens=*" %%i in ('powershell -command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps.fname"') do (
	set /a "k=k+1"
	for /f "tokens=*" %%j in ('powershell -command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps[!k!].dname"') do (
        echo  [0m %%j
    )
)
echo.
echo   A. Custom
echo.
set choice=
set /p choice=Type the number or letter to fetch the corresponding app and hit enter. 
if %choice% geq 1 if %choice% leq %k% ( goto app_download )
if '%choice%'=='A' goto custom
echo "%choice%" is not valid, try again
echo.
goto start
:app_download
call :fetchAppJson "%inputJson%" %choice%
echo Downloading !fname!
call :downloadWithFallback !fname! !link! !hash!
if %choice% geq 7 if %choice% leq 9 call :redditOptions
echo Patching !fname!
call :patchApp !fname!
goto end
:download_abort
echo.
echo  [91m Some download or file integrity check failed... Is the Discord CDN down? Is your internet interrupted? [0m
echo  Other causes might include a very outdated script... Check https://github.com/taku-nm/auto-cli for new releases.
echo  If you can, report to ReVanced Support Discord. If not, they might be gone or your internet connection may be interrupted.
echo  Pressing any key will end this script.
echo.
pause
EXIT
:custom
if exist ..\revanced-cli-input\ (
	echo [93m The revanced-cli-input folder already exists at the location you're running this script in. [0m
) else (
	mkdir ..\revanced-cli-input\ > nul 2> nul
	echo [92m The folder revanced-cli-input has been created at the location you're running this script in. [0m 
)
:custom_missing
echo [93m Ensure that the ONLY files in revanced-cli-input are the app, patches and integrations that you would want to use. [0m
echo  The app [93mMUST[0m be called 'input.apk' 
echo  The patches [93mMUST[0m be called 'patches.jar'.
echo  The integrations [93mMUST[0m be called 'integrations.apk'
echo [93m Patches and integrations are optional. Not providing them will cause the script to use official ReVanced sources. [0m
echo Once you're ready, press any key to continue...
echo.
pause
echo.
if exist ..\revanced-cli-input\input.apk (
	echo [92m input.apk found! [0m
) else (
	echo [91m input.apk missing! [0m
	echo.
	goto custom_missing
)
if exist ..\revanced-cli-input\patches.jar (
	echo [92m patches.jar found! [0m
	set PATCHES=..\revanced-cli-input\patches.jar
) else (
	echo  No patches.jar found... Continuing using official ReVanced patches
)
if exist ..\revanced-cli-input\integrations.apk (
	echo [92m integrations.apk found! [0m
	set INTEGRATIONS=..\revanced-cli-input\integrations.apk
) else (
	echo  No integrations.apk found... Continuing using official ReVanced integrations
)
echo.
echo [92m All files loaded! [0m
if exist ..\revanced-cli-input\patches.jar (
	echo  You've selected a custom patch source. At the next step you will see all available patches.
	echo.
	pause
	"%JDK%" -jar "%CLI%" list-patches -dopv "%PATCHES%"
) else (
	echo  You are using official ReVanced patches. Please look up the patches names at revanced.app/patches.
)
echo.
echo  You now have the opportunity to include and exclude patches using the following syntax:
echo [92m -i "name of a patch to include" -e "name of a patch to exclude" -i "another patch to include" [0m
echo  Type your options now. Leave empty to apply default patches. Hit enter once you're done.
echo.
set /p SELECTION=
:filename
echo.
echo  Final question: What app are you patching? This will be your output file.[93m No spaces. No file extensions.[0m
echo  Giving it the same name the last time you patched, ensures that your keystore is being used and in-place updates are possible.
echo  [92m Example: PATCHED_WhatsApp [0m
echo.
set /p OUTPUT=
if '%OUTPUT%'=='' echo [91m Nu-uh! Provide a name. [0m && goto filename
echo.
"%JDK%" -jar "%CLI%" patch "..\revanced-cli-input\input.apk" -b "%PATCHES%" -m "%INTEGRATIONS%" %SELECTION% --keystore "%KEYSTORE%\%OUTPUT%.keystore" -o %OUTPUT%.apk
goto end
:end
copy /y *.keystore "%localappdata%\revanced-cli\keystore" > nul 2> nul
rmdir /s /q C:\revanced-cli-keystore\ > nul 2> nul
rmdir /s /q revanced-resource-cache\ > nul 2> nul
del .\options.json > nul 2> nul
copy /y "PATCHED_*.apk" "%localappdata%\revanced-cli\apk_backups" > nul 2> nul
ren "%localappdata%\revanced-cli\apk_backups\PATCHED_*.apk"  "PATCHED_* %time:~0,2%%time:~3,2%-%DATE:/=%.backup" > nul 2> nul
echo.
echo [92m DONE! [0m
echo [92m Transfer the PATCHED app found in the revanced-cli-output folder to your phone and open to the apk to install it [0m
echo.
if %choice% geq 1 if %choice% leq 3 ( goto microG )
if %choice% geq 4 if %choice% leq 30 ( goto end_end )
if '%choice%'=='A' goto end_end
:microG
echo [93m Keep in mind that you will need Vanced MicroG for YT and YTM.[0m
echo.
echo Would you like to download Vanced MicroG from GitHub now?
echo.
echo   1. Yes
echo   2. No
echo.
set vancedDownload=
set /p vancedDownload=Type the number to select your answer and hit enter. 
if not '%vancedDownload%'=='' set vancedDownload=%vancedDownload:~0,1%
if '%vancedDownload%'=='1' goto microG_d
if '%vancedDownload%'=='2' goto end_end
echo "%vancedDownload%" is not valid, try again
goto microG
:microG_d
"%CURL%" -L "https://github.com/TeamVanced/VancedMicroG/releases/download/v0.2.24.220220-220220001/microg.apk" --output .\vanced_microG.apk
echo.
echo [92m Vanced MicroG downloaded to the revanced-cli-output folder! [0m
:end_end
echo  If something goes wrong, screenshot the ENTIRE terminal in your support request in the ReVanced discord support channel.
echo  bat Version %batVersion%
echo.
echo  Backups, keystore and supporting files can be found in AppData\Local\revanced-cli
echo  [93m To use the backup files, rename them to .apk instead of .backup [0m
echo.
echo  Pressing any key will close this window.
echo.
pause
EXIT
::functions
:fetchToolsJson
set fname=
set link=
set hash=
for /f %%i in ('powershell -command "(Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.tools.%~2.fname, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.tools.%~2.link, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.tools.%~2.hash"') do (
     if not defined fname (
        set "fname=%%i"
    ) else if not defined link (
        set "link=%%i"
    ) else (
        set "hash=%%i"
    )
)
EXIT /B 0
:fetchAppJson
set fname=
set link=
set hash=
set patch_sel=
for /f "tokens=*" %%i in ('powershell -command "(Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.apps[%~2].fname, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.apps[%~2].link, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.apps[%~2].hash, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.apps[%~2].patches"') do (
     if not defined fname (
        set "fname=%%i"
    ) else if not defined link (
        set "link=%%i"
    ) else if not defined hash (
        set "hash=%%i"
    ) else (
        set "patch_sel=%%i"
    )
)
EXIT /B 0
:downloadWithFallback
set second_check=0
"%localappdata%\revanced-cli\revanced-curl\curl.exe" -L "%~2" --output "%~1"
:fallback_2
set ram_h=
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%~1' | Select-Object -ExpandProperty Hash"`) DO ( SET ram_h=%%F )
if /i "%ram_h%" == "%~3 " (
	echo  [92m Integrity validated! : %~1 [0m
) else (
	if '%second_check%'=='1' echo [91m FATAL : Download or integrity check for %~1 failed completely! [0m && goto download_abort
	set second_check=1
	echo  [93m File integrity damaged... Something must've become corrupted during the download or curl had some issue... [0m
	echo  Falling back to Invoke WebRequest... This might take a bit longer and doesn't give a nice status indication for the download.
	powershell -command "Invoke-WebRequest '%~2' -OutFile '%~1'"
	goto fallback_2
)
EXIT /B 0
:checkTool
call :fetchToolsJson "%inputJson%" %~1
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%localappdata%\revanced-cli\revanced-tools\!fname!' | Select-Object -ExpandProperty Hash"`) DO ( SET ram_h=%%F )
if /i "%ram_h%" == "!hash! " (
	echo  [92m !fname! validated [0m
) else (
	set update=1
)
EXIT /B 0
:patchApp
set "inputString=%~1"
set "keyString=!inputString:.apk=!"
"%JDK%" -jar "%CLI%" patch %~1 -b "%PATCHES%" -m "%INTEGRATIONS%" !patch_sel! !OPTIONS! --keystore "%KEYSTORE%\PATCHED_!keyString!.keystore" -o PATCHED_%~1
EXIT /B 0
:redditOptions
echo.
echo You're patching a third-party reddit client. This requires you to create a client ID at https://www.reddit.com/prefs/apps
echo You can leave "description" and "about url" empty. Make sure to select "installed app".
echo.
echo For "redirect uri" enter the following:
if '%choice%'=='7' echo [92m http://rubenmayayo.com [0m
if '%choice%'=='8' echo [92m dbrady://relay [0m
echo.
if exist "%localappdata%\revanced-cli\options.json" (
	echo  [92m option.json found! [0m
	echo The provided client ID will be used. Make sure it is the correct one.
	echo Pressing any key will open notepad for you to check this value.
) else (
	"%JDK%" -jar "%CLI%" options -o "%PATCHES%"
	move /y "options.json" "%localappdata%\revanced-cli\" > nul 2> nul
	echo An options.json as been created.
	echo The client ID has to be entered where it says null, after value under the spoof client section.
	echo.
	echo Example:    "value"  :  "example_client_id" 
	echo.
	echo Pressing any key will open notepad for you to edit this value.
)
echo Close notepad once you're ready. Don't forget to save within notepad.
echo.
pause
START "" /wait notepad "%localappdata%\revanced-cli\options.json"
set "OPTIONS=--options="%localappdata%\revanced-cli\options.json""
EXIT /B 0
