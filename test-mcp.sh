#!/bin/bash
# 测试 MCP Bridge 连接

echo "🧪 测试 MCP Bridge 连接"
echo "========================"

MCP_PORT=8765

# 测试 MCP 是否运行
echo ""
echo "1. 检查 MCP Bridge 是否运行..."
if curl -s "http://127.0.0.1:$MCP_PORT/mcp/tools/list" > /dev/null 2>&1; then
    echo "   ✅ MCP Bridge 运行正常"
    
    # 获取工具列表
    echo ""
    echo "2. 获取可用工具列表..."
    TOOLS=$(curl -s "http://127.0.0.1:$MCP_PORT/mcp/tools/list" | head -c 500)
    echo "   返回数据: $TOOLS"
else
    echo "   ❌ MCP Bridge 未运行"
    echo "   请运行: ./start-with-mcp.sh start"
    exit 1
fi

# 测试 AlphaBot 后端
echo ""
echo "3. 检查 AlphaBot 后端..."
if curl -s "http://localhost:8000/health" > /dev/null 2>&1; then
    echo "   ✅ AlphaBot 后端运行正常"
else
    echo "   ❌ AlphaBot 后端未运行"
fi

# 测试前端
echo ""
echo "4. 检查 AlphaBot 前端..."
if curl -s "http://localhost:3000" > /dev/null 2>&1; then
    echo "   ✅ AlphaBot 前端运行正常"
else
    echo "   ❌ AlphaBot 前端未运行"
fi

echo ""
echo "========================"
echo "测试完成！"
