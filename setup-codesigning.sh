#!/bin/bash

# Code signing setup script for iPowerMenu
set -e

echo "Available code signing identities:"
security find-identity -v -p codesigning

echo ""
echo "For distribution, you'll need a 'Developer ID Application' certificate."
echo "Current certificate found is for development only."
echo ""
echo "To get a Developer ID Application certificate:"
echo "1. Go to https://developer.apple.com/account/resources/certificates/list"
echo "2. Click '+' to create a new certificate"
echo "3. Select 'Developer ID Application' under 'Production'"
echo "4. Follow the instructions to create and download the certificate"
echo "5. Double-click the downloaded certificate to install it in Keychain"
echo ""
echo "Once you have the Developer ID Application certificate, update the DEVELOPER_ID variable in build-app.sh"
echo "Example: export DEVELOPER_ID='Developer ID Application: Your Name (TEAMID)'"
echo ""

# Check for Developer ID Application certificate specifically
DEV_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d '"' -f 2 || true)

if [ -n "$DEV_ID" ]; then
    echo "Found Developer ID Application certificate: $DEV_ID"
    echo "You can use this for distribution by setting:"
    echo "export DEVELOPER_ID='$DEV_ID'"
else
    echo "No Developer ID Application certificate found for distribution."
    echo "The current Apple Development certificate is only for development/testing."
fi