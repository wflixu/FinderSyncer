#!/usr/bin/env bash

APP_NAME="FinderSyncer"
DMG_FILE_NAME="Build/${APP_NAME}-Installer.dmg"
VOLUME_NAME="${APP_NAME} Installer"
SOURCE_FOLDER_PATH="Build/${APP_NAME}.app"


test -f "${DMG_FILE_NAME}" && rm "${DMG_FILE_NAME}"

# Create the DMG
create-dmg \
  --volname "${VOLUME_NAME}" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 200 190 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 600 185 \
  "${DMG_FILE_NAME}" \
  "${SOURCE_FOLDER_PATH}"