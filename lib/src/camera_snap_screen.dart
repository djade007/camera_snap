import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_type.dart';

const _defaultPermissionMessage =
    'You need to grant this app permission to use your '
    'camera to complete this action.';

/// A screen to capture a user's picture using the front facing camera
/// and returns a temporary path to the picture.
///
/// Usage
/// ``` dart
/// final imagePath = await Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => CameraSnapScreen(),
///   ),
/// );
///
/// print(imagePath);
/// ```
class CameraSnapScreen extends StatefulWidget {
  /// Preferred camera type
  ///
  /// Defaults to the front facing camera.
  final CameraType cameraType;

  /// The widget to display at the Scaffold's appbar.
  final PreferredSizeWidget? appBar;

  /// The error message to display, when user declines camera permission.
  final String permissionErrorMessage;

  const CameraSnapScreen({
    Key? key,
    this.cameraType: CameraType.front,
    this.appBar,
    this.permissionErrorMessage: _defaultPermissionMessage,
  }) : super(key: key);

  @override
  _CameraSnapScreenState createState() {
    return _CameraSnapScreenState();
  }
}

class _CameraSnapScreenState extends State<CameraSnapScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  XFile? imageFile;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    _setUpCamera();
  }

  Future<void> _setUpCamera() async {
    try {
      setState(() {
        _loading = true;
      });

      final cameras = await availableCameras();

      final camera = cameras.where(
        (element) {
          if (widget.cameraType == CameraType.front) {
            return element.lensDirection == CameraLensDirection.front;
          }
          return element.lensDirection == CameraLensDirection.back;
        },
      );

      if (camera.isEmpty) {
        setState(() {
          _loading = false;
        });
        showInSnackBar(
          '${describeEnum(widget.cameraType)} facing camera '
          'not found on this device',
        );
        return;
      }

      onNewCameraSelected(camera.first);
    } catch (e) {
      showInSnackBar('Failed to set up camera');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar ?? _defaultAppbar(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color:
                      controller != null && controller!.value.isRecordingVideo
                          ? Colors.redAccent
                          : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
          _flashModeControlRowWidget(),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final cameraController = controller;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cameraController == null || !cameraController.value.isInitialized) {
      return TextButton(
        onPressed: _setUpCamera,
        child: Text(
          'Enable camera',
        ),
      );
    } else {
      return CameraPreview(
        controller!,
      );
    }
  }

  /// Display the different flash modes available
  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: Icon(Icons.flash_off),
              color: controller?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_auto),
              color: controller?.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.blue,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_on),
              color: controller?.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.blue,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Display the control bar with buttons to take pictures and toggle flash mode.
  Widget _captureControlRowWidget() {
    final cameraController = controller;

    return Stack(
      children: <Widget>[
        Center(
          child: IconButton(
            icon: const Icon(Icons.camera_alt),
            color: Colors.blue,
            onPressed:
                cameraController != null && cameraController.value.isInitialized
                    ? onTakePictureButtonPressed
                    : null,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(Icons.flash_on),
            color: Colors.blue,
            onPressed: controller != null ? onFlashModeButtonPressed : null,
          ),
        ),
      ],
    );
  }

  void showInSnackBar(String message) {
    if (message.contains('permission not granted')) {
      message = widget.permissionErrorMessage;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  /// Set up the selected camera.
  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    final cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    _loading = false;

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((XFile? file) {
      if (mounted) {
        setState(() {
          imageFile = file;
        });
        if (file != null) {
          Navigator.of(context).pop(file.path);
        }
      }
    });
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (controller == null) {
      return;
    }

    try {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        controller = null;
        return null;
      }
      await controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  AppBar _defaultAppbar() {
    return AppBar(
      elevation: 0.0,
      centerTitle: true,
      title: Text(
        "Take Picture",
        style: TextStyle(
          fontSize: 18.0,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          size: 15.0,
        ),
        color: Colors.black,
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    super.dispose();
  }
}

void logError(String code, String? message) {
  if (!kDebugMode) return;

  if (message != null) {
    print('Error: $code\nError Message: $message');
  } else {
    print('Error: $code');
  }
}
