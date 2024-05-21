@echo off
setlocal enabledelayedexpansion
echo The source APKs are downloaded from discord cdn. They originate from apkmirror.
echo The JDK in use is also downloaded from discord cdn. It originates from zulu JDK.
echo Every file's integrity can be checked using checksums.
echo If you wish to abort, close this window.
echo.
pause

set batVersion=3.9

FOR /F "tokens=2 delims=:." %%C IN ('chcp') DO (
	if %%C equ 708 (
      chcp 65001 > nul
	) else if %%C equ 720 (
		chcp 65001 > nul
	) else if %%C equ 862 (
		chcp 65001 > nul
	) else if %%C equ 864 (
		chcp 65001 > nul
	) else if %%C equ 1255 (
		chcp 65001 > nul
	) else if %%C equ 1256 (
		chcp 65001 > nul
	)
)


REM set script location to working dir
pushd "%~dp0"

REM check if powershell is present
set PS_check=0
:PScheck
where powershell >nul 2>nul
if not !errorlevel! equ 0 (
	if !PS_check!==1 (
		echo  [91m FATAL: Powershell is missing. [0m
		echo  [91m Powershell was not found in PATH nor its default location. [0m
		echo  [91m The script cannot function without powershell being accessible. [0m
		echo.
		pause > nul 2> nul
		EXIT
	)
	echo.
	echo  [93m Warning: Powershell is missing from your PATH variable. Attemping to fix for this session. [0m
   set "PATH=!PATH!;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\"
	set PS_check=1
	goto :PScheck
)

REM check if current directory contains non-ASCII characters
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "'%cd%' -match '[^\x00-\x7F]'"`) DO ( 
	 if "%%F" == "True" (
	   echo.
		echo  [91m ATTENTION [0m
		echo  [91m You are executing this script in a path that contains non-ASCII characters [0m
		echo  [91m Doing so will cause patching to fail in a later stage. [0m
		echo  [91m Please move the script to a different location and run it again. [0m
		echo.
		echo  [91m Your current path: %0  [0m
		pause > nul 2> nul
		EXIT
	 )
)

REM check if major version is 3 at minimum
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "$Host.Version.Major"`) DO ( 
    if not %%F geq 3 (
	   echo.
		echo  [91m ATTENTION [0m
		echo  [91m Your PowerShell, Version %%F is too old to run this script. [0m
		echo  [91m Please use the Windows Management Framework to update. [0m
		echo  [93m https://www.microsoft.com/en-us/download/details.aspx?id=54616 [0m
		pause > nul 2> nul
		EXIT
	 )
)

REM check if PATH is greater than 2048 to avoid unexpected behaviour
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "$env:PATH.Length"`) DO ( 
    if %%F geq 2048 (
	   echo.
		echo  [93m Warning: Your current PATH variable is over 2047 characters long. Current value: %%F [0m
		echo  [93m If you encounter the script failing, this can be the cause. No immediate actions required. [0m
	 )
)

REM pre-escape usernames with single quotes
set "localappdata=%localappdata%"
set "PSlocalData=%localappdata%"
set "PSlocalData=!PSlocalData:'=''!"

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

set "MODE=main"
:modeChange

REM refresh input json 
del "%localappdata%\revanced-cli\input.json" > nul 2> nul
powershell -NoProfile -NonInteractive -Command "Invoke-WebRequest 'https://raw.githubusercontent.com/taku-nm/auto-cli/!MODE!/input3.json' -OutFile '!PSlocalData!\revanced-cli\input.json' -Headers @{'Cache-Control'='no-cache'}"
if exist "%localappdata%\revanced-cli\input.json" (
   set "inputJson=!PSlocalData!\revanced-cli\input.json"
) else (
	echo  [93m Input.json download failed... Attempting to circumvent geo-blocking... [0m
	powershell -NoProfile -NonInteractive -Command "Invoke-WebRequest 'http://user737.bplaced.net/downloads/revanced/input3.json' -OutFile '!PSlocalData!\revanced-cli\input.json' -Headers @{'Cache-Control'='no-cache'}"
	if exist "%localappdata%\revanced-cli\input.json" (
       set "inputJson=!PSlocalData!\revanced-cli\input.json"
   ) else (
		 echo.
	    echo  [91m FATAL [0m
		 echo  [91m input.json could not be loaded... are you offline? [0m
		 echo  Contact taku on ReVanced discord or open an issue on GitHub.
		 echo  Include a screenshot of the entire terminal.
		 echo.
       echo  Pressing any key will close this window.
       pause > nul 2> nul
       EXIT
	)
)

REM script version check
for /f %%i in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).batVersion"') do ( set "jsonBatVersion=%%i" )
if /i '%batVersion%' == '%jsonBatVersion%' (
	echo  [92m Script up-to-date!   Version %batVersion% [0m
) else (
	echo  [93m This script is likely outdated. Check https://github.com/taku-nm/auto-cli/releases for new releases. [0m
	echo  [93m Your version: %batVersion% [0m
	echo  [93m Available version: %jsonBatVersion% [0m
)

REM wget setup
if exist "%localappdata%\revanced-cli\revanced-wget\" (
   echo  [92m Wget found! [0m
) else (
   echo  [93m No Wget found... Downloading... [0m
	mkdir "%localappdata%\revanced-cli\revanced-wget\" > nul 2> nul
   powershell -NoProfile -NonInteractive -Command "Invoke-WebRequest 'https://eternallybored.org/misc/wget/1.21.4/64/wget.exe' -OutFile '!PSlocalData!\revanced-cli\revanced-wget\wget.exe'"
)
set "WGET=%localappdata%\revanced-cli\revanced-wget\wget.exe"
set "WGET_ps=!PSlocalData!\revanced-cli\revanced-wget\wget.exe"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "Get-FileHash -Algorithm SHA256 '%WGET_ps%' | Select-Object -ExpandProperty Hash"`) DO ( SET WGET_h=%%F )
if /i "%WGET_h%" == "6136e66e41acd14c409c2d3eb10d48a32febaba04267303d0460ed3bee746cc5 " (
	echo  [92m Wget integrity validated! [0m
) else (
	echo  [93m Wget integrity invalid... [0m
	rmdir /s /q "%localappdata%\revanced-cli\revanced-wget\" > nul 2> nul
	echo  [93m Wget could not be validated... All downloads will likely revert to cURL or invoke webrequest... [0m
)

REM curl setup
if exist "%localappdata%\revanced-cli\revanced-curl\" (
   echo  [92m cURL found! [0m
) else (
   echo  [93m No cURL found... Downloading... [0m
   powershell -NoProfile -NonInteractive -Command "Invoke-WebRequest 'https://curl.se/windows/dl-8.2.1_11/curl-8.2.1_11-win64-mingw.zip' -OutFile '!PSlocalData!\revanced-cli\curl.zip'"
	powershell -NoProfile -NonInteractive -Command "Expand-Archive '!PSlocalData!\revanced-cli\curl.zip' -DestinationPath '!PSlocalData!\revanced-cli\'"
	mkdir "%localappdata%\revanced-cli\revanced-curl\" > nul 2> nul
	copy /y "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\bin\*.*" "%localappdata%\revanced-cli\revanced-curl\*.*"  > nul 2> nul
	rmdir /s /q "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\"  > nul 2> nul
	del "%localappdata%\revanced-cli\curl.zip"
)
set "CURL=%localappdata%\revanced-cli\revanced-curl\curl.exe"
set "CURL_ps=!PSlocalData!\revanced-cli\revanced-curl\curl.exe"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "Get-FileHash -Algorithm SHA256 '%CURL_ps%' | Select-Object -ExpandProperty Hash"`) DO ( SET CURL_h=%%F )
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
	call :fetchToolsJson "%inputJson%" JDK
	call :downloadWithFallback "%localappdata%\revanced-cli\!fname!" "!link!" "!hash!"
	powershell -NoProfile -NonInteractive -Command "Expand-Archive '!PSlocalData!\revanced-cli\!fname!' -DestinationPath '!PSlocalData!\revanced-cli'"
	del "%localappdata%\revanced-cli\!fname!"
)
set "JDK=%localappdata%\revanced-cli\revanced-jdk\bin\java.exe"
set "KEYTOOL=%localappdata%\revanced-cli\revanced-jdk\bin\keytool.exe"
set "JDK_ps=!PSlocalData!\revanced-cli\revanced-jdk\bin\java.exe"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "Get-FileHash -Algorithm SHA256 '%JDK_ps%' | Select-Object -ExpandProperty Hash"`) DO ( SET JDK_h=%%F )
if /i "%JDK_h%" == "6BB6621B7783778184D62D1D9C2D761F361622DD993B0563441AF2364C8A720B " (
	echo  [92m JDK integrity validated! [0m
) else (
	echo  [93m JDK integrity invalid... Something must've become corrupted during the download [0m
	echo Deleting JDK and retrying...
	rmdir /s /q "%localappdata%\revanced-cli\revanced-jdk\" > nul 2> nul
	goto jdk_integ_failed
)

REM check and create keystore password
if exist "%localappdata%\revanced-cli\keystore\keystore_password_do_not_share.txt" (
    set /p KEY_PW=< "%localappdata%\revanced-cli\keystore\keystore_password_do_not_share.txt"
) else (
	 set KEY_PW=%random%%random%%random%%random%
	 echo !KEY_PW!>"%localappdata%\revanced-cli\keystore\keystore_password_do_not_share.txt"
)

REM check for and transform old keystores
if exist "%localappdata%\revanced-cli\keystore\*.keystore" (
	echo  [93m Old keystores found [0m
	call :fetchToolsJson "%inputJson%" BCS
	call :downloadWithFallback "%localappdata%\revanced-cli\!fname!" "!link!" "!hash!"
	for %%i in ("%localappdata%\revanced-cli\keystore\*.keystore") DO (
		if "%%i"=="%localappdata%\revanced-cli\keystore\PATCHED_Sync.keystore" (
			move "%%i" "%%~dpi%%~ni.no_pw_keystore" > nul 2> nul
		) else if "%%i"=="%localappdata%\revanced-cli\keystore\PATCHED_Relay.keystore" (
         move "%%i" "%%~dpi%%~ni.no_pw_keystore" > nul 2> nul
		) else (
	      "%KEYTOOL%" -storepasswd -storepass ReVanced -new !KEY_PW! -storetype bks -provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath "%localappdata%\revanced-cli\!fname!" -keystore "%%i" -alias alias
         move "%%i" "%%~dpi%%~ni.secure_keystore" > nul 2> nul
			echo  [92m Keystore %%~ni transformed [0m
	   )
	)
)

REM tools setup (cli, patches, integrations)
if exist "%localappdata%\revanced-cli\revanced-tools\" (
	for %%i in (cli, patches, integrations) do (
	   call :checkTool %%i
	   set "%%i=%localappdata%\revanced-cli\revanced-tools\!fname!" > nul 2> nul
	)
	if !update! == 1 echo [93m Your ReVanced Tools are out of date or damaged... Re-downloading... [0m && goto update_jump
	if !update! == 0 goto start
) else (
	echo  [93m No ReVanced Tools found... Downloading... [0m
	:update_jump
	mkdir "%localappdata%\revanced-cli\revanced-tools\" > nul 2> nul
	call :getTools "cli, patches, integrations"
)

:start
set "KEYSTORE=%localappdata%\revanced-cli\keystore"
set "k=0"
echo.
if "!MODE!" == "dev" (
	echo [93m You are currently in developer mode. Do you know what you are doing? [0m
)
echo.

REM generate app list
for /f "tokens=*" %%i in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps.fname"') do (
	set /a "k=k+1"
	for /f "tokens=*" %%j in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps[!k!].dname"') do (
        echo  [0m !k!. %%j 
    )
)
echo.
echo   A. Custom
if "!MODE!" == "main" echo   B. Developer Mode
if "!MODE!" == "dev" echo   B. Normal Mode
echo.
set choice=
set /p choice=Type the number or letter to fetch the corresponding app and hit enter. 
if not defined choice goto start
if %choice% geq 1 if %choice% leq %k% ( goto app_download )
if '%choice%'=='A' goto custom
if '%choice%'=='B' if "!MODE!" == "main" set "MODE=dev" && goto modeChange
if '%choice%'=='B' if "!MODE!" == "dev" set "MODE=main" && goto modeChange
echo "%choice%" is not valid, try again
echo.
goto start

:app_download
REM fetch config for app and download
call :fetchAppJson "%inputJson%" %choice%
echo Downloading !fname!
call :downloadWithFallback "!fname!" "!link!" "!hash!"

REM account for special cases such as tool modifiers and third party reddit clients
if defined tool_mod echo [93m Your selected app requires specific tools... They will now be loaded [0m && call :getTools "cli, patches, integrations" !tool_mod!
if defined uri call :redditOptions

REM patch app
call :fetchAppJson "%inputJson%" %choice%
echo Patching !fname!
if defined cmd_mod call :modifiedPatch && goto end
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
    call :downloadWithFallback "!fname!" "!link!" "!hash!"
	 move /y "!fname!" "..\revanced-cli-input\input.apk" > nul 2> nul
	 echo [92m input.apk placed in revanced-cli-input [0m
 )

:custom_missing
echo [93m Ensure that the ONLY files in revanced-cli-input are the app, cli, patches and integrations that you would want to use. [0m
echo  The app [93mMUST[0m be called 'input.apk' 
echo  The CLI [93mMUST[0m be called 'cli.jar' 
echo  The patches [93mMUST[0m be called 'patches.jar'.
echo  The integrations [93mMUST[0m be called 'integrations.apk'
echo [93m CLI, Patches and integrations are optional. Not providing them will cause the script to use official ReVanced tools. [0m
echo Once you're ready, press any key to continue...
pause > nul 2> nul
echo.
if exist ..\revanced-cli-input\input.apk (
	echo [92m input.apk found! [0m
) else (
	echo [91m input.apk missing! [0m
	echo.
	goto custom_missing
)
if exist ..\revanced-cli-input\cli.jar (
	echo [92m cli.jar found! [0m
	set CLI=..\revanced-cli-input\cli.jar
) else (
	echo  No cli.jar found... Continuing using official ReVanced CLI
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
	echo  You are using official ReVanced patches. [93m Please look up the patch names and capitalizations at https://revanced.app/patches. [0m
)
echo.
echo  You now have the opportunity to include and exclude patches using the following syntax:[93m Including the quotes[0m
echo  [92m -i "name of a patch to include" -e "name of a patch to exclude" -i "another patch to include" [0m
echo  Type your options now. Leave empty to apply default patches. Hit enter once you're done.
echo.
set /p SELECTION=
del "%localappdata%\revanced-cli\options.json" > nul 2> nul
"%JDK%" -jar "%CLI%" options -o "%PATCHES%" > nul 2> nul
if exist .\options.json (
    move /y "options.json" "%localappdata%\revanced-cli\" > nul 2> nul
    echo  An options.json as been created.
    echo  Pressing any key will open notepad for you to customize your install.
	 echo  Don't be confused at default values that dont apply to the app you are patching.
	 echo  If the patch isn't selected, it will not use those values.
    echo  Close notepad once you're ready. Don't forget to save within notepad.
    pause > nul 2> nul
    START "" /wait notepad "%localappdata%\revanced-cli\options.json"
    set "optionsJson=%localappdata%\revanced-cli\options.json"
    set "OPTIONS=--options="!optionsJson!""
) else (
	 echo.
    echo  [93mThe options.json could not be created.[0m Likely because the chosen CLI and patches are not compatible with each other.
	 echo  If you want, you can press any key to continue despite this.
	 pause > nul 2> nul
	 set OPTIONS=
)

:filename
echo.
echo  Final question: What app are you patching? This will be your output file.[93m No spaces. No file extensions.[0m
echo  Giving it the same name as the last time you patched ensures that the same keystore is used, which allows for updates without needing to uninstall first.
echo  Unlike previous versions, [93mDO NOT[0m add the PATCHED_ in the beginning.
echo  [92m Example: WhatsApp [0m
echo.
set /p OUTPUT=
if '%OUTPUT%'=='' echo  [91m Nu-uh! Provide a name. [0m && goto filename
echo.
"%JDK%" -jar "%CLI%" patch "..\revanced-cli-input\input.apk" -b "%PATCHES%" -m "%INTEGRATIONS%" %SELECTION% %OPTIONS% --keystore "%KEYSTORE%\PATCHED_%OUTPUT%.secure_keystore" --alias="alias" --keystore-password="%KEY_PW%" --keystore-entry-password="ReVanced" -o PATCHED_%OUTPUT%.apk
goto end

:end
rmdir /s /q C:\revanced-cli-keystore\ > nul 2> nul
rmdir /s /q PATCHED_!keyString!-resource-cache\ > nul 2> nul
del PATCHED_!keyString!-options.json > nul 2> nul
del !fname! > nul 2> nul
if exist PATCHED_*.apk (
    copy /y "PATCHED_*.apk" "%localappdata%\revanced-cli\apk_backups" > nul 2> nul
    ren "%localappdata%\revanced-cli\apk_backups\PATCHED_*.apk"  "PATCHED_* %time:~0,2%%time:~3,2%-%DATE:/=%.backup" > nul 2> nul
    echo.
    echo  [92m DONE! [0m
    echo  [92m Transfer the PATCHED app to your phone and open to the apk to install it [0m
	 if '%choice%' == 'A' ( echo  [92m Location: %CD%\PATCHED_!OUTPUT!.apk [0m ) else ( echo  [92m Location: %CD%\PATCHED_!fname! [0m )
    if /i "!extra!!" == "true" call :extras
    echo.
    echo  bat Version %batVersion%
    echo.
    echo  Backups, keystore and supporting files can be found in AppData\Local\revanced-cli
    echo  To use the backup files, rename them to .apk instead of .backup
    echo.
    echo  Pressing any key will close this window.
    pause > nul 2> nul
    EXIT
) else (
	 echo.
    echo  [91m FATAL [0m
	 echo  [91m Something must've gone wrong during patching. Contact taku on ReVanced discord or open an issue on GitHub. [0m
	 echo.
	 echo  Include a screenshot of the entire terminal.
	 echo  Debug info:
	 if '%choice%' == 'A' (
		echo.
		echo  Since you've used the custom option, it is likely that your chosen CLI version and patches don't work with each other.
		echo  [93mMake sure to include the versions of what you've been using with your help request.[0m
		echo  CLI: %CLI%
		echo  Patches: %PATCHES%
		echo  Integrations: %INTEGRATIONS%
		echo  Selection: %SELECTION%
		echo  Options: %OPTIONS%
		echo  Output: %OUTPUT%
		echo  c_Choice: %c_choice%
	 )
	 echo.
	 echo  bat Version %batVersion%
	 echo  Choice: %choice%
	 echo  Appdata/Local: %localappdata%
	 echo.
    echo  Pressing any key will close this window.
    pause > nul 2> nul
    EXIT
)

REM functions
:fetchToolsJson
set fname=
set link=
set hash=
set tpc=0
for /f %%i in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.%~3tools.%~2.fname, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.%~3tools.%~2.link, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.%~3tools.%~2.hash"') do (
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
if "!MODE!" == "dev" (
	echo Filename !fname!
	echo Link !link!
	echo Hash !hash!
)
EXIT /B 0

:fetchToolsFail
echo.
echo  [91m FATAL [0m
echo  [91m Something has gone wrong when attempting to fetch tool info. Contact taku on ReVanced discord or open an issue on GitHub. [0m
echo  Include a screenshot of the entire terminal.
echo  bat Version %batVersion%
echo.
echo  Pressing any key will close this window.
pause > nul 2> nul
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
set cmd_mod=
set extra=
set apc=0
for /f "tokens=* " %%i in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].fname, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].link, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].hash, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].patches, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].uri, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].toolMod, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].cmdMod, (Get-Content -Raw '!JSON!' | ConvertFrom-Json).downloads.apps[!index!].extras[0].enabled"') do (
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
	 ) else if !apc!==6 (
		  set "cmd_mod=%%i"
	 ) else if !apc!==7 (
		  set "extra=%%i"
	 )
	set /a "apc=!apc!+1"
)
if not defined fname goto fetchAppsFail
if "!MODE!" == "dev" (
	echo Filename !fname!
	echo Link !link!
	echo Hash !hash!
	echo Patch selection !patch_sel!
	echo URI !uri!
	echo Tool modifier !tool_mod!
	echo Command modifier !cmd_mod!
	echo Extra enabled? !extra!
)
EXIT /B 0

:fetchAppsFail
echo.
echo  [91m FATAL [0m
echo  [91m Something has gone wrong when attempting to fetch app info. Contact taku on ReVanced discord or open an issue on GitHub. [0m
echo  Include a screenshot of the entire terminal.
echo  bat Version %batVersion%
echo.
echo  Pressing any key will close this window.
pause > nul 2> nul
EXIT

:fetchExtraJson
set fname=
set link=
set hash=
set epc=0
for /f %%i in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.extras.%~2.fname, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.extras.%~2.link, (Get-Content -Raw '%~1' | ConvertFrom-Json).downloads.extras.%~2.hash"') do (
    if !epc!==0 (
        set "fname=%%i"
    ) else if !epc!==1 (
        set "link=%%i"
    ) else if !epc!==2 (
        set "hash=%%i"
    )
	set /a "epc=!epc!+1"
)
if not defined fname goto fetchExtraFail
if "!MODE!" == "dev" (
	echo Filename !fname!
	echo Link !link!
	echo Hash !hash!
)
EXIT /B 0

:fetchExtraFail
echo.
echo  [91m FATAL [0m
echo  [91m Something has gone wrong when attempting to fetch extras info. Contact taku on ReVanced discord or open an issue on GitHub. [0m
echo  Include a screenshot of the entire terminal.
echo  bat Version %batVersion%
echo.
echo  Pressing any key will close this window.
pause > nul 2> nul
EXIT

:downloadWithFallback
set fallback=0
"!WGET!" -q --show-progress -O "%~1" "%~2"
set ram_h=
set "ram_path=%~1"
set "ram_path=!ram_path:'=''!"
:fallback
if '!fallback!'=='1' ( "!CURL!" -k -L "%~2" --output "%~1" )
if '!fallback!'=='2' ( powershell -NoProfile -NonInteractive -Command "Invoke-WebRequest '%~2' -OutFile '!ram_path!'" )
if "!MODE!" == "dev" (
	echo ram_path !ram_path!
	echo passed_value_1 "%~1"
	echo passed_value_2 "%~2"
)
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "Get-FileHash -Algorithm SHA256 '!ram_path!' | Select-Object -ExpandProperty Hash"`) DO ( SET ram_h=%%F )
if /i "%ram_h%" == "%~3 " (
	echo  [92m Integrity validated %~1 [0m
) else (
	if '!fallback!'=='0' (
       echo  [93m File integrity damaged... Something must've become corrupted during the download or wget had some issue... [0m
		 echo Falling back to cURL...
		 set /a "fallback=!fallback!+1"
		 goto fallback
	)
	if '!fallback!'=='1' (
       echo  [93m File integrity still damaged... Something must've become corrupted during the download or cURL had some issue... [0m
		 echo Falling back to Invoke Webrequest...
		 set /a "fallback=!fallback!+1"
		 goto fallback
	)
	if '!fallback!'=='2' (
		 echo [91m FATAL : Download or integrity check for %~1 failed completely! [0m
		 goto downloadFail
	)
)
EXIT /B 0

:downloadFail
echo.
echo  [91m A download or file integrity check failed... Is the Discord CDN down? Is your internet interrupted? [0m
echo  Other causes might include a very outdated script... Check https://github.com/taku-nm/auto-cli for new releases.
echo  Contact taku on ReVanced discord or open an issue on GitHub.
echo  Include a screenshot of the entire terminal.
echo.
echo  Pressing any key will end this script.
pause > nul 2> nul
EXIT

:checkTool
call :fetchToolsJson "%inputJson%" %~1
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -NoProfile -NonInteractive -Command "Get-FileHash -Algorithm SHA256 '!PSlocalData!\revanced-cli\revanced-tools\!fname!' | Select-Object -ExpandProperty Hash"`) DO ( SET ram_h=%%F )
if /i "%ram_h%" == "!hash! " (
	echo  [92m !fname! validated [0m
) else (
	set update=1
)
EXIT /B 0

:patchApp
if "!MODE!" == "dev" (
	echo Patch current Filename !fname!
	echo JDK "%JDK%"
	echo CLI "%CLI%"
	echo Patches "%PATCHES%"
	echo Integrations "%INTEGRATIONS%"
	echo Patch selection !patch_sel!
	echo Options !OPTIONS!
	echo Keystore Path "%KEYSTORE%"
	echo Keystore Password "%KEY_PW%"
)
set "inputString=%~1"
set "keyString=!inputString:.apk=!"
if "!inputString!"=="Relay.apk" (
	if exist "%KEYSTORE%\PATCHED_Relay.no_pw_keystore" (
	   "%JDK%" -jar "%CLI%" patch %~1 -b "%PATCHES%" -m "%INTEGRATIONS%" !patch_sel! !OPTIONS! --keystore "%KEYSTORE%\PATCHED_Relay.no_pw_keystore" -o PATCHED_%~1
    ) else goto standard_patch
) else if "!inputString!"=="Sync.apk" (
	if exist "%KEYSTORE%\PATCHED_Sync.no_pw_keystore" (
	   "%JDK%" -jar "%CLI%" patch %~1 -b "%PATCHES%" -m "%INTEGRATIONS%" !patch_sel! !OPTIONS! --keystore "%KEYSTORE%\PATCHED_Sync.no_pw_keystore" -o PATCHED_%~1
    ) else goto standard_patch
) else (
	:standard_patch
   "%JDK%" -jar "%CLI%" patch %~1 -b "%PATCHES%" -m "%INTEGRATIONS%" !patch_sel! !OPTIONS! --keystore "%KEYSTORE%\PATCHED_!keyString!.secure_keystore" --alias="alias" --keystore-password="%KEY_PW%" --keystore-entry-password="ReVanced" -o PATCHED_%~1
)
EXIT /B 0

:redditOptions
echo.
echo  You're patching a third-party reddit client. This requires you to create a client ID.
echo [93m You can leave "description" and "about url" empty. Make sure to select "installed app". [0m
echo  For "redirect uri" enter the following:
echo [92m !uri! [0m
echo  Pressing any key will open your browser for you to create a reddit app.
pause > nul 2> nul
start https://www.reddit.com/prefs/apps
echo [93m Paste your client ID now. [0m It is written below "installed app". Do NOT place a space at the end. Press enter once you are done.
echo.
set /p client_id=
if not defined client_id echo [91m Provide a client ID [0m && goto redditOptions 
del "%localappdata%\revanced-cli\options.json" > nul 2> nul
"%JDK%" -jar "%CLI%" options -o "%PATCHES%" > nul 2> nul
move /y "options.json" "%localappdata%\revanced-cli\" > nul 2> nul
set "optionsJson=%localappdata%\revanced-cli\options.json"
for /f "usebackq delims=" %%a in ("%optionsJson%") do (
    set "jsonContent=!jsonContent!%%a"
)
set "NEW_jsonContent=!jsonContent:"Spoof client",  "options" : [ {    "key" : "client-id",    "value" : null="Spoof client",  "options" : [ {    "key" : "client-id",    "value" : "%client_id%"!"
echo !NEW_jsonContent! > "%optionsJson%"
set "OPTIONS=--options="!optionsJson!""
EXIT /B 0

:extras
set /a "m=0"
echo.
echo  Additional apps (Skip if already installed):
echo.
for /f "tokens=*" %%j in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps[!index!].extras.ename"') do (
	set /a "m=m+1"
	for /f "tokens=*" %%r in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps[!index!].extras[!m!].required"') do (
       if /i "%%r" == "true" set "status=[93m(Required)[0m"
		 if /i "%%r" == "false" set "status=(Optional)"
   )
	for /f "tokens=*" %%n in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.extras.%%j.dname"') do (
       echo  [0m !m!. %%n   !status!
   )
)
echo.
echo  Download any of them now?
echo [93m Format your answer like this: 1, 2  [0m etc... 
echo.
set eC=
set /p eC=[93m Leave empty to skip. [0m Press enter to confirm. 
if not defined eC EXIT /B 0
set "eC_lastChar=!eC:~-1!"
if "!eC_lastChar!"=="," echo [91m Invalid formatting. Remove the comma at the end. [0m && goto :extras
if "!eC_lastChar!"==" " echo [91m Invalid formatting. Remove the space at the end. [0m && goto :extras
if !eC_lastChar! geq 1 if !eC_lastChar! leq 9 (
   for /f "tokens=*" %%a in ("!eC!") do (
		 for %%b in (%%a) do (
			 if %%b geq 1 if %%b leq !m! (
             for /f "tokens=*" %%q in ('powershell -NoProfile -NonInteractive -Command "(Get-Content -Raw '%inputJson%' | ConvertFrom-Json).downloads.apps[!index!].extras[%%b].ename"') do (
                call :fetchExtraJson "%inputJson%" "%%q"
    	          call :downloadWithFallback "!fname!" "!link!" "!hash!"
    	       )    
			 ) else (
				   echo  Selected App Nr. %%b is invalid. Skipping.
			 )
       )
   )
) else (
    echo [91m Invalid answer. [0m 
	 goto :extras
)
EXIT /B 0

:getTools
for /f "tokens=*" %%a in ("%~1") do (
    for %%b in (%%a) do (
	   call :fetchToolsJson "%inputJson%" %%b %~2
	   call :downloadWithFallback "%localappdata%\revanced-cli\revanced-tools\!fname!" "!link!" "!hash!"
	   set "%%b=%localappdata%\revanced-cli\revanced-tools\!fname!" 
    )
)
EXIT /B 0

:modifiedPatch
set "inputString=!fname!"
set "keyString=!inputString:.apk=!"
set "cmd_mod=!cmd_mod:keyString=%keyString%!"
"%JDK%" -jar !cmd_mod!
EXIT /B 0
