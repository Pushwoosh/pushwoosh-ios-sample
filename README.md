# iOS SAMPLE

# To launch and utilize a sample with Pushwoosh iOS SDK integration, clone or download the repository archive.

 <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen2.png" alt="Alt text" width="300">
 <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen1.png" alt="Alt text" width="300">
 
### 1. Update the dependency to the latest SDK version (File -> Packages -> Update To Latest Package Version).
   ![Alt Dependencies](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screenshot%202024-04-15%20at%2019.09.31.png)

### 2. Replace the Bundle Identifier in the main target and in the Notification Service Extension with yours.
   ![Alt Main Target](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleID.png)
   ![Alt Service Extension](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleIDExtension.png)
### 3. Add your group to App Groups, tied to your Bundle ID.
   ![Alt](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/AppGroups.png)
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
