# iOS SAMPLE

# To launch and utilize a sample with Pushwoosh iOS SDK integration, clone or download the repository archive.

   ![Alt Dependencies](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen1.png) ![Alt](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screen2.png)

### 1. Update the dependency to the latest SDK version (File -> Packages -> Update To Latest Package Version).
   ![Alt Dependencies](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/Screenshot%202024-04-15%20at%2019.09.31.png)
### 2. Replace the Bundle Identifier in the main target and in the Notification Service Extension with yours.
   ![Alt Dependencies](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleID.png)
   ![Alt Dependencies](https://github.com/Pushwoosh/pushwoosh-ios-sample/blob/main/Screenshots/BundleIDExtension.png)
3. Add your group to App Groups, tied to your Bundle ID.
4. Add the group name to the info.plist of the main target and Notification Service Extension.
5. In the info.plist of the main project, add your Pushwoosh_APPID.
