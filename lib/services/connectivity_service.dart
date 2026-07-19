import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity connectivity =
      Connectivity();

  Stream<List<ConnectivityResult>>
      get stream =>
          connectivity.onConnectivityChanged;
}