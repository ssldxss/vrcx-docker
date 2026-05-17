# 🍡 VRCX Docker

在 Docker 中运行 [VRCX](https://github.com/vrcx-team/VRCX)，通过浏览器 (noVNC) 访问。

VRCX 是 VRChat 的好友/通知/日志管理工具，本项目将其打包为 Docker 容器，适合在 NAS / 服务器上 24 小时运行。

## ✨ 特性

- 🖥️ 浏览器访问 (noVNC)，无需安装客户端
- 📦 自动从源码构建最新版 VRCX
- 💾 数据库/配置持久化存储
- 🎛️ 可自定义虚拟桌面分辨率
- 🐳 支持 amd64 架构

## 🚀 快速开始

### 方式一：docker compose（推荐）

```bash
git clone https://github.com/你的用户名/vrcx-docker.git
cd vrcx-docker
docker compose up -d
```

浏览器打开 `http://你的NASIP:6080`

### 方式二：从 Docker Hub 拉取

```bash
docker run -d \
  --name vrcx \
  -p 6080:6080 \
  -v ./vrcx-data:/root/.config/VRCX \
  -e TZ=Asia/Shanghai \
  -e RESOLUTION=1920x1080 \
  --shm-size=256m \
  你的用户名/vrcx-docker:latest
```

## ⚙️ 配置

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `RESOLUTION` | `1280x720` | 虚拟桌面分辨率 |
| `TZ` | `UTC` | 时区 |

## 🔧 启用关系网 (WebGL)

关系网功能需要 WebGL，默认关闭以节省 CPU。

修改 `entrypoint.sh`，将 Electron 启动参数替换为：

```
--use-gl=angle --use-angle=swiftshader --disable-dev-shm-usage
```

> ⚠️ SwiftShader 是纯 CPU 软件渲染，会显著增加 CPU 占用。

## 📂 数据持久化

```
vrcx-data/AppData/
├── VRCX.sqlite3    # 主数据库
├── VRCX.json        # 配置文件
├── ImageCache/      # 头像缓存
├── logs/            # 日志
└── userdata/        # 用户数据
```

## 🛠️ 从 Windows 导入数据

1. 复制 Windows 上 `%APPDATA%\VRCX\` 目录
2. 放到 `vrcx-data/AppData/` 下
3. 重启容器

## 📝 端口说明

| 端口 | 用途 |
|------|------|
| 6080 | noVNC Web 访问 |
| 5900 | VNC 直连（默认关闭） |

## 🤝 致谢

- [VRCX](https://github.com/vrcx-team/VRCX) - VRChat 客户端工具
- [noVNC](https://github.com/novnc/noVNC) - HTML5 VNC 客户端

## 📄 许可

MIT
