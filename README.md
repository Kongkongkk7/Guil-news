<div align="center">

# 桂林学院新闻中心

### Guilin University News Center

**基于 Java Servlet + React 的前后端分离校园新闻聚合系统**

[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.org/)
[![React](https://img.shields.io/badge/React-18-61DAFB.svg)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.6-3178C6.svg)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-5-646CFF.svg)](https://vitejs.dev/)
[![TailwindCSS](https://img.shields.io/badge/Tailwind-3-38BDF8.svg)](https://tailwindcss.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 项目简介

本项目是一个**前后端分离**的校园新闻聚合平台，通过爬取桂林学院官方网站（glc.edu.cn）的新闻数据，在自建的现代化 Web 界面中聚合展示。系统涵盖**桂院要闻、学术动态、桂院人物、媒体关注**四大板块，提供新闻浏览、搜索、详情阅读等完整功能。

项目综合运用了**多线程并发、读写锁缓存、多策略 HTML 解析、响应式设计**等技术，并配备了一键自动部署脚本，是一个兼具技术深度与实用价值的全栈项目。

---

## 核心技术亮点

### 1. 多线程缩略图并发抓取

采用 `FixedThreadPool`（5 线程）并发抓取每条新闻详情页的首图，配合 30 秒超时机制，相比串行抓取性能提升显著：

```java
ExecutorService executor = Executors.newFixedThreadPool(5);
for (News news : newsList) {
    executor.submit(() -> {
        String thumbnail = fetchFirstImage(news.getLink());
        // ...
    });
}
executor.awaitTermination(30, TimeUnit.SECONDS);
```

### 2. 读写锁 + 双重检查的缓存机制

使用 `ReentrantReadWriteLock` 实现缓存并发控制，读操作不阻塞，写操作通过双重检查锁定（Double-Checked Locking）避免并发重复抓取：

```java
// 第一层：读锁快速检查
CACHE_LOCK.readLock().lock();
try {
    CacheEntry entry = CACHE.get(category);
    if (entry != null && !entry.isExpired()) return entry.newsList;
} finally { CACHE_LOCK.readLock().unlock(); }

// 第二层：写锁 + 双重检查
CACHE_LOCK.writeLock().lock();
try {
    CacheEntry entry = CACHE.get(category);
    if (entry != null && !entry.isExpired()) return entry.newsList;
    // ... 执行抓取并写入缓存
} finally { CACHE_LOCK.writeLock().unlock(); }
```

缓存 TTL 设为 5 分钟，在数据实时性与服务器负载之间取得平衡。

### 3. 多策略降级 HTML 解析

针对官网不同分类页面的 HTML 结构差异，设计了**三级降级解析策略**，自动适配多种页面格式：

| 优先级 | CSS 选择器 | 适用场景 |
|--------|-----------|---------|
| 第一级 | `li a[href*=info/]` | 标准新闻列表页 |
| 第二级 | `a[href*=../info/]` | 备用链接格式 |
| 第三级 | `a.block[title]` | 桂院人物页面（特殊结构） |

### 4. 编码强制处理

官网页面声明 UTF-8 但 Jsoup 自动检测偶发失败，通过获取原始字节数组后强制 UTF-8 解码，彻底解决中文乱码问题：

```java
byte[] bytes = response.bodyAsBytes();
return Jsoup.parse(new String(bytes, Charset.forName("UTF-8")), url);
```

### 5. 前端异步缩略图加载

采用**两阶段渲染**策略：先获取新闻列表立即渲染，再异步批量请求缩略图，大幅提升首屏速度：

```typescript
// 第一阶段：立即渲染列表
const response = await fetch(`/api/news?type=${category}`);
setNews(response.data);

// 第二阶段：异步补全缩略图（不阻塞首屏）
fetch('/api/news/thumbnails', { method: 'POST', body: JSON.stringify({ urls }) })
  .then(r => r.json())
  .then(td => setNews(prev => /* 合并缩略图 */));
```

### 6. 外部链接智能识别

自动识别微信公众号等外部链接，直接在新标签页打开原文，避免无效的后端解析：

```typescript
if (item.link && !item.link.includes('glc.edu.cn')) {
    window.open(item.link, '_blank');
    return;
}
```

---

## 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                      浏览器 (Browser)                     │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  首页 App    │  │ 详情页 Detail │  │  搜索/导航     │  │
│  └──────┬──────┘  └──────┬───────┘  └───────────────┘  │
│         │                │                               │
│         │   fetch API    │                               │
└─────────┼────────────────┼───────────────────────────────┘
          │                │
          ▼                ▼
┌─────────────────────────────────────────┐
│        Vite Dev Server (端口 5173)       │
│   /api/* → 代理转发至后端 (rewrite)       │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│           Tomcat 7 (端口 8080 /guilin-news)           │
│  ┌─────────────────────────────────────────────────┐ │
│  │              ApiServlet (/api/news/*)            │ │
│  │   GET /api/news?type=     → 新闻列表             │ │
│  │   GET /api/news/detail    → 新闻详情             │ │
│  │   GET /api/news/categories→ 分类信息             │ │
│  │   POST /api/news/thumbnails→ 批量缩略图          │ │
│  └────────────────────┬────────────────────────────┘ │
│                       │                               │
│  ┌────────────────────▼────────────────────────────┐ │
│  │              NewsService (核心服务层)             │ │
│  │  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │ │
│  │  │ 读写锁缓存 │  │ 多线程池  │  │ 多策略解析器   │  │ │
│  │  │ TTL 5min │  │ 5 threads│  │ 3级降级策略    │  │ │
│  │  └──────────┘  └──────────┘  └───────────────┘  │ │
│  └────────────────────┬────────────────────────────┘ │
│                       │                               │
│  ┌────────────────────▼────────────────────────────┐ │
│  │           Jsoup + Gson (数据抓取层)              │ │
│  └────────────────────┬────────────────────────────┘ │
└───────────────────────┼───────────────────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │  glc.edu.cn 官网  │
              │  (HTML 页面抓取)   │
              └──────────────────┘
```

---

## 技术栈

### 后端

| 技术 | 版本 | 用途 |
|------|------|------|
| Java | 17 | 编程语言 |
| Servlet API | 4.0 | Web 服务框架 |
| Jsoup | 1.15.4 | HTML 解析与爬虫 |
| Gson | 2.8.2 | JSON 序列化 |
| Tomcat 7 Plugin | 2.2 | 内嵌 Servlet 容器 |
| Maven | 3.9 | 构建与依赖管理 |

### 前端

| 技术 | 版本 | 用途 |
|------|------|------|
| React | 18.3 | UI 框架 |
| TypeScript | 5.6 | 类型安全 |
| Vite | 5.4 | 构建工具与开发服务器 |
| Tailwind CSS | 3.4 | 原子化 CSS 框架 |
| Fetch API | - | HTTP 请求 |

---

## 设计模式应用

| 设计模式 | 应用场景 | 实现方式 |
|----------|---------|---------|
| **MVC 架构** | 整体分层 | Model(News) → Service(NewsService) → Controller(ApiServlet) |
| **读写锁模式** | 缓存并发控制 | `ReentrantReadWriteLock` + 5 分钟 TTL |
| **双重检查锁定** | 缓存写入 | 读锁检查 → 写锁再检查，防止并发重复抓取 |
| **线程池模式** | 缩略图抓取 | `Executors.newFixedThreadPool(5)` |
| **降级策略模式** | HTML 解析 | 三级选择器逐步降级适配 |
| **统一响应格式** | API 设计 | `{success, data, message}` 标准化 |
| **前端自定义路由** | 页面切换 | 基于 `pathname` 的条件渲染，零依赖 |

---

## 功能特性

### 新闻浏览
- 四大分类（桂院要闻、学术动态、桂院人物、媒体关注）实时聚合
- Hero 轮播图展示头条新闻，5 秒自动切换
- 新闻卡片悬停动画，缩略图懒加载

### 新闻搜索
- 实时标题搜索，支持回车触发
- 搜索结果高亮统计

### 详情阅读
- 正文 HTML 渲染，图片自动补全绝对路径
- 字号调节（14-22px）
- 阅读进度条 + 阅读时间估算
- 上下篇导航
- 打印优化（`@media print`）
- 外部链接（微信公众号）智能跳转

### 用户体验
- 骨架屏加载动画
- 响应式设计（桌面/移动端适配）
- 返回顶部按钮
- 分类主题色切换

---

## 项目结构

```
Guil-news/
├── src/main/java/com/guilin/news/
│   ├── model/News.java              # 新闻实体类（值对象）
│   ├── service/NewsService.java     # 核心服务层（缓存/爬虫/解析）
│   └── servlet/ApiServlet.java      # API 控制器（路由/响应）
├── src/main/webapp/WEB-INF/
│   └── web.xml                      # Servlet 4.0 配置
├── frontend/
│   ├── src/
│   │   ├── App.tsx                  # 首页（列表/轮播/搜索）
│   │   ├── NewsDetailPage.tsx       # 详情页（阅读增强）
│   │   ├── main.tsx                 # 入口与路由
│   │   ├── types.ts                 # TypeScript 类型定义
│   │   └── index.css               # 全局样式与动画
│   ├── vite.config.ts               # Vite 配置（代理/端口）
│   ├── tailwind.config.js           # Tailwind 主题配置
│   └── package.json
├── maven-settings.xml               # Maven 阿里云镜像
├── start-all.ps1                    # 一键启动脚本（PowerShell）
├── start-all.bat                    # 一键启动入口（批处理）
└── pom.xml                          # Maven 配置
```

---

## 快速开始

### 一键启动（推荐）

1. 克隆项目到本地
2. **双击运行 `start-all.bat`**
3. 脚本自动完成所有配置并启动服务

脚本会自动完成以下工作：

- 检测并安装 Java JDK 17、Maven 3.9、Node.js 20（如未安装）
- 配置 Maven 阿里云镜像 + npm 淘宝镜像（加速国内下载）
- 安装前端依赖
- 启动后端（端口 8080）和前端（端口 5173）
- 自动打开浏览器

### 手动启动

```bash
# 后端
mvn tomcat7:run

# 前端（另开终端）
cd frontend
npm install
npm run dev
```

### 访问地址

| 服务 | 地址 |
|------|------|
| 前端页面 | http://localhost:5173 |
| 后端 API | http://localhost:8080/guilin-news/api/news |

---

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/news` | 获取所有分类信息 |
| GET | `/api/news?type=xxxw` | 获取指定分类新闻列表 |
| GET | `/api/news/detail?url=xxx` | 获取新闻详情（正文 HTML） |
| GET | `/api/news/categories` | 获取所有新闻分类 |
| POST | `/api/news/thumbnails` | 批量获取新闻缩略图 |

**响应格式**：
```json
{
  "success": true,
  "data": [
    {
      "title": "新闻标题",
      "link": "https://www.glc.edu.cn/info/...",
      "date": "2026年06月01日",
      "thumbnail": "https://..."
    }
  ]
}
```

---

## 数据抓取流程

```
用户切换分类
    │
    ▼
前端 GET /api/news?type=xxx
    │
    ▼ (Vite Proxy 转发)
ApiServlet → NewsService.fetchNews()
    │
    ├─ 缓存命中？─── 是 ──→ 直接返回缓存数据
    │
    否
    │
    ▼
Jsoup 抓取官网列表页 (UTF-8 强制解码)
    │
    ▼
三级策略解析 HTML → 提取标题/链接/日期
    │
    ▼
5 线程池并发抓取每条新闻详情页首图
    │
    ▼
去重 → 写入缓存 (TTL 5min) → 返回 JSON
    │
    ▼
前端渲染列表 → 异步补全缩略图
```

---

## 常见问题

**Q: 端口被占用怎么办？**

使用一键启动脚本会自动检测并寻找可用端口，或手动关闭占用 8080/5173 端口的程序。

**Q: 首次启动很慢？**

首次运行需下载 Maven 依赖和 npm 包，请耐心等待。后续启动会快很多。

**Q: 新闻标题乱码？**

已通过强制 UTF-8 解码修复。如仍出现，请清除缓存重启后端。

**Q: PowerShell 执行策略报错？**

使用 `start-all.bat` 启动，它会自动绕过执行策略限制。

---

## 环境要求

| 依赖 | 最低版本 | 说明 |
|------|---------|------|
| JDK | 17 | 一键脚本可自动安装 |
| Maven | 3.6 | 一键脚本可自动安装 |
| Node.js | 18 | 一键脚本可自动安装 |

> 无需提前安装任何环境，一键脚本会自动检测并安装所有依赖。

---

<div align="center">

**桂林学院 · 新闻中心**

© 2026 Guilin University News Center

</div>
