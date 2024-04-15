# iOS SAMPLE

# To launch and utilize a sample with Pushwoosh iOS SDK integration, clone or download the repository archive.

 <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen2.png" alt="Alt text" width="300"> <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen1.png" alt="Alt text" width="300">
 
### 1. Update the dependency to the latest SDK version (File -> Packages -> Update To Latest Package Version).
 <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/UpdateDependencies.png" alt="Alt text" width="700">
 
### 2. Replace the Bundle Identifier in the main target and in the Notification Service Extension with yours.
   <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleID.png" alt="Alt text" width="700">
   <img src="https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleIDExtension.png" alt="Alt text" width="700">
   
### 3. Add your group to App Groups, tied to your Bundle ID.
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
