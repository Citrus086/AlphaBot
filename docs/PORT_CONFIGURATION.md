# 端口配置指南

AlphaBot 支持通过 `.env` 文件自定义端口，避免与其他服务冲突。

## 🚀 快速开始

默认端口（无需修改即可使用）：
- **后端 API**: 8888
- **前端界面**: 8889
- **Redis**: 6379
- **MCP Bridge**: 8765（可选）

## 📝 修改端口

编辑项目根目录下的 `.env` 文件：

```bash
# 端口配置（如果有冲突可以修改）
# 修改后需要重新启动: docker-compose down && docker-compose up -d
BACKEND_PORT=8888      # 后端API端口
FRONTEND_PORT=8889     # 前端端口
REDIS_PORT=6379        # Redis端口（一般不用改）
```

## 🔧 常见场景

### 场景 1：端口 8888 被占用

```bash
# .env
BACKEND_PORT=8080      # 改成 8080
```

重启后访问：http://localhost:8080

### 场景 2：端口 8889 被占用

```bash
# .env
FRONTEND_PORT=3000     # 改成 3000
```

重启后访问：http://localhost:3000

### 场景 3：多个端口冲突

```bash
# .env
BACKEND_PORT=8080
FRONTEND_PORT=3000
REDIS_PORT=6380
```

## 🔄 重启服务

修改 `.env` 后必须重启：

```bash
./start-with-mcp.sh restart
```

或手动：

```bash
docker-compose down
docker-compose up -d
```

## 🌐 MCP Bridge 端口

MCP Bridge 使用 **8765** 端口（固定，不需要修改）。

如果你的 8765 被占用，需要修改 `start-with-mcp.sh`：

```bash
MCP_PORT=8766  # 改成其他端口
```

同时更新 `mcp_servers.yml`：

```yaml
base_url: http://192.168.0.102:8766/mcp
```

## 📝 配置优先级

1. `.env` 文件中的配置最高
2. 如果 `.env` 中没有，使用默认值
3. 修改后必须重启 Docker 容器

## 🐛 故障排查

### 检查端口占用

```bash
# macOS
lsof -Pi :8888 -sTCP:LISTEN

# Linux
netstat -tlnp | grep 8888
```

### 查看当前使用的端口

```bash
# 查看 .env 配置
grep -E "PORT=" .env

# 查看 Docker 实际映射的端口
docker-compose ps
```

### 端口冲突错误

如果启动时出现：
```
Error starting userland proxy: listen tcp 0.0.0.0:8888: bind: address already in use
```

解决步骤：
1. 找到占用端口的进程：`lsof -Pi :8888`
2. 停止该进程，或修改 `.env` 使用其他端口
3. 重启 AlphaBot

## 📚 相关文件

- `.env` - 端口配置文件
- `docker-compose.yml` - Docker 端口映射（自动读取 .env）
- `start-with-mcp.sh` - 启动脚本（自动读取 .env）
