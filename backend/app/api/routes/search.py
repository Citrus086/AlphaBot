from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional, Dict, Any
from pydantic import BaseModel

from app.services.search_service import search_service
from app.api.dependencies import check_web_search_limit
from app.core.config import settings
from app.middleware.logging import logger
router = APIRouter()

class SearchConfigResponse(BaseModel):
    enabled: bool
    engine: str
    points_required: int = 1000

@router.get("/config", response_model=SearchConfigResponse)
async def get_search_config():
    """
    获取搜索功能配置状态
    """
    return SearchConfigResponse(
        enabled=settings.SEARCH_API_ENABLED,
        engine=settings.SEARCH_ENGINE,
        points_required=1000
    )

class SearchResponse(BaseModel):
    success: bool
    query: Optional[str] = None
    results: list
    result_count: int
    timestamp: str
    engine: str
    error: Optional[str] = None

@router.get("/web", response_model=SearchResponse)
async def search_web(
    query: str = Query(..., description="搜索查询"),
    limit: int = Query(5, ge=1, le=10, description="结果数量限制"),
    enable_mcp: bool = Query(True, description="是否启用 MCP 搜索"),
    _: None = Depends(check_web_search_limit)
):
    """
    执行网络搜索
    """
    # 执行搜索
    search_results = await search_service.search(query, limit, enable_mcp)
    
    # 如果搜索失败但返回了结构化响应，直接返回
    if not search_results.get("success", False):
        return search_results
    
    return search_results 