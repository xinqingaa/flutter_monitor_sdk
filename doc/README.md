# Flutter Monitor SDK 文档中心

## 📚 文档目录

### 🚀 快速开始
- [配置使用指南](CONFIG_USAGE_GUIDE.md) - 如何快速配置和使用SDK
- [配置优化总结](CONFIG_OPTIMIZATION_SUMMARY.md) - 配置系统的优化改进

### 🔧 技术原理
- [优化指南](OPTIMIZATION_GUIDE.md) - 核心算法和性能优化
- [设备性能等级说明](DEVICE_LEVEL_EXPLANATION.md) - 设备性能自动检测原理
- [性能测试指南](PERFORMANCE_TEST_GUIDE.md) - 如何进行性能测试和调试

### 👥 用户管理
- [用户管理指南](USER_MANAGEMENT_GUIDE.md) - 动态用户信息管理

## 🎯 核心特性

### 1. 智能卡顿检测
- **自适应阈值**：根据设备性能动态调整卡顿标准
- **抖动容忍**：允许设备正常抖动，只检测真正的连续卡顿
- **性能优化**：采样控制，减少对应用性能的影响

### 2. 全面监控覆盖
- **错误监控**：Flutter框架错误、Dart异常捕获
- **性能监控**：页面加载时间、路由切换性能
- **行为监控**：用户点击、页面访问统计
- **卡顿监控**：UI卡顿检测和分析

### 3. 灵活配置系统
- **极简配置**：只需要appKey即可开始使用
- **智能默认值**：合理的默认配置
- **动态更新**：运行时更新用户信息和自定义数据

### 4. 丰富的数据输出
- **多输出支持**：日志、HTTP、自定义输出
- **数据丰富**：自动附加设备信息、用户信息、应用信息
- **详细指标**：FPS、稳定性、百分位数分析

## 🚀 快速开始

```dart
// 1. 添加依赖
dependencies:
  flutter_monitor_sdk: ^1.0.0

// 2. 初始化SDK
await FlutterMonitorSDK.init(
  config: MonitorConfig.quick(appKey: 'YOUR_APP_KEY'),
  appStartTime: DateTime.now(),
);

// 3. 使用监控功能
// 自动监控，无需额外代码
```

## 📊 监控数据示例

```json
{
  "category": "jank_sequence",
  "data": {
    "jank_count": 4,
    "max_duration_ms": 45.2,
    "average_duration_ms": 38.7,
    "device_performance": {
      "fps": 59.5,
      "stability": 0.92,
      "device_level": "medium"
    }
  },
  "appInfo": {
    "appKey": "YOUR_APP_KEY",
    "appVersion": "1.0.0"
  },
  "userInfo": {
    "userId": "user_123",
    "userType": "premium"
  }
}
```

## 🔧 技术架构

```
FlutterMonitorSDK
├── 核心层 (Core)
│   ├── MonitorBinding - 单例绑定器
│   ├── MonitorConfig - 配置管理
│   └── Reporter - 数据上报器
├── 监控模块 (Modules)
│   ├── ErrorMonitor - 错误监控
│   ├── PerformanceMonitor - 性能监控
│   ├── BehaviorMonitor - 行为监控
│   └── JankMonitor - 卡顿监控
├── 输出层 (Outputs)
│   ├── LogMonitorOutput - 日志输出
│   ├── HttpOutput - HTTP输出
│   └── CustomLogOutput - 自定义输出
└── 工具层 (Utils)
    ├── MonitoredGestureDetector - 手势监控
    ├── MonitoredHttpClient - HTTP监控
    └── PerformanceUtils - 性能工具
```

## 🎯 最佳实践

1. **开发环境**：使用宽松配置，减少误报
2. **生产环境**：根据设备性能选择合适的配置
3. **用户管理**：及时更新用户信息，便于问题追踪
4. **性能监控**：关注FPS、稳定性等关键指标

## 📈 性能指标

- **FPS**：应保持在50+以上
- **稳定性**：应保持在0.7以上
- **P95帧时间**：应小于33ms
- **设备等级**：自动检测设备性能等级

## 🔍 故障排查

1. **没有监控数据**：检查配置和初始化
2. **数据过多**：调整采样率和阈值
3. **性能影响**：使用宽松配置
4. **用户信息**：确保正确设置用户ID

## 📞 技术支持

如有问题，请查看相关文档或提交Issue。
