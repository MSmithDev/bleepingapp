/// @author Matthew Smith
/// @email Mattdsmith228@gmail.com
/// @file main.dart
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:go_router/go_router.dart';
import 'package:mockup/pages/config.dart';
import 'package:mockup/pages/provision.dart';
import 'package:mockup/pages/splash.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  static const title = 'Bleep';

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
      );

  final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Splash()),
      GoRoute(
        name: 'provision',
        path: '/provision',
        redirect: (state) {
          final isProvisioning = state.location == "/provision";
          final hasDevice = state.extra == null ? false : true;
          if (isProvisioning && !hasDevice) {
            return "/";
          } else {
            return null;
          }
        },
        pageBuilder: (context, state) {
          final device = state.extra as BluetoothDevice;
          return MaterialPage(
            key: state.pageKey,
            child: Provision(
              device: device,
            ),
          );
        },
      ),
      GoRoute(
        name: 'config',
        path: '/config',
        redirect: (state) {
          final isConfiguring = state.location == "/config";
          final hasDevice = state.extra == null ? false : true;
          if (isConfiguring && !hasDevice) {
            return "/";
          } else {
            return null;
          }
        },
        pageBuilder: (context, state) {
          final device = state.extra as BluetoothDevice;
          return MaterialPage(
            key: state.pageKey,
            //child: Config(), // temp
            child: Config(device: device),
          );
        },
      )
    ],
  );
}
