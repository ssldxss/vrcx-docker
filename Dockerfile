FROM debian:bookworm-slim

LABEL maintainer="yuan"
LABEL description="VRCX - VRChat friendship management tool in Docker (noVNC access)"

# ═══════════════════════════════════════════
# 1. 系统依赖 - X11/VNC/Electron/字体
# ═══════════════════════════════════════════
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    wget curl ca-certificates git procps \
    # X11 虚拟显示
    xvfb \
    # VNC 服务
    x11vnc \
    # noVNC (HTML5 VNC 客户端) + WebSocket 桥接
    novnc websockify \
    # Electron/Chromium 运行时依赖
    libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 \
    xdg-utils libatspi2.0-0 libsecret-1-0 libasound2 \
    libgbm1 libdrm2 libxkbcommon0 libxrandr2 \
    libxcomposite1 libxdamage1 libxfixes3 \
    libpango-1.0-0 libcairo2 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libx11-xcb1 libxcb-dri3-0 libxcb-present0 \
    # 多语言字体（中/日/韩）
    fonts-noto-cjk \
    # 清理缓存
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════
# 2. Node.js 24.x
# ═══════════════════════════════════════════
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ═══════════════════════════════════════════
# 3. .NET SDK 9.0 (构建用)
# ═══════════════════════════════════════════
RUN wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb \
        -O /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-9.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置 .NET 环境变量
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=$PATH:$DOTNET_ROOT
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1

# ═══════════════════════════════════════════
# 4. 克隆 VRCX 源码
# ═══════════════════════════════════════════
WORKDIR /app
RUN git clone --depth=1 https://github.com/vrcx-team/VRCX.git /app

# ═══════════════════════════════════════════
# 5. 还原 NuGet 包 + npm 依赖 (可缓存层)
# ═══════════════════════════════════════════
# 先还原 NuGet（独立层，源码不变时可用缓存）
RUN dotnet restore Dotnet/VRCX-Electron.csproj -p:Platform=x64

# npm 安装（也是独立缓存层）
RUN npm install

# ═══════════════════════════════════════════
# 6. 构建 .NET 后端 + Vue 前端
# ═══════════════════════════════════════════
# 编译 .NET → build/Electron/
RUN dotnet build Dotnet/VRCX-Electron.csproj \
    -c Release -p:Platform=x64 \
    --no-restore

# 修复: System.Data.SQLite 需要原生库在 build/Electron/ 根目录
# Linux 原生文件在 runtimes/linux-x64/native/ 里但主 exe 目录找不到
RUN cp -v /app/build/Electron/runtimes/linux-x64/native/SQLite.Interop.dll \
        /app/build/Electron/SQLite.Interop.dll \
    && cp -v /app/build/Electron/runtimes/linux-x64/native/libe_sqlite3.so \
        /app/build/Electron/libe_sqlite3.so 2>/dev/null || true

# 构建 Vue 3 前端 → build/html/
RUN npm run prod-linux

# ═══════════════════════════════════════════
# 7. 运行时配置
# ═══════════════════════════════════════════
ENV DISPLAY=:99
ENV DATA_DIR=/data
ENV VRCX_APPDATA=/data/AppData
# Electron 在 Docker 里必须以非沙箱模式运行
ENV ELECTRON_DISABLE_SANDBOX=1

EXPOSE 6080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
