# iOS Setup Instructions

This project uses `receive_sharing_intent` to handle shared text and URLs from other apps.

## Share Extension Limitation
To support receiving text/urls via the system Share Sheet (e.g., highlighting text in Safari and tapping "Share"), iOS requires a **Share Extension**. This involves creating a separate build target in Xcode, which cannot be automated via text-based file editing tools in this environment.

## Current Configuration
The current setup includes:
1. `Info.plist` configuration for `CFBundleURLTypes`. This allows the app to be opened via custom URL schemes (e.g., `ShareMedia://`).
2. Usage descriptions for Calendar access.

## Manual Steps Required for Full iOS Support
If you are building this project in Xcode, follow the [official receive_sharing_intent setup guide](https://pub.dev/packages/receive_sharing_intent) to add a Share Extension:
1. File -> New -> Target -> Share Extension.
2. Ensure the deployment target matches the Runner.
3. Update `Info.plist` of the extension as per the plugin documentation.
4. Add the App Group capability to both the Runner and the Extension to allow data sharing.
