// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'dart:io';

// class NetworkController extends GetxController {
//   final Connectivity _connectivity = Connectivity();

//   var connectivityStatus = ConnectivityResult.none.obs;
//   var isConnectionPoor = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     // Listen to connectivity changes and call _updateConnectionStatus with the result.
//     _connectivity.onConnectivityChanged
//         .listen((List<ConnectivityResult> results) {
//       if (results.isNotEmpty) {
//         _updateConnectionStatus(results.first);
//       }
//     });
//   }

//   @override
//   void onClose() {
//     super.onClose();
//   }

//   void _updateConnectionStatus(ConnectivityResult connectivityResult) async {
//     connectivityStatus.value = connectivityResult;
//     if (connectivityResult == ConnectivityResult.none) {
//       _showSnackbar(
//         message: 'PLEASE CONNECT TO THE INTERNET',
//         backgroundColor: Colors.red[400]!,
//         icon: Icons.wifi_off,
//       );
//     } else {
//       isConnectionPoor.value = await _isConnectionPoor();
//       if (isConnectionPoor.value) {
//         _showSnackbar(
//           message: 'POOR INTERNET CONNECTION',
//           backgroundColor: Colors.orange[400]!,
//           icon: Icons.signal_cellular_connected_no_internet_4_bar,
//         );
//       } else {
//         if (Get.isSnackbarOpen) {
//           Get.closeCurrentSnackbar();
//         }
//       }
//     }
//   }

//   Future<bool> _isConnectionPoor() async {
//     const int thresholdSpeedKbps = 6; // 6 KBps
//     const int testSize = 1024; // 1 KB test size
//     const int timeout = 5; // 5 seconds timeout
//     try {
//       final stopwatch = Stopwatch()..start();
//       final socket = await Socket.connect('google.com', 80,
//           timeout: Duration(seconds: timeout));
//       stopwatch.stop();

//       socket.destroy();

//       // Calculate speed in KBps
//       final speedKbps = (testSize / stopwatch.elapsedMilliseconds) * 1000;

//       // Check if speed is less than threshold
//       return speedKbps < thresholdSpeedKbps;
//     } catch (_) {
//       return true;
//     }
//   }

//   // void _showSnackbar({required String message, required Color backgroundColor, required IconData icon}) {
//   //   if (Get.isSnackbarOpen) {
//   //     Get.closeCurrentSnackbar();

//   //   }

//   //   Get.rawSnackbar(
//   //     messageText: Text(
//   //       message,
//   //       style: const TextStyle(
//   //         color: Colors.white,
//   //         fontSize: 14,
//   //       ),
//   //     ),
//   //     isDismissible: false,
//   //     duration: const Duration(days: 1),
//   //     backgroundColor: backgroundColor,
//   //     icon: Icon(icon, color: Colors.white, size: 35,),
//   //     margin: EdgeInsets.zero,
//   //     snackStyle: SnackStyle.GROUNDED,
//   //   );
//   // }

//   void _showSnackbar(
//       {required String message,
//       required Color backgroundColor,
//       required IconData icon}) {
//     if (Get.isSnackbarOpen) {
//       Get.closeCurrentSnackbar();
//     }

//     Get.rawSnackbar(
//       messageText: Text(
//         message,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 14,
//         ),
//       ),
//       isDismissible: false,
//       duration: const Duration(days: 1),
//       backgroundColor: backgroundColor,
//       icon: Icon(
//         icon,
//         color: Colors.white,
//         size: 35,
//       ),
//       margin: const EdgeInsets.only(top: 90, left: 60),
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
//       borderRadius: 10,
//       snackStyle: SnackStyle.FLOATING,
//       snackPosition: SnackPosition.TOP,
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();

  var connectivityStatus = ConnectivityResult.none.obs;
  var isConnectionPoor = false.obs;
  Timer? _blinkTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }



  @override
  void onClose() {
    _blinkTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  void _updateConnectionStatus(ConnectivityResult connectivityResult) async {
    connectivityStatus.value = connectivityResult;

    if (connectivityResult == ConnectivityResult.none) {
      _startBlinkingSnackbar(
        message: '        PLEASE CONNECT TO THE INTERNET',
        backgroundColor: Colors.red[400]!,
        icon:    Icons.wifi_off,
      );
    } else {
      isConnectionPoor.value = await _isConnectionPoor();
      if (isConnectionPoor.value) {
        _startBlinkingSnackbar(
          message: '        POOR INTERNET CONNECTION',
          backgroundColor: Colors.orange[400]!,
          icon:    Icons.signal_cellular_connected_no_internet_4_bar,
        );
      } else {
        _stopBlinkingSnackbar();
      }
    }
  }

  Future<bool> _isConnectionPoor() async {
    const int thresholdSpeedKbps = 6;
    const int testSize = 1024; 
    const int timeout = 5; 
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect('google.com', 80, timeout: Duration(seconds: timeout));
      stopwatch.stop();

      socket.destroy();

      final speedKbps = (testSize / stopwatch.elapsedMilliseconds) * 1000;

      return speedKbps < thresholdSpeedKbps;
    } catch (_) {
      return true;
    }
  }

  void _startBlinkingSnackbar({required String message, required Color backgroundColor, required IconData icon}) {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _showSnackbar(message: message, backgroundColor: backgroundColor, icon: icon);
    });
  }

  void _stopBlinkingSnackbar() {
    _blinkTimer?.cancel();
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  void _showSnackbar({required String message, required Color backgroundColor, required IconData icon}) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      isDismissible: false,
      duration: const Duration(seconds: 3),
      backgroundColor: backgroundColor,
      icon: Icon(icon, color: Colors.white, size: 35,),
      margin: EdgeInsets.zero,
      snackStyle: SnackStyle.GROUNDED,
    );
  }
}