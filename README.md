# Flutter Monitor SDK

一个为 Flutter 应用设计的、轻量级且功能全面的前端监控 SDK。它可以帮助开发者轻松地收集和上报应用中的**错误**、**性能指标**和**用户行为**数据，从而快速定位问题、优化体验。

## ✨ 设计理念

本 SDK 的设计遵循以下核心原则：

*   **非侵入式 (Non-intrusive)**: 只需在应用入口处进行一次初始化，其余监控逻辑对业务代码的侵入极小。例如，错误监控是全自动的，API 监控只需添加一个拦截器。
*   **高性能 (High-Performance)**: 所有监控数据的收集和上报都在异步环境中进行，不会阻塞 UI 线程。采用批量上报策略，有效减少网络请求数量，降低客户端和服务器的压力。
*   **高可扩展 (Extensible)**: SDK 采用模块化设计，将错误、性能、行为监控分离。未来可以轻松添加新的监控模块（如卡顿监控、内存监控等）。
*   **易于使用 (Easy to Use)**: 提供清晰、简洁的 API。初始化配置简单明了，并为关键功能（如点击监控）提供了便捷的 Widget。

## 核心功能

*   **错误监控**: 自动捕获 Flutter 框架层和 Dart 层的未处理异常。
*   **性能监控**:
    *   App 启动耗时
    *   页面加载（渲染）耗时
    *   网络 API 请求性能（成功率、耗时、状态码 ，支持 Dio 和原生 http 包）
    *   UI 卡顿监控 (基于连续慢帧序列的智能检测)
*   **用户行为监控**:
    *   页面浏览（PV）
    *   页面停留时长
    *   关键元素点击（UV ， 通过 MonitoredGestureDetector 手动埋点）
*   **灵活的上报策略**: 支持定时、定量批量上报，并在 App退出时进行数据抢救，确保数据不丢失。
*   **丰富的通用信息**: 每条上报数据都会自动附加设备信息、用户信息、平台、App Key 等通用字段。

## 监控原理详解

### 错误监控 (Error Monitoring)

SDK 通过监听两个 Flutter 核心的错误回调来捕获全局异常：

1.  **`FlutterError.onError`**: 用于捕获 Flutter 框架在构建（build）、布局（layout）、绘制（paint）等阶段抛出的错误。最常见的例子是布局溢出（Overflow Error）。
2.  **`PlatformDispatcher.instance.onError`**: 用于捕获更底层的 Dart Isolate 错误。这包括同步代码中的异常和异步代码（如 `Future`、`async/await`）中未被 `try-catch` 的异常。

当捕获到错误时，SDK 会收集错误的类型、信息、堆栈、发生的库等信息，并将其格式化后移交上报。

### 性能监控 (Performance Monitoring)

*   **App 启动耗时**: 在 `main()` 函数开始时记录一个时间戳 `appStartTime`。SDK 初始化后，通过 `WidgetsBinding.instance.addPostFrameCallback` 监听第一帧渲染完成的事件，两个时间点相减即为 App 的启动耗时。

* **UI 卡顿监控**: SDK 并非简单地监控单帧超时，而是采用更科学的连续慢帧序列检测机制。
    1. 根据设备刷新率计算出单帧的预算时间（如 16.7ms）。
    2. 当连续多帧（可配置，如3帧）的耗时都超过了预算时间的某个倍数（如2倍），SDK 才认为发生了一次用户可感知的卡顿。
    3. 此时，SDK 会将这次连续卡顿聚合成一条上报事件，包含卡顿的帧数、最大耗时、平均耗时等丰富信息，避免了日志风暴。

*   **页面加载/渲染耗时**:
    1.  通过注入一个自定义的 `RouteObserver`，在 `didPush` 方法被调用时记录页面 `push` 的时间。
    2.  在目标页面的 `initState` 中，通过 `WidgetsBinding.instance.addPostFrameCallback` 监听该页面第一帧渲染完成。
    3.  在回调中，用当前时间减去 `push` 时记录的时间，得到页面的加载耗时。

*   **API 请求监控**:
    *   `Dio` 库 提供一个 `MonitorDioInterceptor`
    *   `http`: 提供一个 `MonitoredHttpClient` 装饰器类
    *   在 `onRequest` 中记录请求开始时间。
    *   在 `onResponse`（成功）或 `onError`（失败）中，计算总耗时，并收集 URL、方法、状态码、响应数据等信息进行上报。

### 用户行为监控 (User Behavior Monitoring)

*   **页面浏览 (PV)**: `RouteObserver` 的 `didPush` 方法每次被调用，都意味着一次页面浏览。SDK 在此时会上报一个 `pv` 事件。

*   **页面停留时长**: `RouteObserver` 在 `didPush` 时记录页面和进入时间，在 `didPop` 时找到对应的记录，计算时间差，从而得到页面的停留时长。

*   **控件点击 (Click Events)**: SDK 提供了一个 `MonitoredGestureDetector` Widget。你只需用它包裹需要监控点击的普通 Widget，并提供一个唯一的 `identifier` 即可。它的 `onTap` 回调会自动触发一次点击事件上报。

## 上报策略 (Reporting Strategy)

为了避免频繁的网络请求，SDK 采用了**队列 + 批量上报**的策略。

1.  **数据入队**: 所有监控器捕获的事件，在经过数据丰富（附加通用字段）后，都会被添加到一个内部的事件队列 `_eventQueue` 中。
2.  **触发上报**: 以下三种情况会触发上报（`flush`）操作，将队列中的所有事件一次性发送给服务器：
    *   **定时上报**: SDK 内部有一个定时器，周期性地检查并上报队列（默认20秒，可配置）。
    *   **定量上报**: 当队列中的事件数量达到设定的阈值时，立即上报（默认10条，可配置）。
    *   **App 退出时上报**: 监听 App 的生命周期，当 App 进入后台或即将被关闭时，立即上报队列中所有剩余的数据，防止丢失。

## 如何使用

### 1. 安装

将本 SDK 上传到你的私有 Git 仓库（如 Gitee 或 GitHub）。然后在你的 Flutter 项目的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter_monitor_sdk:
    git:
      url: https://gitee.com/your_username/flutter_monitor_sdk.git # 替换为你的仓库地址
      ref: v0.0.1 # 使用 tag 来锁定版本
  # 本 SDK 需要以下对等依赖。请确保它们也存在于你的 dependencies 中
  dependencies:
  http: ^1.2.1
  dio: ^5.4.3+1
  device_info_plus: ^11.2.0
```

然后运行 `flutter pub get`。

### 2. 初始化

在你的 `main.dart` 文件的 `main` 函数中进行初始化。这是使用 SDK 的唯一入口点。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_monitor_sdk/flutter_monitor_sdk.dart';
// 注意：在你的业务项目中，不应该直接导入 src 下的文件。
// 这里是为了注入 navigatorObservers，所以需要访问 MonitorBinding。
// 在更完善的版本中，可以考虑将 routeObserver 暴露在顶层 API。
import 'package:flutter_monitor_sdk/src/core/monitor_binding.dart'; 
import 'package:dio/dio.dart'; // 如果使用API监控

// 如果使用API监控，创建Dio实例并添加拦截器
final dio = Dio()..interceptors.add(MonitorDioInterceptor(MonitorBinding.instance.reporter));

void main() async {
  // 1. 记录启动时间
  final appStartTime = DateTime.now();

  // 2. 确保Flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 初始化监控SDK
  await FlutterMonitorSDK.init(
    config: MonitorConfig(
      serverUrl: 'http://your-server.com/report', // 你的上报服务器地址
      appKey: 'your_app_key_123',
      
      // 可选配置
      enablePeriodicReporting: true, // 是否开启定时上报
      periodicReportDuration: const Duration(seconds: 30), // 定时上报间隔
      batchReportSize: 20, // 批量上报阈值
    ),
    appStartTime: appStartTime,
  );

  // 4. 运行App
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      // 5. 注入路由观察者以实现PV和页面性能监控
      navigatorObservers: [
        MonitorBinding.instance.performanceMonitor.routeObserver
      ],
      // ...
    );
  }
}
```

### 3. API 使用

*   **监控点击事件**:
    ```dart
    import 'package:flutter_monitor_sdk/flutter_monitor_sdk.dart';

    MonitoredGestureDetector(
      identifier: 'confirm-payment-button', // 为此点击事件设置一个唯一标识
      onTap: () {
        // 你的业务逻辑
      },
      child: Text('确认支付'),
    )
    ```

*   **设置用户信息**:
    在用户登录后，可以设置用户ID，之后的所有上报数据都会带上此ID。
    ```dart
    FlutterMonitorSDK.instance.setUserId("user_abc_123");
    ```

*   **手动上报自定义事件**:
    ```dart
    FlutterMonitorSDK.instance.reportEvent(
      'custom_event', // 事件分类
      { // 自定义事件数据
        'action': 'share',
        'platform': 'wechat',
      }
    );
    ```

## 数据结构示例

所有数据最终都会被打包成一个 JSON 对象发送到服务器，结构如下：

```json
{
  "events": [
    {
      "category": "error",
      "data": {
        "type": "dart_error",
        "error": "NoSuchMethodError: The method 'hello' was called on null.",
        "stack": "..."
      },
      "timestamp": "2025-07-09T12:30:00.123Z",
      "appKey": "your_app_key_123",
      "userId": "user_abc_123",
      "customData": null,
      "platform": "android",
      "deviceInfo": {
        "device": "sdk_gphone64_x86_64",
        "model": "sdk_gphone64_x86_64",
        "version": "12"
      }
    }
  ]
}
```

## 配套后端服务（示例）

本 SDK 需要一个后端服务来接收上报的数据。你可以使用以下简单的 Node.js + Express 服务器进行测试和验证。

1.  **`package.json`**:
    ```json
    {
      "name": "mock_server",
      "version": "1.0.0",
      "main": "server.js",
      "scripts": { "start": "node server.js" },
      "dependencies": {
        "body-parser": "^1.20.2",
        "cors": "^2.8.5",
        "express": "^4.19.2"
      }
    }
    ```

2.  **`server.js`**:
    ```javascript
    const express = require('express');
    const bodyParser = require('body-parser');
    const cors = require('cors');

    const app = express();
    const port = 3000;

    app.use(cors());
    app.use(bodyParser.json({ limit: '10mb' }));

    app.post('/report', (req, res) => {
      console.log('--- ✅ 收到上报数据 ---');
      console.log('上报时间:', new Date().toISOString());
      console.log('上报内容:', JSON.stringify(req.body, null, 2));
      console.log('-----------------------\n');
      
      res.status(200).send({ message: 'Report received' });
    });

    app.listen(port, '0.0.0.0', () => {
      console.log(`模拟服务器已启动，监听在 http://localhost:${port}`);
    });
    ```
    运行 `npm install && npm start` 即可启动。

## 路线图 (Roadmap)

未来计划为 SDK 添加更多功能，包括：

*   [ ] **UI 卡顿监控**: 监测并上报 UI 线程的卡顿事件。
*   [ ] **内存泄露监控**: 辅助开发者发现潜在的内存泄露问题。
*   [ ] **离线缓存**: 在无网络环境下，将数据缓存到本地存储，待网络恢复后重新上报。
*   [ ] **更广泛的库支持**: 提供对原生 `http` 包的监控支持。
*   [ ] **数据可视化面板**: 开发一个简单的前端页面，用于展示和筛选上报的数据。

## 许可证 (License)

本 SDK 采用 [MIT](https://opensource.org/licenses/MIT) 许可证。
