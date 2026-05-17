#!/bin/bash
set -e

echo "╔══════════════════════════════════════════╗"
echo "║       🍡 VRCX Docker 启动中...         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════
# 清理残留
# ═══════════════════════════════════════════
echo "🧹 清理旧锁文件..."
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

# ═══════════════════════════════════════════
# 1. 启动 dbus (Electron/Chromium 需要)
# ═══════════════════════════════════════════
echo "🔌 启动 dbus-daemon..."
dbus-daemon --system --fork 2>/dev/null || true
dbus-daemon --session --fork --address="unix:path=/tmp/dbus-session" 2>/dev/null || true
export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-session"
sleep 0.5
echo "   ✅ dbus 已启动"

# ═══════════════════════════════════════════
# 2. 启动 Xvfb 虚拟显示器
# ═══════════════════════════════════════════
RESOLUTION="${RESOLUTION:-1280x720}"
echo "🖥️  启动虚拟显示器 (${RESOLUTION})..."
Xvfb :99 -screen 0 ${RESOLUTION}x24 -ac +extension RANDR &
XVFB_PID=$!
sleep 1

if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "❌ Xvfb 启动失败！"
    exit 1
fi
echo "   ✅ Xvfb PID=$XVFB_PID"

# ═══════════════════════════════════════════
# 3. 启动 x11vnc
# ═══════════════════════════════════════════
echo "📺 启动 x11vnc (端口 5900)..."
x11vnc -display :99 -forever -nopw -quiet -rfbport 5900 -listen 0.0.0.0 &
XVNC_PID=$!
sleep 1

if ! kill -0 $XVNC_PID 2>/dev/null; then
    echo "❌ x11vnc 启动失败！"
    exit 1
fi
echo "   ✅ x11vnc PID=$XVNC_PID"

# ═══════════════════════════════════════════
# 4. 启动 noVNC (Web 访问)
# ═══════════════════════════════════════════
echo "🌐 启动 noVNC (端口 6080)..."
websockify --web=/usr/share/novnc 6080 localhost:5900 &
NOVNC_PID=$!
sleep 1

if ! kill -0 $NOVNC_PID 2>/dev/null; then
    echo "❌ noVNC 启动失败！"
    exit 1
fi
echo "   ✅ noVNC PID=$NOVNC_PID"

# ═══════════════════════════════════════════
# 5. 环境信息
# ═══════════════════════════════════════════
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$DOTNET_ROOT:$PATH

echo ""
echo "📦 .NET: $(dotnet --version 2>/dev/null || echo 'N/A')"
echo "📦 Node.js: $(node --version)"
echo ""

# ═══════════════════════════════════════════
# 6. 启动 VRCX Electron
# ═══════════════════════════════════════════
echo "🚀 启动 VRCX Electron..."
echo "   📍 Web 访问: http://<你的IP>:6080"
echo ""

export DISPLAY=:99
export ELECTRON_DISABLE_SANDBOX=1

# 如需启用关系网/WebGL 功能，替换为:
#   --use-gl=angle --use-angle=swiftshader --disable-dev-shm-usage
export ELECTRON_EXTRA_LAUNCH_ARGS="--disable-gpu --disable-dev-shm-usage --disable-software-rasterizer"

cd /app
exec npx electron . \
    --no-sandbox \
    --disable-gpu \
    --disable-dev-shm-usage \
    --disable-software-rasterizer \
    2>&1 | tee /tmp/vrcx.log
