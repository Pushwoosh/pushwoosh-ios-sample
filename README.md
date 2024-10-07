# iOS SAMPLE 🍏

## To launch and utilize a sample with Pushwoosh iOS SDK integration, clone or download the repository archive.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/)

 <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen2.png" alt="Alt text" width="300"> <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen1.png" alt="Alt text" width="300">
 
### 1. In this project, we use the Pushwoosh iOS SDK as a submodule. To fetch the dependency, follow these steps:

### Adding Pushwoosh iOS SDK as a source code project

1.1 Navigate to the sample folder via the terminal and enter the following command:

```
git submodule update --init --recursive
```
1.2 You can check the status of the submodules to ensure they have been successfully fetched:

```
git submodule status
```

1.3 If you have already cloned the repository and want to update the submodules to the latest commits, you can use:

```
git submodule update --recursive --remote
```

### Adding Pushwoosh iOS SDK via Swift Package Manager

If you don't want to use a submodule, you can add the Pushwoosh iOS SDK as a dependency via Swift Package Manager.

1.1 Add Dependencies via Swift Package Manager. Use this link https://github.com/Pushwoosh/Pushwoosh-XCFramework

<img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/SPM.png" alt="Alt text" width="700">

 
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
