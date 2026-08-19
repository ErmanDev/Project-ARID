import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityStatus {
  static bool isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  static Stream<bool> watch() {
    return Connectivity().onConnectivityChanged.map(isOnline);
  }

  static Future<bool> current() async {
    return isOnline(await Connectivity().checkConnectivity());
  }
}
