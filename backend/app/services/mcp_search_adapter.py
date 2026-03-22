"""
MCP 搜索适配器 - 将 MCP 搜索工具集成到 SearchService

自动发现和调用 MCP 中的搜索工具（如 web-search-prime、exa 等）
"""

import asyncio
from typing import Dict, Any, List, Optional
from app.core.mcp_host import McpHostRegistry
from app.middleware.logging import logger


class MCPSearchAdapter:
    """MCP 搜索适配器，自动发现和调用 MCP 搜索工具"""
    
    # 已知的搜索类 MCP 服务器名称（优先级顺序）
    KNOWN_SEARCH_SERVERS = [
        "web-search-prime",  # 智谱网页搜索
        "web_search_prime",
        "exa",               # Exa AI 搜索
        "web-search",
        "web_search",
        "search",
        "tavily",
        "bing-search",
        "brave-search",
    ]
    
    # 已知的搜索工具名称
    KNOWN_SEARCH_TOOLS = [
        "search",
        "web_search",
        "search_web",
        "query",
    ]
    
    def __init__(self):
        self._search_server_cache: Optional[str] = None
        self._search_tool_cache: Optional[str] = None
        self._initialized = False
    
    def _find_search_server(self) -> Optional[Dict[str, str]]:
        """
        在 MCP 服务器中查找可用的搜索服务器
        
        Returns:
            {"server": str, "tool": str} 或 None
        """
        # 首先检查缓存
        if self._search_server_cache and self._search_tool_cache:
            # 验证缓存是否仍然有效
            entry = McpHostRegistry.get_tool(
                f"{self._search_server_cache}.{self._search_tool_cache}"
            )
            if entry:
                return {
                    "server": self._search_server_cache,
                    "tool": self._search_tool_cache
                }
        
        # 获取所有 MCP 工具
        mcp_tools = McpHostRegistry.list_tools()
        
        # 按优先级查找已知搜索服务器
        for server_name in self.KNOWN_SEARCH_SERVERS:
            for full_name, entry in mcp_tools.items():
                server_id = entry.get("server_id", "")
                if server_id == server_name or server_id.startswith(f"{server_name}-"):
                    tool_def = entry.get("tool", {})
                    tool_name = tool_def.get("name", "")
                    
                    # 缓存结果
                    self._search_server_cache = server_id
                    self._search_tool_cache = tool_name
                    
                    logger.info(f"找到 MCP 搜索服务器: {server_id}/{tool_name}")
                    return {"server": server_id, "tool": tool_name}
        
        # 如果没找到已知服务器，尝试查找任何带有搜索关键词的服务器
        for full_name, entry in mcp_tools.items():
            server_id = entry.get("server_id", "").lower()
            tool_def = entry.get("tool", {})
            tool_name = tool_def.get("name", "").lower()
            
            # 检查服务器名或工具名是否包含搜索关键词
            if any(keyword in server_id for keyword in ["search", "web"]):
                self._search_server_cache = entry.get("server_id")
                self._search_tool_cache = tool_def.get("name")
                
                logger.info(f"找到 MCP 搜索服务器(模糊匹配): {self._search_server_cache}/{self._search_tool_cache}")
                return {
                    "server": self._search_server_cache,
                    "tool": self._search_tool_cache
                }
        
        return None
    
    async def search(self, query: str, limit: int = 5) -> Optional[Dict[str, Any]]:
        """
        使用 MCP 搜索工具执行搜索
        
        Args:
            query: 搜索查询
            limit: 结果数量限制
            
        Returns:
            搜索结果字典，如果没有可用的 MCP 搜索工具则返回 None
        """
        try:
            # 查找可用的搜索服务器
            search_config = self._find_search_server()
            if not search_config:
                logger.debug("没有找到可用的 MCP 搜索服务器")
                return None
            
            server = search_config["server"]
            tool = search_config["tool"]
            
            # 构建搜索参数（根据不同服务器适配）
            params = self._build_search_params(server, tool, query, limit)
            
            # 通过 MCP Host 调用工具
            logger.info(f"使用 MCP 搜索: {server}/{tool}, query={query}")
            
            # 构造工具调用参数
            call_params = {
                "server_name": server,
                "tool_name": tool,
                "arguments": params
            }
            
            # 调用 MCP 工具
            from app.services.agent_service import AgentService
            result = await AgentService._execute_mcp_tool(
                "mcporter_bridge.mcporter_call_tool", 
                call_params
            )
            
            # 解析结果
            return self._parse_search_result(result, query)
            
        except Exception as e:
            logger.error(f"MCP 搜索失败: {e}")
            return None
    
    def _build_search_params(self, server: str, tool: str, query: str, limit: int) -> Dict[str, Any]:
        """
        根据不同搜索服务器构建参数
        """
        server_lower = server.lower()
        
        # 智谱 web-search-prime
        if "web-search-prime" in server_lower or "web_search_prime" in server_lower:
            return {
                "query": query,
                "count": limit
            }
        
        # Exa 搜索
        if "exa" in server_lower:
            return {
                "query": query,
                "num_results": limit
            }
        
        # 通用参数格式
        return {
            "query": query,
            "limit": limit
        }
    
    def _parse_search_result(self, result: Dict[str, Any], query: str) -> Optional[Dict[str, Any]]:
        """
        解析 MCP 搜索结果为标准格式
        """
        try:
            # 处理错误
            if "error" in result:
                logger.error(f"MCP 搜索返回错误: {result['error']}")
                return None
            
            # 提取内容（MCP 返回的通常是 content 数组）
            content = result.get("content", [])
            if not content:
                return None
            
            # 解析 JSON 结果
            search_data = None
            for item in content:
                if isinstance(item, dict) and "text" in item:
                    try:
                        import json
                        search_data = json.loads(item["text"])
                        break
                    except:
                        continue
            
            if not search_data:
                return None
            
            # 标准化结果格式
            results = []
            
            # 处理不同格式的返回结果
            if isinstance(search_data, list):
                for item in search_data[:5]:
                    results.append({
                        "title": item.get("title", item.get("name", "无标题")),
                        "link": item.get("url", item.get("link", "")),
                        "snippet": item.get("content", item.get("snippet", item.get("summary", ""))),
                        "source": "mcp"
                    })
            elif isinstance(search_data, dict):
                # 可能是包含 results 字段的对象
                items = search_data.get("results", search_data.get("items", search_data.get("data", [])))
                for item in items[:5]:
                    results.append({
                        "title": item.get("title", item.get("name", "无标题")),
                        "link": item.get("url", item.get("link", "")),
                        "snippet": item.get("content", item.get("snippet", item.get("summary", ""))),
                        "source": "mcp"
                    })
            
            if not results:
                return None
            
            return {
                "success": True,
                "query": query,
                "results": results,
                "result_count": len(results),
                "engine": "mcp"
            }
            
        except Exception as e:
            logger.error(f"解析 MCP 搜索结果失败: {e}")
            return None
    
    def is_available(self) -> bool:
        """检查是否有可用的 MCP 搜索工具"""
        return self._find_search_server() is not None


# 全局单例
mcp_search_adapter = MCPSearchAdapter()
