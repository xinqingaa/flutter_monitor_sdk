import 'package:dio/dio.dart';
import 'package:example/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monitor_sdk/flutter_monitor_sdk.dart';
import 'detail_page.dart';
import 'package:logger/logger.dart';

// 模拟用户自己的日志系统
final myAppLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

// 这是用户为了适配 SDK 而创建的处理函数
void handleMonitorEvent(Map<String, dynamic> event) {
  final category = event['category'];
  final data = event['data'];

  // 用户可以根据事件类型，调用自己日志库的不同方法
  if (category == 'error') {
    myAppLogger.e(
      "Flutter Monitor SDK Error Captured",
      error: data['error'],
      stackTrace: StackTrace.fromString(data['stackTrace'] ?? ''),
    );
  } else {
    myAppLogger.i("Flutter Monitor SDK Event: $category", error: data);
  }
}

// 创建一个全局的Dio实例，并添加我们的拦截器
final dio = Dio()..interceptors.add(FlutterMonitorSDK.dioInterceptor);

void main() async {
  // 记录启动时间
  final appStartTime = DateTime.now();

  // 确保Flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

  final List<MonitorOutput> monitorOutputs = [];

  // 默认日志输出
  if (kDebugMode) {
    monitorOutputs.add(LogMonitorOutput());
  }

  // 自定义日志系统输出
  // if (kDebugMode) {
  //   monitorOutputs.add(
  //     CustomLogOutput(onLog: handleMonitorEvent),
  //   );
  // }

  // 配置服务端上报
  // monitorOutputs.add(
  //   HttpOutput(
  //     serverUrl: 'http://192.168.100.85:3000/report',
  //     enablePeriodicReporting: false, // 明确开启定时上报
  //     periodicReportDuration: const Duration(seconds: 15), // 设置为15秒
  //     batchReportSize: 5,
  //   ),
  // );

  // 4. 使用这个列表来创建 MonitorConfig
  final monitorConfig = MonitorConfig(
    appKey: 'APP_KEY',
    outputs: monitorOutputs, // 传入配置好的输出器
    enableJankMonitor:false // 关闭ui卡顿监测
  );


  // 初始化监控SDK
  await FlutterMonitorSDK.init(
    config:monitorConfig,
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
