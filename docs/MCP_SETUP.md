# MCP (Model Context Protocol) 配置指南

AlphaBot 支持作为 MCP Host，可以连接多个外部的 MCP 服务器来扩展功能。

## 🚀 快速开始

### 1. 了解 MCP

MCP (Model Context Protocol) 是一种开放协议，允许 AI 助手通过标准化的接口调用外部工具和服务。

### 2. 配置 MCP 服务器

复制示例配置文件：

```bash
cp backend/app/config/mcp_servers.yml.example backend/app/config/mcp_servers.yml
```

编辑 `mcp_servers.yml`，添加你想要连接的 MCP 服务器：

```yaml
servers:
  # 示例：本地 Playwright MCP 服务器
  - id: playwright
    base_url: http://host.docker.internal:3000/mcp

  # 示例：远程 Notion MCP 服务器（需要认证）
  - id: notion
    base_url: https://mcp.notion.com/mcp
    api_key: ${NOTION_API_KEY}
```

### 3. 重启服务

```bash
./start-with-mcp.sh restart
```

### 4. 验证连接

```bash
curl http://localhost:8888/api/v1/agent/tools
```

你应该能看到所有可用的 MCP 工具列表。

## 🔧 支持的 MCP 服务器类型

### 1. 本地 MCP 服务器（stdio 模式）

需要通过 HTTP bridge 暴露为 HTTP 接口：

```bash
# 启动 HTTP bridge
your-mcp-server --transport http --port 3000
```

配置：
```yaml
servers:
  - id: local_mcp
    base_url: http://host.docker.internal:3000/mcp
```

**注意**：`host.docker.internal` 在 Docker Desktop 中指向宿主机。Linux 用户可能需要使用宿主机的实际 IP。

### 2. 远程 MCP 服务器（HTTP/SSE 模式）

直接配置 URL：

```yaml
servers:
  - id: notion
    base_url: https://mcp.notion.com/mcp
    api_key: ${NOTION_API_KEY}
```

### 3. Docker 容器中的 MCP 服务器

如果 MCP 服务器也在 Docker 中，使用容器名：

```yaml
servers:
  - id: playwright
    base_url: http://playwright-mcp:3000/mcp
```

## 📝 配置详解

### 字段说明

| 字段 | 必填 | 说明 |
|-----|------|------|
| `id` | ✅ | 服务器的唯一标识，只能包含字母、数字、下划线、中划线 |
| `base_url` | ✅ | MCP 服务器的 HTTP 端点 URL，必须以 `/mcp` 结尾 |
| `api_key` | ❌ | 如果服务器需要认证，填写 API key |

### 环境变量支持

支持 `${ENV_VAR}` 语法：

```yaml
servers:
  - id: my_mcp
    base_url: ${MY_MCP_URL}
    api_key: ${MY_MCP_API_KEY}
```

在 `.env` 文件中定义：
```bash
MY_MCP_URL=http://localhost:3000/mcp
MY_MCP_API_KEY=sk-xxxxxx
```

## 🌐 常见 MCP 服务器

### Playwright (浏览器自动化)

```bash
# 安装
npm install -g @playwright/mcp

# 启动 HTTP 服务器
playwright-mcp --transport http --port 3000
```

配置：
```yaml
servers:
  - id: playwright
    base_url: http://host.docker.internal:3000/mcp
```

### GitHub

```yaml
servers:
  - id: github
    base_url: https://api.githubcopilot.com/mcp
    api_key: ${GITHUB_TOKEN}
```

### 自定义 MCP 服务器

任何符合 [MCP 规范](https://modelcontextprotocol.io) 的 HTTP 服务器都可以连接。

## 🔍 故障排查

### 1. 检查 MCP 服务器是否可达

```bash
# 从宿主机测试
curl http://localhost:3000/mcp

# 从 Docker 容器测试
docker exec alphabot-backend python -c "
import urllib.request
print(urllib.request.urlopen('http://host.docker.internal:3000/mcp').read()[:100])
"
```

### 2. 查看 AlphaBot 日志

```bash
docker logs alphabot-backend | grep -i mcp
```

你应该看到类似：
```
INFO:     MCP Host: loaded 2 servers
INFO:     MCP Host: server playwright discovered 5 tools
INFO:     MCP Host: server notion discovered 8 tools
```

### 3. 工具未显示在列表中

检查：
- MCP 服务器是否正常运行
- `base_url` 是否正确（必须以 `/mcp` 结尾）
- Docker 容器是否能访问该地址
- 是否需要认证（`api_key`）

## 🧩 开发者指南

### 为 AlphaBot 添加自定义 MCP 工具

1. 创建一个符合 MCP 规范的 HTTP 服务器
2. 在 `mcp_servers.yml` 中添加配置
3. 重启 AlphaBot

工具会自动被发现并可供 AI 助手调用。

### 工具命名规则

为了避免冲突，MCP 工具名会被转换为：
- 原始名：`server_id.tool_name`
- LLM 友好名：`server_id_tool_name`（替换非法字符）

## 📚 参考

- [MCP 官方文档](https://modelcontextprotocol.io)
- [FastMCP 文档](https://github.com/modelcontextprotocol/python-sdk)
