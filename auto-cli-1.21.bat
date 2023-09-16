@echo off
echo The source APKs are downloaded from discord cdn. They originate from apkmirror.
echo The JDK in use is also downloaded from discord cdn. It originates from zulu JDK.
echo Every file's integrity can be checked using checksums.
echo If you wish to abort, close this window.
echo.
pause
pushd "%~dp0"
mkdir "%localappdata%\revanced-cli\" > nul 2> nul
mkdir "%localappdata%\revanced-cli\keystore" > nul 2> nul
mkdir "%localappdata%\revanced-cli\apk_backups" > nul 2> nul
copy /y C:\revanced-cli-keystore\*.keystore "%localappdata%\revanced-cli\keystore" > nul 2> nul
rmdir /s /q revanced-cli-output > nul 2> nul
mkdir revanced-cli-output > nul 2> nul
cd revanced-cli-output
echo.
:integ_failed
if exist "%localappdata%\revanced-cli\revanced-curl\" (
    echo  [92m Curl found! [0m
	echo.
) else (
    echo [93m No Curl found... Downloading... [0m
	echo.
    powershell -command "Invoke-WebRequest 'https://curl.se/windows/dl-8.2.1_11/curl-8.2.1_11-win64-mingw.zip' -OutFile '%localappdata%\revanced-cli\curl.zip'"
	powershell -command "Expand-Archive '%localappdata%\revanced-cli\curl.zip' -DestinationPath '%localappdata%\revanced-cli\'"
	mkdir "%localappdata%\revanced-cli\revanced-curl\" > nul 2> nul
	Xcopy "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\bin\" "%localappdata%\revanced-cli\revanced-curl\"  > nul 2> nul
	rmdir /s /q "%localappdata%\revanced-cli\curl-8.2.1_11-win64-mingw\"  > nul 2> nul
	del "%localappdata%\revanced-cli\curl.zip"
    echo.
)
if exist "%localappdata%\revanced-cli\revanced-jdk\" (
	echo  [92m JDK found! [0m
	echo.
) else (
	echo [93m No JDK found... Downloading... [0m
	echo.
	"%localappdata%\revanced-cli\revanced-curl\curl.exe" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1149793623324504084/jdk.zip" --output "%localappdata%\revanced-cli\jdk.zip"
	powershell -command "Expand-Archive '%localappdata%\revanced-cli\jdk.zip' -DestinationPath '%localappdata%\revanced-cli'"
	del "%localappdata%\revanced-cli\jdk.zip"
	echo.
)
if exist "%localappdata%\revanced-cli\revanced-tools\" (
	echo  [92m ReVanced Tools found! [0m
	echo.
) else (
	echo [93m No ReVanced Tools found... Downloading... [0m
	echo.
	mkdir "%localappdata%\revanced-cli\revanced-tools\" > nul 2> nul
	"%localappdata%\revanced-cli\revanced-curl\curl.exe" -L "https://github.com/ReVanced/revanced-patches/releases/download/v2.190.0/revanced-patches-2.190.0.jar" --output "%localappdata%\revanced-cli\revanced-tools\revanced-patches-2.190.0.jar"
	"%localappdata%\revanced-cli\revanced-curl\curl.exe" -L "https://github.com/ReVanced/revanced-integrations/releases/download/v0.117.1/revanced-integrations-0.117.1.apk" --output "%localappdata%\revanced-cli\revanced-tools\revanced-integrations-0.117.1.apk"
	"%localappdata%\revanced-cli\revanced-curl\curl.exe" -L "https://github.com/ReVanced/revanced-cli/releases/download/v3.1.0/revanced-cli-3.1.0-all.jar" --output "%localappdata%\revanced-cli\revanced-tools\revanced-cli-3.1.0-all.jar"
	echo.
)
set "CURL=%localappdata%\revanced-cli\revanced-curl\curl.exe"
set "JDK=%localappdata%\revanced-cli\revanced-jdk\bin\java.exe"
set "CLI=%localappdata%\revanced-cli\revanced-tools\revanced-cli-3.1.0-all.jar"
set "PATCHES=%localappdata%\revanced-cli\revanced-tools\revanced-patches-2.190.0.jar"
set "INTEGRATIONS=%localappdata%\revanced-cli\revanced-tools\revanced-integrations-0.117.1.apk"
set "KEYSTORE=%localappdata%\revanced-cli\keystore"
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%CURL%' | Select-Object -ExpandProperty Hash"`) DO ( SET CURL_h=%%F )
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%JDK%' | Select-Object -ExpandProperty Hash"`) DO ( SET JDK_h=%%F )
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%CLI%' | Select-Object -ExpandProperty Hash"`) DO ( SET CLI_h=%%F )
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%PATCHES%' | Select-Object -ExpandProperty Hash"`) DO ( SET PATCHES_h=%%F )
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 '%INTEGRATIONS%' | Select-Object -ExpandProperty Hash"`) DO ( SET INTEGRATIONS_h=%%F )
set "comb_h=%CURL_h%%JDK_h%%CLI_h%%PATCHES_h%%INTEGRATIONS_h%"
set "comp_h=7B27734E0515F8937B7195ED952BBBC6309EE1EEF584DAE293751018599290D1 6BB6621B7783778184D62D1D9C2D761F361622DD993B0563441AF2364C8A720B D53327788EBB1D96647736C375A69D64910B2897616339332718C0BE99CCCBE0 6C0AAE909547CB563F3F536EF420FA69FC83FB28B3C263F8ECEDACDAEA2A50F1 C2FC01E5F9B5866A38533A4BA37C0AE1CF2F8F353ACBED2D334693506FFE32EA "
if /i "%comb_h%" == "%comp_h%" (
	echo  [92m File integrity validated! [0m
	echo.
	goto start
) else (
	echo  [93m File integrity damaged... Something must've become corrupted during the download [0m
	echo Deleting everyting and retrying...
	rmdir /s /q "%localappdata%\revanced-cli\revanced-curl\" > nul 2> nul
	rmdir /s /q "%localappdata%\revanced-cli\revanced-jdk\" > nul 2> nul
	rmdir /s /q "%localappdata%\revanced-cli\revanced-tools\" > nul 2> nul
	echo.
	goto integ_failed
)
:start
echo.
echo   1. YouTube (stock logo)
echo   2. YouTube (revanced logo)
echo   3. YouTube Music
echo   4. TikTok
echo   5. Twitch
echo   6. Twitter
echo.
echo   A. Custom
echo.
set choice=
set /p choice=Type the number or letter to fetch the corresponding app and hit enter. 
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto app_download
if '%choice%'=='2' goto app_download
if '%choice%'=='3' goto app_download
if '%choice%'=='4' goto app_download
if '%choice%'=='5' goto app_download
if '%choice%'=='6' goto app_download
if '%choice%'=='A' goto custom
echo "%choice%" is not valid, try again
echo.
goto start
:app_download
if '%choice%'=='1' "%CURL%" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1149347604904292472/com.google.android.youtube_18.32.39-1539440064.apk" --output .\YouTube-stock.apk 
if '%choice%'=='2' "%CURL%" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1149347604904292472/com.google.android.youtube_18.32.39-1539440064.apk" --output .\YouTube-stock.apk 
if '%choice%'=='3' "%CURL%" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1149346807814570064/com.google.android.apps.youtube.music_6.16.52-61652240.apk" --output .\YouTube-music-stock.apk
if '%choice%'=='4' "%CURL%" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1149348108535353484/com.zhiliaoapp.musically_30.8.4-2023008040.apk" --output .\TikTok-stock.apk
if '%choice%'=='5' "%CURL%" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1149766585272246364/tv.twitch.android.app_15.4.1-1504010.apk" --output .\Twitch-stock.apk
if '%choice%'=='6' "%CURL%" -L "https://cdn.discordapp.com/attachments/1149345921516187789/1150412361979658340/com.twitter.android_10.6.0-release.0-310060000.apk" --output .\Twitter-stock.apk
goto app_integ_check
:app_integ_check
if '%choice%'=='1' FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 'YouTube-stock.apk' | Select-Object -ExpandProperty Hash"`) DO ( SET APP_h=%%F ) && set "app_comp_h=342ab2dba5a099bf108a5cf21c3fbee37cdf09865a30cbc0140db7f81cb7164c "
if '%choice%'=='2' FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 'YouTube-stock.apk' | Select-Object -ExpandProperty Hash"`) DO ( SET APP_h=%%F ) && set "app_comp_h=342ab2dba5a099bf108a5cf21c3fbee37cdf09865a30cbc0140db7f81cb7164c "
if '%choice%'=='3' FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 'YouTube-music-stock.apk' | Select-Object -ExpandProperty Hash"`) DO ( SET APP_h=%%F ) && set "app_comp_h=cee5753b9290e1c6d8c3eac2dcf692dce7fc97f260c05f3d60eee04d28285e25 "
if '%choice%'=='4' FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 'TikTok-stock.apk' | Select-Object -ExpandProperty Hash"`) DO ( SET APP_h=%%F ) && set "app_comp_h=f0b5834a56d3e8a3f2fd005f9a2d7d6da4cd8b8ff558258467296a8666c83144 "
if '%choice%'=='5' FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 'Twitch-stock.apk' | Select-Object -ExpandProperty Hash"`) DO ( SET APP_h=%%F ) && set "app_comp_h=beb6f68c7003b6d168f8d5368a878c988569c3c70fbf0e30abb9078d4e47c982 "
if '%choice%'=='6' FOR /F "tokens=* USEBACKQ" %%F IN (`powershell -command "Get-FileHash -Algorithm SHA256 'Twitter-stock.apk' | Select-Object -ExpandProperty Hash"`) DO ( SET APP_h=%%F ) && set "app_comp_h=7321513751e36fc2a044c6032edfd89ec9eb3ef72f9fd5c1a850d52d708b3863 "
if /i "%APP_h%" == "%app_comp_h%" (
	echo  [92m File integrity validated! [0m
	echo.
	goto app_integ_check_passed
) else (
	if '%second_check%'=='1' goto download_abort
	set second_check=1
	echo  [93m File integrity damaged... Something must've become corrupted during the download or curl had some issue... [0m
	echo  Falling back to Invoke WebRequest... This might take a bit longer and doesn't give a nice status indication for the download.
	echo.
	if '%choice%'=='1' powershell -command "Invoke-WebRequest 'https://cdn.discordapp.com/attachments/1149345921516187789/1149347604904292472/com.google.android.youtube_18.32.39-1539440064.apk' -OutFile '.\YouTube-stock.apk'"
	if '%choice%'=='2' powershell -command "Invoke-WebRequest 'https://cdn.discordapp.com/attachments/1149345921516187789/1149347604904292472/com.google.android.youtube_18.32.39-1539440064.apk' -OutFile '.\YouTube-stock.apk'"
	if '%choice%'=='3' powershell -command "Invoke-WebRequest 'https://cdn.discordapp.com/attachments/1149345921516187789/1149346807814570064/com.google.android.apps.youtube.music_6.16.52-61652240.apk' -OutFile '.\YouTube-music-stock.apk'"
	if '%choice%'=='4' powershell -command "Invoke-WebRequest 'https://cdn.discordapp.com/attachments/1149345921516187789/1149348108535353484/com.zhiliaoapp.musically_30.8.4-2023008040.apk' -OutFile '.\TikTok-stock.apk'"
	if '%choice%'=='5' powershell -command "Invoke-WebRequest 'https://cdn.discordapp.com/attachments/1149345921516187789/1149766585272246364/tv.twitch.android.app_15.4.1-1504010.apk' -OutFile '.\Twitch-stock.apk'"
	if '%choice%'=='6' powershell -command "Invoke-WebRequest 'https://cdn.discordapp.com/attachments/1149345921516187789/1150412361979658340/com.twitter.android_10.6.0-release.0-310060000.apk' -OutFile '.\Twitter-stock.apk'"
	goto app_integ_check
)
:app_integ_check_passed
if '%choice%'=='1' "%JDK%" -jar "%CLI%" patch YouTube-stock.apk -b "%PATCHES%" -m "%INTEGRATIONS%" --keystore "%KEYSTORE%\PATCHED_YouTube.keystore" -o PATCHED_YouTube_18.32.39.apk
if '%choice%'=='2' "%JDK%" -jar "%CLI%" patch YouTube-stock.apk -b "%PATCHES%" -m "%INTEGRATIONS%" --keystore "%KEYSTORE%\PATCHED_YouTube.keystore" -i "custom branding" -o PATCHED_YouTube.apk
if '%choice%'=='3' "%JDK%" -jar "%CLI%" patch YouTube-music-stock.apk -b "%PATCHES%" -m "%INTEGRATIONS%" --keystore "%KEYSTORE%\PATCHED_YouTube_Music.keystore" -o PATCHED_YouTube_Music.apk
if '%choice%'=='4' "%JDK%" -jar "%CLI%" patch TikTok-stock.apk -b "%PATCHES%" -m "%INTEGRATIONS%" -i "Sim spoof" --keystore "%KEYSTORE%\PATCHED_TikTok.keystore" -o PATCHED_TikTok.apk
if '%choice%'=='5' "%JDK%" -jar "%CLI%" patch Twitch-stock.apk -b "%PATCHES%" -m "%INTEGRATIONS%" --keystore "%KEYSTORE%\PATCHED_Twitch.keystore" -o PATCHED_Twitch.apk
if '%choice%'=='6' "%JDK%" -jar "%CLI%" patch Twitter-stock.apk -b "%PATCHES%" -m "%INTEGRATIONS%" --keystore "%KEYSTORE%\PATCHED_Twitter.keystore" -o PATCHED_Twitter.apk
goto end
:download_abort
echo  [91m The base APKs could not be downloaded... Is the Discord CDN down? Open this script in an editor and check if you can download the APKs directly. [0m
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
if '%choice%'=='1' goto microG
if '%choice%'=='2' goto microG
if '%choice%'=='3' goto microG
if '%choice%'=='4' goto end_end
if '%choice%'=='5' goto end_end
if '%choice%'=='6' goto end_end
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
echo  bat Version 1.21
echo.
echo  Backups, keystore and supporting files can be found in AppData\Local\revanced-cli
echo.
echo  Pressing any key will close this window.
echo.
pause
