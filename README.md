# Guilin University News Center

桂林学院新闻中心 - Java 新闻爬虫系统

## 项目简介

基于 Java Web + React 技术栈的校园新闻爬虫系统，实时获取桂林学院官网新闻动态，采用绿色系设计风格。

## 技术栈

| 模块 | 技术 |
|------|------|
| 后端框架 | Java Servlet + JSON API |
| 爬虫库 | Jsoup |
| 前端框架 | React 18 + TypeScript + Vite |
| UI 样式 | Tailwind CSS 3 |
| 构建工具 | Maven (后端) + npm (前端) |
| 服务器 | Tomcat 7 (后端) + Vite Dev Server (前端) |

## 项目结构

```
Guil-news/
├── src/main/java/com/guilin/news/
│   ├── model/
│   │   └── News.java              # 新闻数据模型
│   ├── service/
│   │   └── NewsService.java       # 爬虫核心服务（含缓存机制）
│   └── servlet/
│       └── ApiServlet.java        # JSON API 接口
├── src/main/webapp/
│   └── WEB-INF/web.xml           # Servlet 配置
├── frontend/
│   ├── src/
│   │   ├── App.tsx                # 首页组件（列表+轮播+搜索）
│   │   ├── NewsDetailPage.tsx     # 新闻详情页
│   │   ├── types.ts               # TypeScript 类型定义
│   │   ├── main.tsx               # 入口文件
│   │   └── index.css              # 全局样式
│   ├── index.html
│   ├── package.json
│   ├── vite.config.ts             # Vite 配置（含代理）
│   ├── tailwind.config.js         # Tailwind 配置
│   └── postcss.config.js          # PostCSS 配置
├── pom.xml                        # Maven 配置
└── start-all.ps1                  # Windows 一键启动脚本
```

## 环境要求

- JDK 17+
- Maven 3.6+
- Node.js 18+

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/Kongkongkk7/Guil-news.git
cd Guil-news
```

### 2. 启动 Java 后端

```bash
mvn clean package
mvn tomcat7:run
```

后端将在 http://localhost:8080/guilin-news/ 启动

### 3. 启动 React 前端

```bash
cd frontend
npm install
npm run dev
```

前端将在 http://localhost:5173 启动

### 4. 访问应用

打开浏览器访问 http://localhost:5173

## API 接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/news?type={category}` | GET | 获取新闻列表 |
| `/api/news/detail?url={url}` | GET | 获取新闻详情 |
| `/api/news/thumbnails` | POST | 批量获取缩略图 |
| `/api/news/categories` | GET | 获取所有分类 |

## 新闻分类

| 分类标识 | 名称 | 说明 |
|----------|------|------|
| `xxxw` | 桂院要闻 | 学校重要新闻和公告 |
| `xsdt` | 学术动态 | 学术讲座与科研动态 |
| `xykx` | 校园快讯 | 校园新鲜事和活动 |

## 核心功能

### 后端功能 (`NewsService.java`)
- ✅ Jsoup 解析网页内容
- ✅ 5分钟内存缓存机制（ReentrantReadWriteLock）
- ✅ 并发安全的缓存读写
- ✅ 异步获取新闻缩略图（ExecutorService）
- ✅ 日期自动提取（正则匹配）
- ✅ 新闻链接去重
- ✅ 多选择器兼容解析

### 前端功能 (`App.tsx`)
- ✅ 新闻列表展示（卡片式布局）
- ✅ Hero 轮播（自动播放+手动切换）
- ✅ 新闻搜索（实时过滤）
- ✅ 分类导航（带视觉反馈）
- ✅ 加载状态骨架屏
- ✅ 错误处理与重试
- ✅ 响应式设计（移动端适配）
- ✅ 桂林学院绿色系设计风格

### 详情页功能 (`NewsDetailPage.tsx`)
- ✅ 富文本内容渲染
- ✅ 阅读进度条
- ✅ 字号调节（A-/A+）
- ✅ 打印功能
- ✅ 上一篇/下一篇导航
- ✅ 返回顶部按钮
- ✅ 阅读时间预估

## 开发说明

### 添加新的新闻分类

1. 在 `NewsService.java` 的 `CATEGORY_MAP` 中添加新的 URL
2. 在 `getCategoryName()` 方法中添加分类名称
3. 在 `frontend/src/types.ts` 的 `CATEGORIES` 中添加分类信息

### 修改爬虫规则

爬虫规则在 `NewsService.java` 的 `fetchNews()` 方法中，使用 Jsoup 选择器语法。

## 常见问题

### 1. 爬取失败

检查网络连接，确保可以访问 https://www.glc.edu.cn/

### 2. 前端无法连接后端

确保 Java 后端已在 8080 端口启动，并检查 `vite.config.ts` 中的代理配置。

## License

Private - 仅供学习使用