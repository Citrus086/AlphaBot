#!/bin/bash
# AlphaBot + MCP 一键启动脚本

set -e  # 出错时停止

echo "🚀 AlphaBot + MCP 启动脚本"
echo "=========================="

# 配置
MCP_PORT=8765
MCP_PID_FILE="/tmp/mcporter-bridge.pid"
PROJECT_DIR="/Users/mima0000/alphabot"
MCP_DIR="/Users/mima0000/mcporter-bridge"

# 从 .env 读取端口配置（默认值与 docker-compose.yml 一致）
eval $(grep -E "^(BACKEND_PORT|FRONTEND_PORT|REDIS_PORT)=" "$PROJECT_DIR/.env" 2>/dev/null)
BACKEND_PORT=${BACKEND_PORT:-8888}
FRONTEND_PORT=${FRONTEND_PORT:-8889}
REDIS_PORT=${REDIS_PORT:-6379}

# 检查 MCP 目录
if [ ! -d "$MCP_DIR" ]; then
    echo "❌ 错误: 未找到 mcporter-bridge 目录: $MCP_DIR"
    exit 1
fi

# 函数：检查 Docker
check_docker() {
    echo ""
    echo "🐳 检查 Docker..."
    
    # 检查 docker 命令是否存在
    if ! command -v docker &> /dev/null; then
        echo "❌ 错误: 未找到 Docker"
        echo ""
        echo "请先安装 Docker Desktop:"
        echo "https://www.docker.com/products/docker-desktop"
        echo ""
        osascript -e 'display dialog "请先安装 Docker Desktop" buttons {"确定"} default button "确定" with icon stop' 2>/dev/null || true
        exit 1
    fi
    
    # 检查 Docker 是否正在运行
    if ! docker info > /dev/null 2>&1; then
        echo "❌ 错误: Docker 未运行"
        echo ""
        echo "请启动 Docker Desktop 应用"
        echo ""
        
        # 尝试打开 Docker Desktop
        osascript -e 'display dialog "请先启动 Docker Desktop 应用" buttons {"打开 Docker", "取消"} default button "打开 Docker"' 2>/dev/null | grep -q "打开 Docker"
        if [ $? -eq 0 ]; then
            echo "正在打开 Docker Desktop..."
            open -a "Docker Desktop"
            
            # 等待 Docker 启动
            echo "等待 Docker 启动..."
            for i in {1..60}; do
                if docker info > /dev/null 2>&1; then
                    echo "✅ Docker 已启动"
                    return 0
                fi
                sleep 1
                echo -n "."
            done
            echo ""
            echo "❌ Docker 启动超时，请手动启动后重试"
            exit 1
        else
            exit 1
        fi
    fi
    
    echo "✅ Docker 运行正常"
}

# 函数：检查 MCP 是否运行
check_mcp_running() {
    if [ -f "$MCP_PID_FILE" ]; then
        MCP_PID=$(cat "$MCP_PID_FILE" 2>/dev/null)
        if ps -p "$MCP_PID" > /dev/null 2>&1; then
            # 检查端口是否可访问
            if curl -s "http://127.0.0.1:$MCP_PORT/mcp/tools/list" > /dev/null 2>&1; then
                return 0  # 正在运行
            fi
        fi
    fi
    return 1  # 未运行
}

# 函数：检查是否安装了 mcporter-bridge
has_mcporter_bridge() {
    [ -d "$MCP_DIR/.venv" ] && [ -f "$MCP_DIR/src/mcporter_bridge/__init__.py" ]
}

# 函数：更新 MCP 配置中的 IP 地址
update_mcp_ip() {
    local mcp_config="$PROJECT_DIR/backend/app/config/mcp_servers.yml"
    if [ ! -f "$mcp_config" ]; then
        return 0
    fi
    
    # 获取当前 IP
    local current_ip=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
    if [ -z "$current_ip" ]; then
        return 0
    fi
    
    # 检查配置中是否有 mcporter_bridge 配置
    if ! grep -q "mcporter_bridge" "$mcp_config" 2>/dev/null; then
        return 0
    fi
    
    # 提取当前配置中的 IP
    local config_ip=$(grep -oE "base_url: http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:8765" "$mcp_config" 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -1)
    
    # 如果配置中有 YOUR_HOST_IP 占位符，替换为当前 IP
    if grep -q "YOUR_HOST_IP" "$mcp_config" 2>/dev/null; then
        sed -i '' "s|YOUR_HOST_IP|$current_ip|g" "$mcp_config" 2>/dev/null
        echo "   🔄 已更新 MCP 配置中的 IP: $current_ip"
        return 0
    fi
    
    # 如果配置中的 IP 与当前 IP 不同，更新它
    if [ -n "$config_ip" ] && [ "$config_ip" != "$current_ip" ]; then
        sed -i '' "s|base_url: http://$config_ip:8765|base_url: http://$current_ip:8765|" "$mcp_config" 2>/dev/null
        echo "   🔄 检测到 IP 变化: $config_ip → $current_ip，已自动更新 MCP 配置"
    fi
}

# 函数：启动 MCP（可选）
start_mcp() {
    echo ""
    echo "📦 步骤 1/4: 检查 MCP Bridge..."
    
    # 更新 MCP 配置中的 IP（如果需要）
    update_mcp_ip
    
    # 检查是否安装了 mcporter-bridge
    if ! has_mcporter_bridge; then
        echo "   ⏭️  未检测到 mcporter-bridge，跳过 MCP 启动"
        echo "      如需使用 MCP 功能，请安装: https://github.com/yourusername/mcporter-bridge"
        return 0
    fi
    
    # 检查是否已在运行
    if check_mcp_running; then
        echo "   ✓ MCP Bridge 已在运行 (PID: $(cat $MCP_PID_FILE))"
        return 0
    fi
    
    # 启动 MCP Bridge（后台运行）
    cd "$MCP_DIR"
    export PYTHONPATH="$MCP_DIR/src:$PYTHONPATH"
    
    # 使用 nohup 在后台启动，输出到日志文件
    # --host 0.0.0.0 允许 Docker 容器访问
    nohup "$MCP_DIR/.venv/bin/python3" -m mcporter_bridge \
        --transport http \
        --host 0.0.0.0 \
        --port $MCP_PORT \
        > /tmp/mcporter-bridge.log 2>&1 &
    
    MCP_PID=$!
    echo $MCP_PID > "$MCP_PID_FILE"
    
    # 等待服务就绪
    echo "   ⏳ 等待 MCP Bridge 就绪..."
    for i in {1..30}; do
        if curl -s "http://127.0.0.1:$MCP_PORT/mcp/tools/list" > /dev/null 2>&1; then
            echo "   ✓ MCP Bridge 已启动 (PID: $MCP_PID, 端口: $MCP_PORT)"
            return 0
        fi
        sleep 1
        echo -n "."
    done
    
    echo ""
    echo "   ⚠️  MCP Bridge 启动超时，AlphaBot 将在无 MCP 功能的情况下启动"
    echo "   日志: tail -f /tmp/mcporter-bridge.log"
    return 0
}

# 函数：检查端口是否被占用
check_port() {
    local port=$1
    lsof -Pi :$port -sTCP:LISTEN -t > /dev/null 2>&1
}

# 函数：智能清理（只在端口冲突时）
smart_cleanup() {
    echo ""
    echo "🧹 检查端口占用..."
    
    cd "$PROJECT_DIR"
    
    local need_cleanup=false
    
    # 检查关键端口（后端 $BACKEND_PORT，前端 $FRONTEND_PORT）
    if check_port $BACKEND_PORT; then
        echo "   ⚠️ 端口 $BACKEND_PORT (后端) 被占用"
        need_cleanup=true
    fi
    
    if check_port $FRONTEND_PORT; then
        echo "   ⚠️ 端口 $FRONTEND_PORT (前端) 被占用"
        need_cleanup=true
    fi
    
    if check_port $REDIS_PORT; then
        echo "   ⚠️ 端口 6379 (Redis) 被占用"
        need_cleanup=true
    fi
    
    # 如果有端口冲突，尝试清理
    if [ "$need_cleanup" = true ]; then
        echo "   检测到端口冲突，尝试清理旧容器..."
        
        # 尝试优雅地停止
        docker-compose down 2>/dev/null || true
        
        # 等待一下
        sleep 2
        
        # 如果还有端口被占用，强制删除
        if check_port $BACKEND_PORT || check_port $FRONTEND_PORT || check_port $REDIS_PORT; then
            echo "   强制清理占用端口的容器..."
            docker rm -f alphabot-backend alphabot-frontend alphabot-redis alphabot-celery 2>/dev/null || true
            sleep 1
        fi
        
        # 再次检查
        if check_port $BACKEND_PORT || check_port $FRONTEND_PORT || check_port $REDIS_PORT; then
            echo "   ⚠️ 警告: 端口仍被占用，可能是其他程序"
            echo "   被占用的端口:"
            lsof -Pi :$BACKEND_PORT -sTCP:LISTEN 2>/dev/null | tail -1
            lsof -Pi :$FRONTEND_PORT -sTCP:LISTEN 2>/dev/null | tail -1
            lsof -Pi :6379 -sTCP:LISTEN 2>/dev/null | tail -1
        else
            echo "   ✓ 端口已释放"
        fi
    else
        echo "   ✓ 端口未被占用，无需清理"
    fi
}

# 函数：启动 AlphaBot
start_alphabot() {
    echo ""
    echo "🤖 步骤 2/4: 启动 AlphaBot..."
    
    cd "$PROJECT_DIR"
    
    # 智能清理（只在端口冲突时）
    smart_cleanup
    
    # 检查 .env 文件
    if [ ! -f "./.env" ]; then
        echo "   ⚠️ 警告: 未找到 .env 文件"
        if [ -f "./.env.example" ]; then
            echo "   正在从示例创建..."
            cp ./.env.example ./.env
        fi
    fi
    
    # 启动服务
    if ! docker-compose up -d; then
        echo "   ❌ Docker 启动失败"
        echo "   请检查:"
        echo "   1. Docker Desktop 是否运行"
        echo "   2. docker-compose.yml 是否存在"
        exit 1
    fi
    
    echo "   ✓ AlphaBot 容器已启动"
}

# 函数：等待服务就绪
wait_services() {
    echo ""
    echo "⏳ 步骤 3/4: 等待服务就绪..."
    
    # 等待后端
    echo -n "   等待后端 ($BACKEND_PORT)..."
    for i in {1..60}; do
        if curl -s "http://localhost:$BACKEND_PORT/health" > /dev/null 2>&1; then
            echo " ✅"
            break
        fi
        sleep 1
        echo -n "."
        if [ $i -eq 60 ]; then
            echo ""
            echo "   ⚠️ 后端启动超时，但可能仍在启动中"
        fi
    done
    
    # 等待前端
    echo -n "   等待前端 ($FRONTEND_PORT)..."
    for i in {1..60}; do
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$FRONTEND_PORT" | grep -q "200\|307\|302"; then
            echo " ✅"
            break
        fi
        sleep 1
        echo -n "."
        if [ $i -eq 60 ]; then
            echo ""
            echo "   ⚠️ 前端启动超时，但可能仍在启动中"
        fi
    done
}

# 函数：打开浏览器
open_browser() {
    echo ""
    echo "🌐 步骤 4/4: 打开浏览器..."
    
    # 最终检查
    echo "   检查服务状态..."
    
    local backend_ok=false
    local frontend_ok=false
    
    if curl -s "http://localhost:$BACKEND_PORT/health" > /dev/null 2>&1; then
        backend_ok=true
        echo "   ✅ 后端: http://localhost:$BACKEND_PORT"
    else
        echo "   ⚠️ 后端: 未就绪"
    fi
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$FRONTEND_PORT" | grep -q "200\|307\|302"; then
        frontend_ok=true
        echo "   ✅ 前端: http://localhost:$FRONTEND_PORT"
    else
        echo "   ⚠️ 前端: 未就绪"
    fi
    
    echo ""
    echo "✅ 启动完成！"
    echo "=========================="
    echo ""
    echo "📱 前端界面: http://localhost:$FRONTEND_PORT"
    echo "📡 后端 API: http://localhost:$BACKEND_PORT/api/v1/docs"
    echo "🔌 MCP Bridge: http://127.0.0.1:$MCP_PORT"
    echo ""
    # 读取 .env 中的管理员账号信息
    if [ -f "$PROJECT_DIR/.env" ]; then
        ADMIN_USER=$(grep "^ADMIN_USERNAME=" "$PROJECT_DIR/.env" | cut -d'"' -f2)
        echo "👤 登录账号: ${ADMIN_USER:-admin}"
        echo "🔐 密码: 见 .env 文件中的 ADMIN_PASSWORD"
        echo ""
    fi
    
    if [ "$frontend_ok" = true ]; then
        echo "正在打开浏览器..."
        sleep 2
        open "http://localhost:$FRONTEND_PORT"
    else
        echo "⚠️ 服务可能还在启动中，请稍后手动刷新浏览器"
        echo "   或运行: open http://localhost:$FRONTEND_PORT"
    fi
}

# 函数：显示状态
show_status() {
    echo ""
    echo "📊 服务状态"
    echo "=========================="
    
    # MCP 状态
    if check_mcp_running; then
        echo "✅ MCP Bridge: 运行中 (PID: $(cat $MCP_PID_FILE))"
    else
        echo "❌ MCP Bridge: 未运行"
    fi
    
    # Docker 状态
    cd "$PROJECT_DIR"
    if docker-compose ps 2>/dev/null | grep -q "Up"; then
        echo "✅ AlphaBot Docker: 运行中"
        docker-compose ps 2>/dev/null | grep -E "alphabot-" || true
    else
        echo "❌ AlphaBot Docker: 未运行"
    fi
    
    # 端口检查
    echo ""
    echo "端口检查:"
    if lsof -Pi :$FRONTEND_PORT -sTCP:LISTEN -t > /dev/null 2>&1; then
        echo "   ✅ $FRONTEND_PORT (前端)"
    else
        echo "   ❌ $FRONTEND_PORT (前端)"
    fi
    if lsof -Pi :$BACKEND_PORT -sTCP:LISTEN -t > /dev/null 2>&1; then
        echo "   ✅ $BACKEND_PORT (后端)"
    else
        echo "   ❌ $BACKEND_PORT (后端)"
    fi
    if lsof -Pi :8765 -sTCP:LISTEN -t > /dev/null 2>&1; then
        echo "   ✅ 8765 (MCP)"
    else
        echo "   ❌ 8765 (MCP)"
    fi
}

# 主逻辑
case "${1:-start}" in
    start)
        check_docker
        start_mcp
        start_alphabot
        wait_services
        open_browser
        show_status
        ;;
    stop)
        echo "🛑 停止所有服务..."
        
        # 停止 MCP
        if [ -f "$MCP_PID_FILE" ]; then
            MCP_PID=$(cat "$MCP_PID_FILE" 2>/dev/null)
            if ps -p "$MCP_PID" > /dev/null 2>&1; then
                kill "$MCP_PID" 2>/dev/null || true
                echo "✅ MCP Bridge 已停止"
            fi
            rm -f "$MCP_PID_FILE"
        fi
        
        # 停止 AlphaBot
        cd "$PROJECT_DIR"
        docker-compose down 2>/dev/null || echo "AlphaBot 未运行"
        echo "✅ AlphaBot 已停止"
        ;;
    status)
        show_status
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    logs)
        echo "📋 MCP Bridge 日志:"
        tail -n 50 /tmp/mcporter-bridge.log 2>/dev/null || echo "暂无日志"
        echo ""
        echo "📋 AlphaBot Docker 日志:"
        cd "$PROJECT_DIR"
        docker-compose logs --tail=20
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "命令:"
        echo "  start   - 启动 MCP + AlphaBot"
        echo "  stop    - 停止所有服务"
        echo "  restart - 重启所有服务"
        echo "  status  - 查看服务状态"
        echo "  logs    - 查看日志"
        exit 1
        ;;
esac
