# Guilin University News Center

桂林学院新闻中心 - Java 新闻爬虫系统

## 项目简介

这是一个基于 Java Web 技术的校园新闻爬虫系统，用于实时获取桂林学院官网的新闻动态。

## 技术栈

| 模块 | 技术 |
|------|------|
| 后端框架 | Servlet + JSP |
| 爬虫库 | Jsoup |
| 前端 | JSP + Bootstrap 5 |
| 构建工具 | Maven |
| 服务器 | Tomcat |

## 项目结构

```
src/
├── main/
│   ├── java/
│   │   └── com/guilin/news/
│   │       ├── model/
│   │       │   └── News.java          # 新闻数据模型
│   │       ├── service/
│   │       │   └── NewsService.java   # 爬虫服务类
│   │       └── servlet/
│   │           └── NewsServlet.java   # Servlet 控制器
│   ├── resources/
│   └── webapp/
│       ├── WEB-INF/
│       │   └── web.xml               # Web 应用配置
│       ├── jsp/
│       │   ├── index.jsp             # 首页
│       │   ├── news.jsp              # 新闻列表页
│       │   └── error.jsp             # 错误页面
│       └── index.jsp                 # 重定向页面
└── test/
    └── java/
pom.xml                               # Maven 配置文件
```

## 环境要求

- JDK 17+
- Maven 3.6+
- Tomcat 9+ 或 10+
- 网络连接（需要访问桂林学院官网）

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/Kongkongkk7/Guil-news.git
cd Guil-news
```

### 2. 使用 Maven 构建项目

```bash
mvn clean package
```

### 3. 部署到 Tomcat

**方式一：使用 Maven Tomcat 插件**

```bash
mvn tomcat7:run
```

**方式二：手动部署**

1. 将 `target/guilin-news.war` 文件复制到 Tomcat 的 `webapps` 目录
2. 启动 Tomcat 服务器
3. 访问 http://localhost:8080/guilin-news/

### 4. 在 IDEA 中运行

1. 使用 IDEA 打开项目
2. 配置 Tomcat 服务器
3. 运行项目

## 功能说明

| 功能 | 说明 |
|------|------|
| 校内新闻 | 获取校园内部新闻动态 |
| 学术动态 | 获取学术讲座、科研成果等信息 |
| 光荣入伍 | 获取学生参军入伍相关新闻 |
| 媒体关注 | 获取媒体对学校的报道 |

## API 路由

| 路由 | 说明 |
|------|------|
| `GET /news/` | 首页，显示新闻分类 |
| `GET /news/xxxw` | 校内新闻列表 |
| `GET /news/xsdt` | 学术动态列表 |
| `GET /news/gyrw` | 光荣入伍列表 |
| `GET /news/mtgy` | 媒体关注列表 |

## 开发说明

### 添加新的新闻分类

1. 在 `NewsService.java` 的 `CATEGORY_MAP` 中添加新的 URL
2. 在 `getCategoryName()` 方法中添加分类名称
3. 在 JSP 页面中添加对应的显示

### 修改爬虫规则

爬虫规则在 `NewsService.java` 的 `fetchNews()` 方法中，使用 Jsoup 选择器语法。

## 常见问题

### 1. 编译错误：找不到 javax.servlet

确保 Tomcat 已正确配置，Servlet API 依赖为 `provided` scope。

### 2. 爬取失败

检查网络连接，确保可以访问 https://www.glc.edu.cn/

### 3. 中文乱码

确保项目编码为 UTF-8，JSP 页面 charset 设置正确。

## License

Private - 仅供学习使用
