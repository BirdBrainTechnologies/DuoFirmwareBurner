@echo off
if [%1]==[] (
  echo Usage: CreateWinMsi 'signing password'
  goto :eof
)

:: Set the current app version
SET VER=1.5.3

cd Windows

SET FILESDIR=temp

echo ***** Copying the jar file...
mkdir %filesdir%
copy ..\..\out\artifacts\HummingbirdFirmwareBurner_jar\HummingbirdFirmwareBurner.jar %filesdir%\HummingbirdFirmwareBurner.jar

:: Make the app image separately so that the command line application can be copied in before the msi is made.
echo ***** Creating the app-image...
jpackage ^
  --type app-image ^
  --app-version %ver% ^
  --copyright "BirdBrain Technologies LLC" ^
  --description "Hummingbird Firmware Burner from BirdBrain Technologies" ^
  --name "Hummingbird Firmware Burner" ^
  --vendor "BirdBrain Technologies" ^
  --input %filesdir% ^
  --icon HummingbirdRoundOrange.ico ^
  --main-jar HummingbirdFirmwareBurner.jar ^
  --verbose ^
  --main-class HummingbirdFirmwareBurner
:: Additional useful flags:
:: * Have the app run in a console window (good for debugging) with
::  --win-console ^
::

echo ***** Copying additional files...
copy libs\* "Hummingbird Firmware Burner"

echo ***** Signing HummingbirdFirmwareBurner.jar and Hummingbird Firmware Burner.exe...
jarsigner -tsa http://timestamp.digicert.com -storetype pkcs12 -keystore BIRDBRAIN.pfx -storepass %1 "Hummingbird Firmware Burner\app\HummingbirdFirmwareBurner.jar" 73cfaf53eaee4153b44e02ca7b2a7e76
attrib -r "Hummingbird Firmware Burner\Hummingbird Firmware Burner.exe"
signtool sign /fd SHA256 /f BIRDBRAIN.pfx /p %1 "Hummingbird Firmware Burner\Hummingbird Firmware Burner.exe"
attrib +r "Hummingbird Firmware Burner\Hummingbird Firmware Burner.exe"

::goto :eof

:: Make msi
echo ***** Creating the .msi...
jpackage ^
  --type msi ^
  --app-version %ver% ^
  --copyright "BirdBrain Technologies LLC" ^
  --description "Hummingbird Firmware Burner from BirdBrain Technologies" ^
  --name "Hummingbird Firmware Burner" ^
  --vendor "BirdBrain Technologies" ^
  --app-image "Hummingbird Firmware Burner" ^
  --verbose ^
  --win-menu ^
  --win-shortcut
:: Additional useful flags:
:: * see copies of the temp files being used with
::  --temp tempFiles ^
::

echo ***** Signing the .msi...
signtool sign /d "Hummingbird Firmware Burner" /fd SHA256 /f BIRDBRAIN.pfx /p %1 "Hummingbird Firmware Burner-%ver%.msi"

:: Cleanup
echo ***** Cleaning up...
rmdir "Hummingbird Firmware Burner" /S /Q
rmdir %filesdir% /S /Q
cd ..\
echo ***** DONE!

:: NOTES:
::
:: If you need to find the alias of a new signing certificate, the command is
:: keytool -list -v -storetype pkcs12 -keystore BIRDBRAIN.pfx
::
:: To verify that the jar is signed, you can run
:: jarsigner -verify "BlueBird Connector\app\BlueBirdConnector.jar"
::
:: To capture a log of msi installation, you can install from command line:
:: msiexec /i "BlueBird Connector-3.0.msi" /L*V msiLog.log
