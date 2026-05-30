# Guilin University News Center

桂林学院新闻中心 - 新闻爬虫与前端展示系统

## 项目结构

```
├── index.ts          # 后端服务（Hono + Cheerio）
├── frontend/         # 前端应用（React + Vite + Tailwind CSS）
├── start-all.ps1     # 一键启动脚本
├── package.json      # 后端依赖配置
└── tsconfig.json     # TypeScript 配置
```

## 环境要求

- [Bun](https://bun.sh/) >= 1.0
- [Node.js](https://nodejs.org/) >= 18
- [Git](https://git-scm.com/)

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/Kongkongkk7/Guil-news.git
cd Guil-news
```

### 2. 安装后端依赖

```bash
bun install
```

### 3. 安装前端依赖

```bash
cd frontend
npm install
cd ..
```

### 4. 启动项目

#### 方式一：使用启动脚本（推荐）

```powershell
.\start-all.ps1
```

#### 方式二：手动启动

启动后端服务（端口 4001）：
```bash
bun run index.ts
```

启动前端开发服务器（端口 5173）：
```bash
cd frontend
npm run dev
```

### 5. 访问应用

- 前端页面：http://localhost:5173
- 后端 API：http://localhost:4001

## 技术栈

| 部分 | 技术 |
|------|------|
| 后端 | Bun, Hono, Cheerio |
| 前端 | React, TypeScript, Vite, Tailwind CSS |

## API 接口

| 接口 | 说明 |
|------|------|
| `GET /news/xxxw` | 校内新闻 |
| `GET /news/xsdt` | 学术动态 |
| `GET /news/gyrw` | 光荣入伍 |
| `GET /news/mtgy` | 媒体关注 |

## License

Private
