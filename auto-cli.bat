@echo off
setlocal enabledelayedexpansion
echo The source APKs are downloaded from discord cdn. They originate from apkmirror.
echo The JDK in use is also downloaded from discord cdn. It originates from zulu JDK.
echo Every file's integrity can be checked using checksums.
echo If you wish to abort, close this window.
echo.
pause
REM pre-escape usernames with single quotes
set "localappdata=%localappdata%"
set "PSlocalData=%localappdata%"
set "PSlocalData=!PSlocalData:'=''!"

REM set script location to working dir
pushd "%~dp0"

REM create needed folders
mkdir "%localappdata%\revanced-cli\" > nul 2> nul
mkdir "%localappdata%\revanced-cli\keystore" > nul 2> nul
mkdir "%localappdata%\revanced-cli\apk_backups" > nul 2> nul

REM legacy function to preserve keystore from old versions
copy /y C:\revanced-cli-keystore\*.keystore "%localappdata%\revanced-cli\keystore" > nul 2> nul

REM refresh and enter output dir
rmdir /s /q revanced-cli-output > nul 2> nul
mkdir revanced-cli-output > nul 2> nul
cd revanced-cli-output

REM create link to install dir
mklink /D "backups and more" "%localappdata%\revanced-cli\" > nul 2> nul
echo.

REM refresh input json 
del "%localappdata%\revanced-cli\input.json" > nul 2> nul
powershell -command "Invoke-WebRequest 'https://raw.githubusercontent.com/taku-nm/auto-cli/main/input.json' -OutFile '!PSlocalData!\revanced-cli\input.json' -Headers @{'Cache-Control'='no-cache'}"
if exist "%localappdata%\revanced-cli\input.json" (
   set "inputJson=!PSlocalData!\revanced-cli\input.json"
) else (
	echo  [93m Input.json download failed... Attempting to circumvent geo-blocking... [0m
	powershell -command "Invoke-WebRequest 'http://user737.bplaced.net/downloads/revanced/input.json' -OutFile '!PSlocalData!\revanced-cli\input.json' -Headers @{'Cache-Control'='no-cache'}"
	if exist "%localappdata%\revanced-cli\input.json" (
       set "inputJson=!PSlocalData!\revanced-cli\input.json"
   ) else (
		 echo.
	    echo  [91m FATAL [0m
		 echo  [91m input.json could not be loaded... are you offline? [0m
		 echo.
       echo  Pressing any key will close this window.
       echo.
       pause
       EXIT
	)
)

REM script version check
set batVersion=1.38
for /f %%i in ('powershell -command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).batVersion"') do ( set "jsonBatVersion=%%i" )
if /i '%batVersion%' == '%jsonBatVersion%' (
	echo  [92m Script up-to-date!   Version %batVersion% [0m
) else (
	echo  [93m This script is likely outdated. Check https://github.com/taku-nm/auto-cli for new releases. [0m
	echo  [93m Your version: %batVersion% [0m
	echo  [93m Available version: %jsonBatVersion% [0m
)

REM curl setup
if exist "%localappdata%\revanced-cli\revanced-curl\" (
   echo  [92m cURL found! [0m
) else (
   echo  [93m No cURL found... Downloading... [0m
   powershell -command "Invoke-WebRequest 'https://curl.se/windows/dl-8.2.1_11/curl-8.2.1_11-win64-mingw.zip' -OutFile '!PSlocalData!\revanced-cli\curl.zip'"
	powershell -command "Expand-Archive '!PSlocalData!\revanced-cli\curl.zip' -DestinationPath '!PSlocalData!\revanced-cli\'"
	mkdir "%localappdata%\revanced-cli\revanced-curl\" > nul 2> nul
	copy /y "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\bin\*.*" "%localappdata%\revanced-cli\revanced-curl\*.*"  > nul 2> nul
	rmdir /s /q "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\"  > nul 2> nul
	del "%localappdata%\revanced-cli\curl.zip"
)
set "CURL=%localappdata%\revanced-cli\revanced-curl\curl.exe"
set "CURL_ps=!PSlocalData!\revanced-cli\revanced-curl\curl.exe"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%CURL_ps%' | Select-Object -ExpandProperty Hash"`) DO ( SET CURL_h=%%F )
if /i "%CURL_h%" == "7B27734E0515F8937B7195ED952BBBC6309EE1EEF584DAE293751018599290D1 " (
	echo  [92m cURL integrity validated! [0m
) else (
	echo  [93m cURL integrity invalid... [0m
	rmdir /s /q "%localappdata%\revanced-cli\revanced-curl\" > nul 2> nul
	if exist "%windir%\System32\curl.exe" (
		echo  [92m Windows cURL found... Attempting to fall back on that. [0m
		set "CURL=%windir%\System32\curl.exe"
	) else (
		echo  [93m cURL could not be validated... All downloads will likely revert to Invoke WebRequest... [0m
	)
)

REM JDK setup
:jdk_integ_failed
if exist "%localappdata%\revanced-cli\revanced-jdk\" (
	echo  [92m JDK found! [0m
) else (
	echo  [93m No JDK found... Downloading... [0m
	echo.
	call :downloadWithFallback "%localappdata%\revanced-cli\jdk.zip" "https://cdn.discordapp.com/attachments/1149345921516187789/1149793623324504084/jdk.zip" "5c6b84417f108479c0ff5adc5a3bff1e1af531129573fcfeb2520f8395282e34"
	powershell -command "Expand-Archive '!PSlocalData!\revanced-cli\jdk.zip' -DestinationPath '!PSlocalData!\revanced-cli'"
	del "%localappdata%\revanced-cli\jdk.zip"
)
set "JDK=%localappdata%\revanced-cli\revanced-jdk\bin\java.exe"
set "JDK_ps=!PSlocalData!\revanced-cli\revanced-jdk\bin\java.exe"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%JDK_ps%' | Select-Object -ExpandProperty Hash"`) DO ( SET JDK_h=%%F )
if /i "%JDK_h%" == "6BB6621B7783778184D62D1D9C2D761F361622DD993B0563441AF2364C8A720B " (
	echo  [92m JDK integrity validated! [0m
) else (
	echo  [93m JDK integrity invalid... Something must've become corrupted during the download [0m
	echo Deleting JDK and retrying...
	rmdir /s /q "%localappdata%\revanced-cli\revanced-jdk\" > nul 2> nul
	goto jdk_integ_failed
)

REM tools setup (cli, patches, integrations)
if exist "%localappdata%\revanced-cli\revanced-tools\" (
	for %%i in (cli, patches, integrations) do (
	   call :checkTool %%i
	   set "%%i=%localappdata%\revanced-cli\revanced-tools\!fname!" > nul 2> nul
	)
	if !update! == 1 echo [93m Your ReVanced Tools are out of date or damaged... Re-downloading... [0m && rmdir /s /q "%localappdata%\revanced-cli\revanced-tools\" > nul 2> nul && goto update_jump
	if !update! == 0 goto start
) else (
	echo  [93m No ReVanced Tools found... Downloading... [0m
	:update_jump
	mkdir "%localappdata%\revanced-cli\revanced-tools\" > nul 2> nul
	call :getTools cli patches integrations
)

:start
set "KEYSTORE=%localappdata%\revanced-cli\keystore"
set "k=0"
echo.

REM generate app list
for /f "tokens=*" %%i in ('powershell -command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps.fname"') do (
	set /a "k=k+1"
	for /f "tokens=*" %%j in ('powershell -command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps[!k!].dname"') do (
        echo  [0m !k!. %%j 
    )
)
echo.
echo   A. Custom
echo.
set choice=
set /p choice=Type the number or letter to fetch the corresponding app and hit enter. 
if not defined choice goto start
if %choice% geq 1 if %choice% leq %k% ( goto app_download )
if '%choice%'=='A' goto custom
echo "%choice%" is not valid, try again
echo.
goto start

:app_download
REM fetch config for app and download
call :fetchAppJson "%inputJson%" %choice%
echo Downloading !fname!
call :downloadWithFallback !fname! !link! !hash!

REM account for special cases such as tool modifiers and third party reddit clients
if defined tool_mod echo [93m Your selected app requires specific tools... They will now be loaded [0m && call :getTools cli patches integrations !tool_mod!
if defined uri call :redditOptions

REM patch app
call :fetchAppJson "%inputJson%" %choice%
echo Patching !fname!
if defined tool_mod call :safePatch !fname! && goto end
call :patchApp !fname!
goto end

:custom
if exist ..\revanced-cli-input\ (
	echo [93m The revanced-cli-input folder already exists at the location you're running this script in. [0m
) else (
	mkdir ..\revanced-cli-input\ > nul 2> nul
	echo [92m The folder revanced-cli-input has been created at the location you're running this script in. [0m 
)
echo  Would you like to provide your own APK to patch or download one of the above and customize the rest?
set /p c_choice=Type the number to fetch the corresponding app from above and hit enter. Leave empty to provide your own APK. 
if not defined c_choice goto custom_missing
if %c_choice% geq 1 if %c_choice% leq %k% ( 
    call :fetchAppJson "%inputJson%" %c_choice%
    echo Downloading !fname!
    call :downloadWithFallback !fname! !link! !hash!
	 move /y "!fname!" "..\revanced-cli-input\input.apk" > nul 2> nul
	 echo [92m input.apk placed in revanced-cli-input [0m
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
echo  [92m All files loaded! [0m
if exist ..\revanced-cli-input\patches.jar (
	echo  You've selected a custom patch source. At the next step you will see all available patches.
	echo.
	pause
	"%JDK%" -jar "%CLI%" list-patches -dopv "%PATCHES%"
) else (
	echo  You are using official ReVanced patches. Please look up the patches names at revanced.app/patches.
)
echo.
echo  You now have the opportunity to include and exclude patches using the following syntax:[93m Including the quotes[0m
echo  [92m -i "name of a patch to include" -e "name of a patch to exclude" -i "another patch to include" [0m
echo  Type your options now. Leave empty to apply default patches. Hit enter once you're done.
echo.
set /p SELECTION=
if exist "%localappdata%\revanced-cli\options.json" (
	echo  [92m option.json found! [0m
) else (
	"%JDK%" -jar "%CLI%" options -o "%PATCHES%"
	move /y "options.json" "%localappdata%\revanced-cli\" > nul 2> nul
	echo An options.json as been created.
)
echo Pressing any key will open notepad for you to customize your install.
echo Close notepad once you're ready. Don't forget to save within notepad.
echo.
pause
START "" /wait notepad "%localappdata%\revanced-cli\options.json"
set "OPTIONS=--options="%localappdata%\revanced-cli\options.json""
:filename
echo.
echo  Final question: What app are you patching? This will be your output file.[93m No spaces. No file extensions.[0m
echo  Giving it the same name the last time you patched, ensures that your keystore is being used and in-place updates are possible.
echo  [92m Example: PATCHED_WhatsApp [0m
echo.
set /p OUTPUT=
if '%OUTPUT%'=='' echo  [91m Nu-uh! Provide a name. [0m && goto filename
echo.
"%JDK%" -jar "%CLI%" patch "..\revanced-cli-input\input.apk" -b "%PATCHES%" -m "%INTEGRATIONS%" %SELECTION% %OPTIONS% --keystore "%KEYSTORE%\%OUTPUT%.keystore" -o %OUTPUT%.apk
goto end

:end
copy /y *.keystore "%localappdata%\revanced-cli\keystore" > nul 2> nul
rmdir /s /q C:\revanced-cli-keystore\ > nul 2> nul
rmdir /s /q revanced-resource-cache\ > nul 2> nul
del .\options.json > nul 2> nul
if exist PATCHED_*.apk (
    copy /y "PATCHED_*.apk" "%localappdata%\revanced-cli\apk_backups" > nul 2> nul
    ren "%localappdata%\revanced-cli\apk_backups\PATCHED_*.apk"  "PATCHED_* %time:~0,2%%time:~3,2%-%DATE:/=%.backup" > nul 2> nul
	 :custom_jump
    echo.
    echo  [92m DONE! [0m
    echo  [92m Transfer the PATCHED app found in the revanced-cli-output folder to your phone and open to the apk to install it [0m
    if "!fname!" == "YouTube.apk" call :microG
    if "!fname!" == "YouTube_Music.apk" call :microG
    echo.
    echo  If something goes wrong, screenshot the ENTIRE terminal in your support request in the ReVanced discord support channel.
    echo  bat Version %batVersion%
    echo.
    echo  Backups, keystore and supporting files can be found in AppData\Local\revanced-cli
    echo  To use the backup files, rename them to .apk instead of .backup
    echo.
    echo  Pressing any key will close this window.
    echo.
    pause
    EXIT
) else if '%choice%' == 'A' (
	 goto custom_jump
) else (
	 echo.
    echo  [91m FATAL [0m
	 echo  [91m Something must've gone wrong during patching. Contact taku on discord or open an issue on github. [0m
	 echo  bat Version %batVersion%
	 echo.
    echo  Pressing any key will close this window.
    echo.
    pause
    EXIT
)

REM functions
:fetchToolsJson
set fname=
set link=
set hash=
set tpc=0
for /f %%i in ('powershell -command "(Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.%~3tools.%~2.fname, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.%~3tools.%~2.link, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.%~3tools.%~2.hash"') do (
    if !tpc!==0 (
        set "fname=%%i"
    ) else if !tpc!==1 (
        set "link=%%i"
    ) else if !tpc!==2 (
        set "hash=%%i"
    )
	set /a "tpc=!tpc!+1"
)
if not defined fname goto fetchToolsFail
EXIT /B 0

:fetchToolsFail
echo.
echo  [91m FATAL [0m
echo  [91m Something has gone wrong when attempting to fetch tool info. Contact taku on discord or open an issue on github. [0m
echo  bat Version %batVersion%
echo.
echo  Pressing any key will close this window.
echo.
pause
EXIT

:fetchAppJson
set "JSON=%~1"
set "index=%~2"
set fname=
set link=
set hash=
set patch_sel=
set uri=
set tool_mod=
set apc=0
for /f "tokens=* " %%i in ('powershell -command "(Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].fname, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].link, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].hash, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].patches, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].uri, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].toolMod"') do (
	if !apc!==0 (
        set "fname=%%i"
    ) else if !apc!==1 (
        set "link=%%i"
    ) else if !apc!==2 (
        set "hash=%%i"
    ) else if !apc!==3 (
        set "patch_sel=%%i"
    ) else if !apc!==4 (
		  set "uri=%%i"
	 ) else if !apc!==5 (
		  set "tool_mod=%%i"
	 )
	set /a "apc=!apc!+1"
)
if not defined fname goto fetchAppsFail
EXIT /B 0

:fetchAppsFail
echo.
echo  [91m FATAL [0m
echo  [91m Something has gone wrong when attempting to fetch app info. Contact taku on discord or open an issue on github. [0m
echo  bat Version %batVersion%
echo.
echo  Pressing any key will close this window.
echo.
pause
EXIT

:downloadWithFallback
set second_check=0
"!CURL!" -L "%~2" --output "%~1"
:fallback_2
set ram_h=
set "ram_path=%~1"
set "ram_path=!ram_path:'=''!"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '!ram_path!' | Select-Object -ExpandProperty Hash"`) DO ( SET ram_h=%%F )
if /i "%ram_h%" == "%~3 " (
	echo  [92m Integrity validated !ram_path! [0m
) else (
	if '%second_check%'=='1' echo [91m FATAL : Download or integrity check for !ram_path! failed completely! [0m && goto downloadFail
	set second_check=1
	echo  [93m File integrity damaged... Something must've become corrupted during the download or curl had some issue... [0m
	echo  Falling back to Invoke WebRequest... This might take a bit longer and doesn't give a nice status indication for the download.
	powershell -command "Invoke-WebRequest '%~2' -OutFile '!ram_path!'"
	goto fallback_2
)
EXIT /B 0

:downloadFail
echo.
echo  [91m A download or file integrity check failed... Is the Discord CDN down? Is your internet interrupted? [0m
echo  Other causes might include a very outdated script... Check https://github.com/taku-nm/auto-cli for new releases.
echo  If you can, report to ReVanced Support Discord.
echo.
echo  Pressing any key will end this script.
echo.
pause
EXIT

:checkTool
call :fetchToolsJson "%inputJson%" %~1
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '!PSlocalData!\revanced-cli\revanced-tools\!fname!' | Select-Object -ExpandProperty Hash"`) DO ( SET ram_h=%%F )
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
echo [92m !uri! [0m
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

:microG
echo  [93m Keep in mind that you will need Vanced MicroG for YT and YTM.[0m
echo  Would you like to download Vanced MicroG from GitHub now?
echo.
echo   1. Yes
echo   2. No
echo.
set vD=
set /p vD=Type the number to select your answer and hit enter. 
if '%vD%'=='1' call :downloadWithFallback vanced_microG.apk "https://github.com/TeamVanced/VancedMicroG/releases/download/v0.2.24.220220-220220001/microg.apk" "e5ce4f9759d3e70ac479bf2d0707efe5a42fca8513cf387de583b8659dbfbbbf"
EXIT /B 0

:getTools
for %%i in (%~1, %~2, %~3) do (
	   call :fetchToolsJson "%inputJson%" %%i %~4
	   call :downloadWithFallback "%localappdata%\revanced-cli\revanced-tools\!fname!" !link! !hash!
	   set "%%i=%localappdata%\revanced-cli\revanced-tools\!fname!"
	)
EXIT /B 0

:safePatch
"%JDK%" -jar "%CLI%" patch %~1 -b "%PATCHES%" -m "%INTEGRATIONS%" !patch_sel! !OPTIONS! -o PATCHED_%~1
EXIT /B 0