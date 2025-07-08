import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monitor_sdk/flutter_monitor_sdk.dart';

class HomePage extends StatelessWidget {
  final Dio dio;
  const HomePage({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor SDK Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 演示行为监控 (PV/PageLoad)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/detail'),
                child: const Text('Go to Detail Page (Track PV)'),
              ),
              const SizedBox(height: 20),

              // 演示错误监控
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  dynamic a;
                  a.hello(); // 这会触发一个 NoSuchMethodError
                },
                child: const Text('Trigger Dart Error'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  // 触发一个布局溢出错误
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text("Layout Error"),
                      content: Row(children: [Text("This text is too long for the row and will cause an overflow error.This text is too long for the row and will cause an overflow error.This text is too long for the row and will cause an overflow error.")]),
                    ),
                  );
                },
                child: const Text('Trigger Flutter Layout Error'),
              ),
              const SizedBox(height: 20),

              // 演示性能监控 (API)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  try {
                    await dio.get('https://api.github.com/users/flutter');
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API call successful! Check server log.'))
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('API call failed: $e'))
                    );
                  }
                },
                child: const Text('Make Successful API Call'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  try {
                    await dio.get('https://api.github.com/non-existent-path');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API call failed as expected! Check server log.'))
                    );
                  }
                },
                child: const Text('Make Failed API Call'),
              ),
              const SizedBox(height: 20),

              // 演示行为监控 (Click)
              MonitoredGestureDetector(
                identifier: 'set-user-id-button',
                onTap: () {
                  FlutterMonitorSDK.instance.setUserId("user_007");
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID set to user_007. Future reports will include it.'))
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Set UserID (Track Click)', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
