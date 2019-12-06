#!/bin/sh

# Set the app version number here
export VER=1.5

echo "**** About to build Hummingbird Firmware Burner version $VER for Mac ****"
echo
echo "Removing any old products..."

# Remove old products
rm -rfv Mac/supportFiles/Hummingbird\ Firmware\ Burner.app
rm -fv Mac/HummingbirdFirmwareBurner.dmg
rm -fv Mac/HummingbirdFirmwareBurner.pkg

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
codesign -f -s "Developer ID Application: Tom Lauwers" --entitlements Mac/supportFiles/entitlements.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/Java/avrdude_mac
codesign -f -s "Developer ID Application: Tom Lauwers" --entitlements Mac/supportFiles/entitlements.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/PlugIns/Java.runtime/Contents/Home/lib/jspawnhelper
codesign -f -s "Developer ID Application: Tom Lauwers" --entitlements Mac/supportFiles/entitlements.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/Contents/PlugIns/Java.runtime
codesign -f -s "Developer ID Application: Tom Lauwers" --entitlements Mac/supportFiles/entitlements.plist Mac/supportFiles/Hummingbird\ Firmware\ Burner.app/


echo
echo "**** Making the .dmg ****"

# Make a .dmg for manual distribution
appdmg Mac/supportFiles/appdmg.json Mac/HummingbirdFirmwareBurner.dmg
codesign -f -s "Developer ID Application: Tom Lauwers" Mac/HummingbirdFirmwareBurner.dmg

echo
echo "**** Making the .pkg ****"

# Make a .pkg for app store distribution (using the 'Transporter' developer tool)
# Requires a 'Developer ID Installer' for signing. Then you can use productsign or the --sign
# flag in productbuild
productbuild --component Mac/supportFiles/Hummingbird\ Firmware\ Burner.app /Applications Mac/HummingbirdFirmwareBurnerTmp.pkg
productsign --sign "3rd Party Mac Developer Installer: Tom Lauwers" Mac/HummingbirdFirmwareBurnerTmp.pkg Mac/HummingbirdFirmwareBurner.pkg 
rm -fv Mac/HummingbirdFirmwareBurnerTmp.pkg

echo
echo "**** Checking signatures..."
echo "... for the .app"
spctl -a -t exec -vv Mac/supportFiles/Hummingbird\ Firmware\ Burner.app
echo "... for the .dmg"
spctl -a -t install -vv Mac/HummingbirdFirmwareBurner.dmg
echo "... for the .pkg"
pkgutil --check-signature Mac/HummingbirdFirmwareBurner.pkg
