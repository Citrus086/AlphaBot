#!/bin/bash
# AlphaBot 故障诊断脚本

echo "🔧 AlphaBot 故障诊断"
echo "====================="
echo ""

# 1. 检查 Docker
echo "1. 检查 Docker..."
if command -v docker &> /dev/null; then
    echo "   ✅ Docker 命令已安装"
    if docker info > /dev/null 2>&1; then
        echo "   ✅ Docker 正在运行"
    else
        echo "   ❌ Docker 未运行！"
        echo "      请启动 Docker Desktop 应用"
        exit 1
    fi
else
    echo "   ❌ Docker 未安装！"
    echo "      请访问: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# 2. 检查容器状态
echo ""
echo "2. 检查容器状态..."
cd "$(dirname "$0")"
docker-compose ps

# 3. 检查端口占用
echo ""
echo "3. 检查端口占用..."
echo "   端口 3000 (前端):"
if lsof -Pi :3000 -sTCP:LISTEN -t &> /dev/null; then
    echo "      被进程占用: $(lsof -Pi :3000 -sTCP:LISTEN | tail -1)"
else
    echo "      未被占用"
fi

echo "   端口 8000 (后端):"
if lsof -Pi :8000 -sTCP:LISTEN -t &> /dev/null; then
    echo "      被进程占用: $(lsof -Pi :8000 -sTCP:LISTEN | tail -1)"
else
    echo "      未被占用"
fi

echo "   端口 8765 (MCP):"
if lsof -Pi :8765 -sTCP:LISTEN -t &> /dev/null; then
    echo "      被进程占用: $(lsof -Pi :8765 -sTCP:LISTEN | tail -1)"
else
    echo "      未被占用"
fi

# 4. 检查服务是否可访问
echo ""
echo "4. 检查服务响应..."

echo -n "   后端 (8000): "
if curl -s "http://localhost:8000/health" > /dev/null 2>&1; then
    echo "✅ 正常"
else
    echo "❌ 无法访问"
fi

echo -n "   前端 (3000): "
if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000" | grep -q "200\|307\|302"; then
    echo "✅ 正常"
else
    echo "❌ 无法访问"
fi

echo -n "   MCP (8765): "
if curl -s "http://127.0.0.1:8765/mcp/tools/list" > /dev/null 2>&1; then
    echo "✅ 正常"
else
    echo "❌ 无法访问"
fi

# 5. 检查日志
echo ""
echo "5. 最近的错误日志:"
echo "   Docker 日志:"
docker-compose logs --tail=5 2>/dev/null || echo "   无法获取"

echo ""
echo "====================="
echo "诊断完成！"
echo ""
echo "常见问题:"
echo "1. 如果 Docker 未运行 → 启动 Docker Desktop"
echo "2. 如果端口被占用 → 停止占用端口的程序"
echo "3. 如果服务无法访问 → 查看日志: ./start-with-mcp.sh logs"
