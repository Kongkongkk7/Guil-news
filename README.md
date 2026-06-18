<div align="center">

# 📰 桂林学院新闻中心

### Guilin University News Center

**基于 Java + React 的校园新闻爬虫系统**

实时获取桂林学院官网新闻动态，采用桂林学院绿色系设计风格

</div>

---

## ✨ 功能特性

### 🎯 核心能力

- **实时爬取** — 自动抓取桂林学院官网最新新闻
- **智能缓存** — 5分钟内存缓存，减少重复请求
- **并发安全** — 读写锁保证多线程环境数据一致性
- **异步加载** — 后台异步获取缩略图，不阻塞主流程
- **响应式设计** — 完美适配桌面端和移动端

### 🖥️ 前端功能

| 功能 | 说明 |
|------|------|
| 新闻列表 | 卡片式布局，支持分类切换 |
| Hero 轮播 | 自动播放 + 手动切换 |
| 实时搜索 | 输入关键词即时过滤 |
| 骨架屏 | 加载状态优雅过渡 |
| 新闻详情 | 富文本渲染 + 阅读进度条 |
| 字号调节 | A- / A+ 适老化设计 |
| 打印功能 | 一键打印新闻内容 |
| 上下篇导航 | 快速跳转相邻新闻 |

### ⚙️ 后端功能

| 功能 | 说明 |
|------|------|
| Jsoup 解析 | 多选择器兼容解析 |
| 内存缓存 | ReentrantReadWriteLock 读写锁 |
| 异步缩略图 | ExecutorService 线程池 |
| 日期提取 | 正则表达式自动匹配 |
| 链接去重 | 自动过滤重复新闻 |
| JSON API | RESTful 风格接口设计 |

---

## 🛠️ 技术栈

<div align="center">

| 后端 | 前端 |
|:---:|:---:|
| Java 17 | React 18 |
| Servlet 4.0 | TypeScript 5.6 |
| Jsoup 1.17 | Vite 5.4 |
| Gson 2.10 | Tailwind CSS 3.4 |
| Maven | npm |
| Tomcat 7 | Vite Dev Server |

</div>

---

## 📁 项目结构

```
Guil-news/
├── src/main/java/com/guilin/news/
│   ├── model/News.java              # 新闻数据模型
│   ├── service/NewsService.java     # 爬虫核心服务（缓存 + 异步）
│   └── servlet/ApiServlet.java      # RESTful API 接口
├── src/main/webapp/WEB-INF/web.xml  # Servlet 配置
├── frontend/
│   ├── src/
│   │   ├── App.tsx                  # 首页（列表 + 轮播 + 搜索）
│   │   ├── NewsDetailPage.tsx       # 详情页（进度条 + 字号调节）
│   │   ├── types.ts                 # TypeScript 类型定义
│   │   ├── main.tsx                 # 应用入口
│   │   └── index.css                # 全局样式
│   ├── index.html
│   ├── vite.config.ts               # Vite 配置（含 API 代理）
│   ├── tailwind.config.js
│   └── package.json
├── pom.xml                          # Maven 配置
├── start-all.ps1                    # PowerShell 一键启动
└── start-all.bat                    # 批处理一键启动
```

---

## 🚀 快速开始

### 环境要求

- **JDK** 17+
- **Maven** 3.6+
- **Node.js** 18+

### 方式一：一键启动（推荐）

双击运行项目根目录下的启动脚本：

```
start-all.ps1    # PowerShell 脚本
start-all.bat    # 批处理脚本
```

脚本会自动完成：
1. 检查 Java、Maven、Node.js 环境
2. 安装前端依赖（首次运行）
3. 启动 Java 后端（端口 8080）
4. 启动 React 前端（端口 5173）

### 方式二：手动启动

```bash
# 1. 克隆仓库
git clone https://github.com/Kongkongkk7/Guil-news.git
cd Guil-news

# 2. 启动后端
mvn tomcat7:run

# 3. 启动前端（新终端）
cd frontend
npm install
npm run dev
```

### 访问应用

打开浏览器访问 **http://localhost:5173**

---

## 📡 API 文档

### 获取新闻列表

```
GET /api/news?type={category}
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `type` | string | 分类标识：`xxxw` / `xsdt` / `xykx` |

**响应示例：**

```json
{
  "success": true,
  "data": [
    {
      "title": "新闻标题",
      "link": "https://www.glc.edu.cn/...",
      "date": "2024-01-15",
      "thumbnail": "https://..."
    }
  ]
}
```

### 获取新闻详情

```
GET /api/news/detail?url={url}
```

### 批量获取缩略图

```
POST /api/news/thumbnails
Content-Type: application/json

{
  "urls": ["https://...", "https://..."]
}
```

### 新闻分类

| 分类 | 标识 | 说明 |
|------|------|------|
| 桂院要闻 | `xxxw` | 学校重要新闻和公告 |
| 学术动态 | `xsdt` | 学术讲座与科研动态 |
| 校园快讯 | `xykx` | 校园新鲜事和活动 |

---

## 🎨 设计亮点

- **桂林学院绿色系** — 主色调 `#1E6B56`，呼应学校视觉形象
- **渐变 Hero 区域** — 多层渐变 + 装饰圆形，营造层次感
- **骨架屏加载** — 内容加载时显示占位骨架，避免闪烁
- **平滑过渡动画** — 分类切换、卡片悬停均有流畅动效
- **阅读进度条** — 详情页顶部显示阅读进度
- **适老化设计** — 支持字号调节，提升可访问性

---

## 🔧 开发指南

### 添加新闻分类

1. 在 [NewsService.java](src/main/java/com/guilin/news/service/NewsService.java) 的 `CATEGORY_MAP` 中添加 URL
2. 在 `getCategoryName()` 方法中添加分类名称
3. 在 [types.ts](frontend/src/types.ts) 的 `CATEGORIES` 中添加分类信息

### 修改爬虫规则

爬虫规则位于 `NewsService.java` 的 `fetchNews()` 方法，使用 Jsoup 选择器语法。

---

## ❓ 常见问题

<details>
<summary><b>爬取失败怎么办？</b></summary>

检查网络连接，确保能访问 https://www.glc.edu.cn/。学校官网偶尔会维护，稍后重试即可。

</details>

<details>
<summary><b>前端显示"网络错误"？</b></summary>

1. 确认 Java 后端已在 8080 端口启动
2. 检查 [vite.config.ts](frontend/vite.config.ts) 中的代理配置
3. 查看后端控制台是否有异常信息

</details>

<details>
<summary><b>端口被占用？</b></summary>

使用一键启动脚本会自动释放端口，或手动执行：

```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <进程ID> /F
```

</details>

---

## 📄 License

本项目仅供学习交流使用

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个 Star！**

Made with ❤️ for Guilin University

</div>
