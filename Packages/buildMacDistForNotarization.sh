#!/bin/sh

# Build a disk image for Apple Notarization.

# Set the app version number here. Number must also be set in Info.plist
export VER=1.5.2

echo "**** About to build Hummingbird Firmware Burner version $VER for Mac Testing ****"
echo
echo "Removing any old products..."

# Remove old products
rm -rfv Mac/supportFiles/Hummingbird\ Firmware\ Burner.app
rm -fv Mac/HummingbirdFirmwareBurner.dmg

echo
echo "**** Making the .app ****"

# Make the .app
javapackager -deploy -native image -name "Hummingbird Firmware Burner" -Bicon=Mac/supportFiles/HummingbirdRoundOrange.icns -BappVersion=$VER -Bidentifier=com.birdbraintechnologies.HummingbirdFirmwareBurner -srcdir . -srcfiles HummingbirdFirmwareBurner.jar -outfile "Hummingbird Firmware Burner" -outdir Mac/supportFiles -v -appclass HummingbirdFirmwareBurner

# Copy extra files needed (that cannot be included automatically because of a bug in javapackager
/bin/cp  -R  Mac/appFiles/*  Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/Java/.
/bin/cp  -R  sharedResources/*  Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/Java/.
/bin/cp Mac/supportFiles/Info.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/.

# Sign the app again because of the changes
# Check syntax of the entitlements file with 'plutil entitlements.plist'
codesign -f -s "Developer ID Application: Tom Lauwers" --timestamp --entitlements Mac/supportFiles/entitlementsInherit.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/Java/avrdude_mac -vvvv
codesign -f -s "Developer ID Application: Tom Lauwers" --timestamp --entitlements Mac/supportFiles/entitlementsInherit.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/PlugIns/Java.runtime/Contents/Home/lib/jspawnhelper -vvvv
codesign -f -s "Developer ID Application: Tom Lauwers" --timestamp --entitlements Mac/supportFiles/entitlementsInherit.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/PlugIns/Java.runtime -vvvv
codesign -f -s "Developer ID Application: Tom Lauwers" --timestamp --entitlements Mac/supportFiles/entitlements.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/ -vvvv


echo
echo "**** Making the .dmg ****"

# Make a .dmg for manual distribution
appdmg Mac/supportFiles/appdmg.json Mac/HummingbirdFirmwareBurner.dmg
codesign -f -s "Developer ID Application: Tom Lauwers" --timestamp Mac/HummingbirdFirmwareBurner.dmg

echo
echo "**** Checking signatures..."
echo "... for the .app"
spctl -a -t exec -vv Mac/supportFiles/Hummingbird\ Firmware\ Burner.app
echo "... for the .dmg"
spctl -a -t install -vv Mac/HummingbirdFirmwareBurner.dmg

# Notarization process (see https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)
# When you are ready to upload for notification run (only if you have multiple versions of xcode):
# sudo xcode-select -s /path/to/Xcode10.app
#
# And then
# xcrun altool --notarize-app --primary-bundle-id "com.birdbraintechnologies.HummingbirdFirmwareBurner.dmg" --asc-provider N6XC9HC8PB --file  Mac/HummingbirdFirmwareBurner.dmg --username kristinalauwers@gmail.com --password "@keychain:AC_PASSWORD"
#
# You will receive an email when the process is finished. Also check with
# xcrun altool --notarization-history 0 -u kristinalauwers@gmail.com -p "@keychain:AC_PASSWORD"
# Get details with (where "Request_UUID" is the actual Request UUID 
# xcrun altool --notarization-info "Request_UUID" -u kristinalauwers@gmail.com -p "@keychain:AC_PASSWORD"
#
# Make sure to read the log file.
#
# Now, staple the ticket to the app
# xcrun stapler staple Mac/supportFiles/Hummingbird\ Firmware\ Burner.app
# and make a new dmg
