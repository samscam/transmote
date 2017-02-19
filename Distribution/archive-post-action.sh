#!/bin/sh
osascript -e 'display notification "Starting DMG archive" with title "Archiving"'

## This is a post-action when archiving
exec > "/Users/sam/Desktop/archive.log" 2>&1

PRODUCT_INFO_PLIST_PATH="${ARCHIVE_PRODUCTS_PATH}/Applications/${TARGET_NAME}.app/Contents/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PRODUCT_INFO_PLIST_PATH}")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PRODUCT_INFO_PLIST_PATH}")

unset XCODE_DEVELOPER_DIR_PATH

OUTPUT_DIR="${SOURCE_ROOT}/Distribution/Archives/${TARGET_NAME}_${VERSION}"
mkdir -p "$OUTPUT_DIR"

exec > "${OUTPUT_DIR}/archive.log" 2>&1

# Export the archive we just made
xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportPath "${OUTPUT_DIR}" -exportOptionsPlist "${SOURCE_ROOT}/Distribution/exportOptions.plist"

# Zip and copy .dSYM
cd "${ARCHIVE_DSYMS_PATH}/"
/usr/bin/zip -r "$OUTPUT_DIR/${TARGET_NAME}.dSYM.zip" "${TARGET_NAME}.app.dSYM"

cd "${SOURCE_ROOT}/Distribution"

# Create dmg
DMG_PATH="${OUTPUT_DIR}/${TARGET_NAME}-${VERSION}.dmg"
dmgcanvas "${SOURCE_ROOT}/Distribution/dmg_template.dmgCanvas" "${DMG_PATH}" -setFilePath "Transmote.app" "${OUTPUT_DIR}/${TARGET_NAME}.app"

./sparklething.py sparklething-config.json "${DMG_PATH}" -v "${VERSION}" "${OUTPUT_DIR}/appcast.xml" -vv

osascript -e 'display notification "Exporting DMG complete" with title "Archiving"'
