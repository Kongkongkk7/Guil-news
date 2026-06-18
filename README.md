# 桂林学院新闻中心 (Guilin University News Center)

基于 Java + React 的新闻爬虫系统，抓取桂林学院官网新闻并展示。

## 一键启动

### 快速开始

1. 克隆项目到本地
2. **双击运行 `start-all.bat`**（推荐，会自动请求管理员权限）
   - 或右键 `start-all.ps1` → "使用 PowerShell 运行"
3. 脚本会自动完成所有配置和启动

### 脚本会自动完成

- 检查并安装 Java JDK 17（如未安装）
- 检查并安装 Maven 3.9（如未安装）
- 检查并安装 Node.js 20（如未安装）
- 配置 Maven 阿里云镜像（加速国内下载）
- 配置 npm 淘宝镜像（加速国内下载）
- 安装前端依赖
- 启动后端和前端服务
- 自动打开浏览器

### 访问地址

| 服务 | 地址 |
|------|------|
| 前端 | http://localhost:5173 |
| 后端 API | http://localhost:8080/guilin-news/api/news |

### 手动安装依赖（可选）

如不想使用自动安装，可手动安装以下环境：

| 依赖 | 最低版本 | 下载地址 |
|------|---------|---------|
| JDK | 17 | https://learn.microsoft.com/java/openjdk/ |
| Maven | 3.6 | https://maven.apache.org/download.cgi |
| Node.js | 18 | https://nodejs.org/ |

国内镜像推荐：
- JDK: https://mirrors.tuna.tsinghua.edu.cn/Adoptium/
- Node.js: https://npmmirror.com/mirrors/node/

### 手动启动

```bash
# 后端
mvn tomcat7:run

# 前端（另开终端）
cd frontend
npm install
npm run dev
```

### 停止服务

关闭对应的命令行窗口即可。

## 技术栈

- **后端**: Java 17 + Servlet + Jsoup + Gson
- **前端**: React 18 + TypeScript + Vite + TailwindCSS
- **构建**: Maven + npm

## 项目结构

```
Guil-news/
├── src/main/java/          # 后端 Java 代码
├── src/main/webapp/        # 后端 Web 资源
├── frontend/               # 前端 React 项目
├── maven-settings.xml      # Maven 阿里云镜像配置
├── start-all.ps1           # 一键启动脚本（PowerShell）
├── start-all.bat           # 一键启动脚本（批处理入口）
└── pom.xml                 # Maven 配置
```

## 常见问题

### Q: 端口被占用怎么办？
关闭占用 8080 或 5173 端口的程序后重新运行脚本。

### Q: 自动安装失败怎么办？
以管理员身份运行脚本，或手动安装依赖后重新运行。

### Q: 首次启动很慢？
首次运行需要下载 Maven 依赖和 npm 包，请耐心等待。后续启动会快很多。

### Q: PowerShell 执行策略报错？
使用 `start-all.bat` 启动，它会自动绕过执行策略限制。
