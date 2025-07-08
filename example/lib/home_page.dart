// example/lib/home_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monitor_sdk/flutter_monitor_sdk.dart';

class HomePage extends StatelessWidget {
  final Dio dio;
  const HomePage({super.key, required this.dio});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor SDK Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text("页面与性能监控", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/detail'),
                child: const Text('跳转详情页 (监控PV和页面加载)'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  try {
                    await dio.get('https://api.github.com/users/flutter');
                    _showSnackBar(context, 'API 调用成功! 请查看后端日志。');
                  } catch (e) {
                    _showSnackBar(context, 'API 调用失败: $e');
                  }
                },
                child: const Text('发起成功的API请求'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade200),
                onPressed: () async {
                  try {
                    await dio.get('https://api.github.com/non-existent-path');
                  } catch (e) {
                    _showSnackBar(context, 'API 调用失败 (预期)! 请查看后端日志。');
                  }
                },
                child: const Text('发起失败的API请求'),
              ),
              const SizedBox(height: 24),

              const Text("错误监控", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  dynamic a;
                  a.hello(); // 这会触发一个 NoSuchMethodError
                },
                child: const Text('触发 Dart 异步错误'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade200),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text("布局错误"),
                      content: Row(children: [Text("这段文字非常非常长，它会超出行的宽度限制，从而导致一个经典的布局溢出错误，这个错误会被FlutterError捕获。")]),
                    ),
                  );
                },
                child: const Text('触发 Flutter 布局错误'),
              ),
              const SizedBox(height: 24),

              const Text("行为与自定义事件监控", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),

              // 案例1: 使用 MonitoredGestureDetector 监控关键点击
              MonitoredGestureDetector(
                identifier: 'set-user-id-button',
                onTap: () {
                  FlutterMonitorSDK.instance.setUserId("user_007_bond");
                  _showSnackBar(context, '用户 ID 已设置为 user_007_bond');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('设置用户ID (监控点击)', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),

              // 案例2: 手动上报一个自定义事件
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade100),
                onPressed: () {
                  FlutterMonitorSDK.instance.reportEvent(
                    'user_share', // 自定义事件分类
                    { // 自定义事件的数据
                      'content_id': 'article_123',
                      'content_type': 'article',
                      'content_platform': 'wechat_timeline',
                    }
                  );
                  _showSnackBar(context, '已手动上报“分享”事件，请查看后端日志。');
                },
                child: const Text('手动上报“分享”事件'),
              ),
              const SizedBox(height: 10),

              // 案例3: 另一个 MonitoredGestureDetector 示例，包裹更复杂的组件
              MonitoredGestureDetector(
                identifier: 'subscribe-newsletter-click',
                onTap: () {
                  _showSnackBar(context, '“订阅”点击已记录！');
                },
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text("订阅我们的 Newsletter (监控点击)"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
