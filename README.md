# iOS SAMPLE 🍏

## To launch and utilize a sample with Pushwoosh iOS SDK integration, clone or download the repository archive.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)

 <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen2.png" alt="Alt text" width="300"> <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen1.png" alt="Alt text" width="300">
 
### Project Settings

### 1. Pushwoosh Dependency

Pushwoosh framework is integrated into the project via Swift Package Manager. When loading the project, Xcode will fetch the latest version of the framework. If you want to change the framework version, go to the Package Dependencies tab and adjust the version there.
 
### 2. Replace the Bundle Identifier in the main target and in the Notification Service Extension with yours.
   <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleID.png" alt="Alt text" width="700">
   <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleIDExtension.png" alt="Alt text" width="700">
   
### 3. Add your Group Name to App Groups (Main Target and Notification Service Extension Target), tied to your Bundle ID.
   <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/AppGroups.png" alt="Alt text" width="700">
   
### 4. Add the group name to the info.plist of the main target and Notification Service Extension.

```
...
<key>PW_APP_GROUPS_NAME</key>
<string>group.com.example.demo_group</string>
...
```
### 5. In the info.plist of the main project, add your Pushwoosh_APPID.
```
...
<key>Pushwoosh_APPID</key>
<string>XXXXX-XXXXX</string>
...
```

### 6. In the info.plist of the main project, add your PW_API_TOKEN - the API key from the Pushwoosh control panel.

```
...
<key>PW_API_TOKEN</key>
<string>XXXXX</string>
...
```

## The guide for SDK integration is available on Pushwoosh [website](https://docs.pushwoosh.com/platform-docs/pushwoosh-sdk/ios-push-notifications/setting-up-pushwoosh-ios-sdk/swift-package-manager-setup).

Documentation:
https://github.com/Pushwoosh/pushwoosh-ios-sdk/tree/master/Documentation

Pushwoosh team
http://www.pushwoosh.com
