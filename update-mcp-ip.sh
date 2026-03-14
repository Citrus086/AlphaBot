#!/bin/bash
# 自动更新 MCP 配置中的宿主机 IP

# 获取当前 IP（优先 en0 或 WLAN 接口）
CURRENT_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)

if [ -z "$CURRENT_IP" ]; then
    echo "❌ 无法获取 IP 地址"
    exit 1
fi

echo "🔄 检测到当前 IP: $CURRENT_IP"

# 更新 mcp_servers.yml
MCP_CONFIG="/Users/mima0000/alphabot/backend/app/config/mcp_servers.yml"

if [ -f "$MCP_CONFIG" ]; then
    # 备份原配置
    cp "$MCP_CONFIG" "$MCP_CONFIG.bak"
    
    # 替换 IP 地址（保留 /mcp 路径）
    sed -i '' "s|base_url: http://[0-9.]*:8765|base_url: http://${CURRENT_IP}:8765|" "$MCP_CONFIG"
    
    echo "✅ 已更新 MCP 配置: $CURRENT_IP:8765"
    
    # 显示配置内容
    echo ""
    echo "当前配置:"
    grep "base_url" "$MCP_CONFIG"
    
    # 重启后端服务
    echo ""
    echo "🔄 正在重启 AlphaBot 后端..."
    cd /Users/mima0000/alphabot
    docker-compose restart backend
    
    echo ""
    echo "✅ 完成！MCP 配置已更新并重启"
else
    echo "❌ 找不到配置文件: $MCP_CONFIG"
    exit 1
fi
