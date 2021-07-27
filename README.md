# Camera Snap Plugin

[![pub package](https://img.shields.io/pub/v/camera_snap.svg)](https://pub.dev/packages/camera_snap)

A Flutter plugin for iOS and Android to capture images from the camera without saving it to the gallery.

## Installation

First, add `camera_snap` as a [dependency in your pubspec.yaml file](https://flutter.dev/using-packages/).

### iOS

iOS 10.0 of higher is needed to use the camera plugin. If compiling for any version lower than 10.0 make sure to check
the iOS version before using the camera plugin. For example, using
the [device_info](https://pub.dev/packages/device_info) plugin.

Add two rows to the `ios/Runner/Info.plist`:

* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the key `Privacy - Microphone Usage Description` and a usage description.

Or in text format add the key:

```xml

<key>NSCameraUsageDescription</key>
<string>Can I use the camera please?</string>
<key>NSMicrophoneUsageDescription</key>
<string>Can I use the mic please?</string>
```

### Android

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```
minSdkVersion 21
```

### Usage

```dart
void takePicture() async {
  final imagePath = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          CameraSnapScreen(
              cameraType: CameraType.front,
              appBar: AppBar(title: 'Take Picture')
          ),
    ),
  );
  if (imagePath == null) {
    print('cancelled');
    return;
  }
  
  print(imagePath);
}
```
