#!/bin/sh

PRODUCT_INFO_PLIST_PATH="${ARCHIVE_PRODUCTS_PATH}/Applications/${TARGET_NAME}.app/Contents/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PRODUCT_INFO_PLIST_PATH}")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PRODUCT_INFO_PLIST_PATH}")

unset XCODE_DEVELOPER_DIR_PATH

DATE=$(/bin/date +%Y%m%d%H%M%S)
OUTPUT_DIR="${SOURCE_ROOT}/Distribution/Archives/${TARGET_NAME}_${VERSION}"
mkdir -p "$OUTPUT_DIR"

exec > "${OUTPUT_DIR}/archive.log" 2>&1

# Export the archive we just made
xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportPath "${OUTPUT_DIR}" -exportOptionsPlist "${SOURCE_ROOT}/Distribution/exportOptions.plist"

# Zip and copy .dSYM
cd "${ARCHIVE_DSYMS_PATH}/"
/usr/bin/zip -r "$OUTPUT_DIR/${TARGET_NAME}.dSYM.zip" "${TARGET_NAME}.app.dSYM"

# Create dmg
dmgcanvas "${SOURCE_ROOT}/Distribution/dmg_template.dmgCanvas" "${OUTPUT_DIR}/${TARGET_NAME}-${VERSION}.dmg" -setFilePath "Transmote.app" "${OUTPUT_DIR}/${TARGET_NAME}.app" 

#/usr/local/bin/dropdmg "${ARCHIVE_PRODUCTS_PATH}/Applications/${TARGET_NAME}.app" --layout-folder "${SOURCE_ROOT}/DropDMG/Layout" --destination  "$OUTPUT_DIR"
# Zip and copy .app
#cd "${ARCHIVE_PRODUCTS_PATH}/Applications/"
#/usr/bin/zip -r -y "$OUTPUT_DIR/${TARGET_NAME}.app.zip" "${TARGET_NAME}.app"

osascript -e 'Exporting DMG complete" with title "Archiving"'
