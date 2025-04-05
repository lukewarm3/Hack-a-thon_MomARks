# ARCore SDK for iOS

This pod contains the ARCore SDK for iOS.

## Getting Started

*   *Cloud Anchors Quickstart*:
    https://developers.google.com/ar/develop/ios/cloud-anchors/quickstart
*   *Augmented Faces Quickstart*:
    https://developers.google.com/ar/develop/ios/augmented-faces/quickstart
*   *Geospatial Quickstart*:
    https://developers.google.com/ar/develop/ios/geospatial/quickstart
*   *Reference*: https://developers.google.com/ar/reference/ios
*   *Code samples*: Sample apps are available for download at
    https://github.com/google-ar/arcore-ios-sdk/tree/master/Examples. Be sure to
    follow any instructions in README files.

## Installation

ARCore requires a deployment target that is >= 13.0. Also, you must be building
with at least version 15.0 of the iOS SDK. ARCore binaries no longer contain
bitcode, which is deprecated with Xcode 14, so if you are building with Xcode 13
then you must disable bitcode for your project. ARCore can alternatively be
installed via Swift Package Manager, see
https://developers.google.com/ar/develop/ios/enable-arcore for details.

### Using CocoaPods

To integrate ARCore SDK for iOS into your Xcode project using CocoaPods, specify
it in your `Podfile`:

```
target 'YOUR_APPLICATION_TARGET_NAME_HERE'
platform :ios, '13.0'
pod 'ARCore/SUBSPEC_NAME_HERE' ~> VERSION_HERE
```

Then, run the following command:

```
$ pod install
```

### Additional Steps

Before you can start using the ARCore Cloud Anchors API or the ARCore Geospatial
API, you will need to create a project in the
[Google Developer Console](https://console.developers.google.com/) and enable
the [ARCore API](https://console.cloud.google.com/apis/library/arcore).

## License and Terms of Service

By using the ARCore SDK for iOS you accept Google's **ARCore Additional Terms of
Service** at
[https://developers.google.com/ar/develop/terms](https://developers.google.com/ar/develop/terms)
