import 'package:dio/dio.dart';
import 'package:example/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monitor_sdk/flutter_monitor_sdk.dart';
import 'detail_page.dart';

// 创建一个全局的Dio实例，并添加我们的拦截器
final dio = Dio()..interceptors.add(FlutterMonitorSDK.dioInterceptor);

void main() async {
  // 记录启动时间
  final appStartTime = DateTime.now();

  // 确保Flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化监控SDK
  await FlutterMonitorSDK.init(
    config: MonitorConfig(
      // 重要：将IP地址改为你电脑的局域网IP，不要用localhost或127.0.0.1
      // 在Mac/Linux上用 ifconfig, 在Windows上用 ipconfig 查看
      serverUrl: 'http://192.168.100.85:3000/report',
      appKey: 'your_app_key_123',
      enablePeriodicReporting: false, // 明确开启定时上报
      periodicReportDuration: const Duration(seconds: 15), // 设置为15秒
      batchReportSize: 5,
    ),
    appStartTime: appStartTime,
  );

  // 运行App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Monitor Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 注入路由观察者
      navigatorObservers: [
        FlutterMonitorSDK.routeObserver
      ],
      routes: {
        '/': (context) => HomePage(dio: dio),
        '/detail': (context) => const DetailPage(),
      },
      initialRoute: '/',
    );
  }
}
