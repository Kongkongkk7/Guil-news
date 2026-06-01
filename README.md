# Guilin University News Center

桂林学院新闻中心 - Java 新闻爬虫系统

## 项目简介

这是一个基于 Java Web 技术的校园新闻爬虫系统，用于实时获取桂林学院官网的新闻动态。采用前后端分离架构，仿照北京大学新闻网设计风格。

## 技术栈

| 模块 | 技术 |
|------|------|
| 后端框架 | Servlet + JSON API |
| 爬虫库 | Jsoup |
| 前端框架 | React + TypeScript + Vite |
| UI 样式 | Tailwind CSS |
| 构建工具 | Maven (后端) + npm (前端) |
| 服务器 | Tomcat (后端) + Vite Dev Server (前端) |

## 项目结构

```
├── src/                           # Java 后端
│   └── main/
│       ├── java/com/guilin/news/
│       │   ├── model/News.java    # 数据模型
│       │   ├── service/NewsService.java  # 爬虫服务
│       │   └── servlet/
│       │       ├── NewsServlet.java     # JSP 版本
│       │       └── ApiServlet.java      # JSON API
│       └── webapp/
│           ├── WEB-INF/web.xml
│           └── jsp/               # JSP 页面（备用）
├── frontend/                      # React 前端
│   ├── src/
│   │   ├── App.tsx               # 主组件
│   │   └── types.ts              # 类型定义
│   ├── package.json
│   └── vite.config.ts
├── pom.xml                        # Maven 配置
└── README.md
```

## 环境要求

- JDK 17+
- Maven 3.6+
- Node.js 18+
- 网络连接（需要访问桂林学院官网）

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

| 接口 | 说明 |
|------|------|
| `GET /api/news/categories` | 获取所有分类 |
| `GET /api/news/xxxw` | 校内新闻 |
| `GET /api/news/xsdt` | 学术动态 |
| `GET /api/news/gyrw` | 光荣入伍 |
| `GET /api/news/mtgy` | 媒体关注 |

## 功能特性

- ✅ 实时爬取桂林学院官网新闻
- ✅ 仿北京大学新闻网设计风格
- ✅ 响应式布局，支持移动端
- ✅ 新闻搜索功能
- ✅ 新闻详情弹窗
- ✅ 上一篇/下一篇导航
- ✅ 加载状态和错误处理

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
