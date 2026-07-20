# 韭菜盘 (JCP AI) - iOS App

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> AI 驱动的智能股票分析系统 - 多 Agent 协作，让投资决策更智能

基于 [JCP (韭菜盘)](https://github.com/run-bigpig/jcp) 开源项目打造的 iOS 客户端，完整复刻了原项目的核心功能与交互体验。

## 功能特性

### 📈 股票行情
- 实时行情数据展示（价格、涨跌幅、成交量、成交额）
- 多周期 K 线图表（1分、5分、日线、周线、月线）
- MA5/MA10 均线绘制
- 盘口五档深度数据
- 大盘指数实时监控

### ⭐ 自选股管理
- 添加/删除自选股
- 实时行情刷新
- 市场状态自动识别（交易中/已收盘）
- 股票搜索（代码/名称）

### 🤖 AI 智库
- 多 Agent 协作分析（多头分析师、空头怀疑论者、技术量化专家、宏观经济学家、市场情报员）
- 自定义选择参与分析的专家团队
- 智能讨论总结生成
- 支持自定义分析问题
- Markdown 格式的详细分析报告

### 🔥 热点舆情
- 多平台热点聚合（百度、微博、抖音、B站、头条、知乎）
- 热度排名展示
- 实时刷新

### 📊 市场数据
- 龙虎榜数据
- 盘口异动监控
- 板块资金流向
- 股票 F10 数据（公司信息、估值、财务数据、主要指标）

### ⚙️ 设置中心
- AI 模型配置（OpenAI、Google Gemini、DeepSeek、Kimi、GLM 等）
- 多配置管理
- 默认配置切换

## 技术栈

| 层级 | 技术 |
|------|------|
| **框架** | SwiftUI + Combine |
| **架构** | MVVM (Model-View-ViewModel) |
| **图表** | 自定义 Canvas/Path 绘制 |
| **数据** | 本地模拟数据 (Mock) |
| **最低版本** | iOS 17.0 |

## 项目结构

```
jcp-ios/
├── project.yml              # XcodeGen 项目配置
├── jcp-ios/
│   ├── JCPApp.swift          # App 入口
│   ├── Models/               # 数据模型
│   │   ├── Stock.swift       # 股票、K线、盘口、大盘模型
│   │   ├── Agent.swift       # Agent、聊天消息、策略模型
│   │   └── HotTrend.swift    # 热点、龙虎榜、F10、配置模型
│   ├── Services/             # 服务层
│   │   ├── MockDataService.swift  # 模拟数据服务
│   │   ├── AIAgentService.swift   # AI 分析服务
│   │   └── ConfigService.swift    # 配置存储服务
│   ├── ViewModels/           # 视图模型 (MVVM)
│   │   └── ViewModels.swift
│   ├── Views/                # SwiftUI 视图
│   │   ├── Main/             # 主界面 (TabView)
│   │   ├── Watchlist/        # 自选股
│   │   ├── StockDetail/      # 股票详情 (K线/盘口/F10)
│   │   ├── AgentRoom/        # AI 智库
│   │   ├── Market/           # 行情 (热点/龙虎榜/异动/资金流)
│   │   ├── Search/           # 股票搜索
│   │   └── Settings/         # 设置
│   ├── Utils/                # 工具类
│   │   └── Constants.swift   # 常量、颜色、格式化
│   └── Resources/            # 资源文件
│       ├── Info.plist
│       └── Assets.xcassets/
└── README.md
```

## 快速开始

### 前置条件

- macOS 14+ (Sonoma)
- Xcode 15.0+
- iOS 17.0+ 模拟器或真机

### 方法一：使用 XcodeGen（推荐）

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 在项目目录生成 Xcode 项目
cd jcp-ios
xcodegen generate

# 3. 打开项目
open jcp-ios.xcodeproj
```

### 方法二：手动创建

1. 打开 Xcode → File → New → Project
2. 选择 iOS → App
3. 填写项目信息：
   - Product Name: `jcp-ios`
   - Team: (选择你的开发者团队)
   - Organization Identifier: `com.jcp`
   - Interface: SwiftUI
   - Language: Swift
4. 将 `jcp-ios/` 目录下的所有 `.swift` 文件添加到项目中
5. 添加 `Resources/Info.plist` 和 `Resources/Assets.xcassets`
6. 设置 Deployment Target 为 iOS 17.0

### 运行

1. 选择合适的模拟器（推荐 iPhone 15 Pro）
2. Cmd + R 运行

## 功能预览

### 主界面
- **行情** 标签页：大盘指数 + 热点舆情 + 龙虎榜 + 异动 + 资金流
- **自选** 标签页：自选股列表 + 实时行情 + 搜索添加
- **AI智库** 标签页：选择股票 + 选择专家 + 输入问题 → 智能分析
- **我的** 标签页：AI 配置管理 + 版本信息

### 股票详情
- 点击自选股或搜索结果中的股票进入详情
- **K线** 标签：多周期 K 线图 + 均线 + 成交量
- **盘口** 标签：五档买卖盘口深度
- **F10** 标签：公司信息 + 估值 + 财务数据 + 主要指标

## 数据说明

当前版本使用 **本地模拟数据**（MockDataService），涵盖了 18 只主流 A 股的真实名称和行业分类，价格为模拟数据。

后续版本将接入真实数据源。

## 许可证

本项目基于 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 致谢

- [JCP (韭菜盘)](https://github.com/run-bigpig/jcp) - 原项目
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - UI 框架
