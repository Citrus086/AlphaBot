from pydantic_settings import BaseSettings, SettingsConfigDict
import os
from dotenv import load_dotenv
from typing import List, Literal

# 加载环境变量
load_dotenv()


class Settings(BaseSettings):
    """应用配置设置"""
    
    # 应用信息
    APP_NAME: str = "AI Stock Assistant API"
    API_V1_STR: str = "/api/v1"
    
    # 基础目录
    BASE_DIR: str = os.getenv("BASE_DIR", "./") 
    
    # 数据源配置
    # 可选值: "alphavantage", "tushare", "akshare", "hk_stock"
    DEFAULT_DATA_SOURCE: str = os.getenv("DEFAULT_DATA_SOURCE", "alphavantage")
    
    # Alpha Vantage API配置
    ALPHAVANTAGE_API_BASE_URL: str = os.getenv("ALPHAVANTAGE_API_BASE_URL", "https://www.alphavantage.co/query")
    ALPHAVANTAGE_API_KEY: str = os.getenv("ALPHAVANTAGE_API_KEY", "demo")
    
    # Tushare API配置
    TUSHARE_API_TOKEN: str = os.getenv("TUSHARE_API_TOKEN", "")
    
    # AKShare配置
    # AKShare 不需要 API 密钥，但可以配置一些参数
    AKSHARE_USE_PROXY: bool = os.getenv("AKSHARE_USE_PROXY", "False").lower() == "true"
    AKSHARE_PROXY_URL: str = os.getenv("AKSHARE_PROXY_URL", "")

    # 雪球配置（用于AKShare的部分接口）
    XUEQIU_TOKEN: str = os.getenv("XUEQIU_TOKEN", "")
    
    # 数据库配置
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./stock_assistant.db")
    
    # 搜索API配置
    SEARCH_API_ENABLED: bool = os.getenv("SEARCH_API_ENABLED", "True").lower() == "true"
    SEARCH_ENGINE: str = os.getenv("SEARCH_ENGINE", "serpapi") # 可选: serpapi, googleapi, bingapi
    SERPAPI_API_KEY: str = os.getenv("SERPAPI_API_KEY", "")
    SERPAPI_API_BASE_URL: str = os.getenv("SERPAPI_API_BASE_URL", "https://serpapi.com/search")
    GOOGLE_SEARCH_API_KEY: str = os.getenv("GOOGLE_SEARCH_API_KEY", "")
    GOOGLE_SEARCH_CX: str = os.getenv("GOOGLE_SEARCH_CX", "")
    GOOGLE_SEARCH_BASE_URL: str = os.getenv("GOOGLE_SEARCH_BASE_URL", "https://www.googleapis.com/customsearch/v1")
    BING_SEARCH_API_KEY: str = os.getenv("BING_SEARCH_API_KEY", "")
    BING_SEARCH_BASE_URL: str = os.getenv("BING_SEARCH_BASE_URL", "https://api.bing.microsoft.com/v7.0/search")
    
    # CORS配置 - 允许本地开发和Docker环境
    # 生产环境应通过环境变量 CORS_ORIGINS 配置，多个域名用逗号分隔
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:8000,http://frontend:3000,http://backend:8000")
    
    @property
    def cors_origins_list(self) -> list:
        """获取CORS起源列表"""
        if isinstance(self.CORS_ORIGINS, list):
            return self.CORS_ORIGINS
        return self.CORS_ORIGINS.split(",") if self.CORS_ORIGINS else []
    
    # 安全配置
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-for-development-only")
    
    # 管理员账户配置（用于初始化）
    ADMIN_USERNAME: str = os.getenv("ADMIN_USERNAME", "admin")
    ADMIN_EMAIL: str = os.getenv("ADMIN_EMAIL", "admin@example.com")
    ADMIN_PASSWORD: str = os.getenv("ADMIN_PASSWORD", "admin123")
    
    # AI分析配置（Phase 5 AnalysisModeRegistry）
    # 可选值: "rule", "ml", "llm"
    DEFAULT_ANALYSIS_MODE: str = os.getenv("DEFAULT_ANALYSIS_MODE", "rule")
    # Agent 工具白名单：逗号分隔，空则全部启用（Phase 5 ToolRegistry）
    ENABLED_AGENT_TOOLS: str = os.getenv("ENABLED_AGENT_TOOLS", "")
    
    # AI模型配置（传统本地模型）
    AI_MODEL_PATH: str = os.getenv("AI_MODEL_PATH", "./models/stock_analysis_model.pkl")

    # LLM 配置（LiteLLM 统一接口，无 OpenAI 兼容层）
    # 模型格式：provider/model_name，如 openai/gpt-4o-mini、deepseek/deepseek-chat
    LLM_MODEL: str = os.getenv("LLM_MODEL", "openai/gpt-4o-mini")
    LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")
    LLM_API_BASE: str = os.getenv("LLM_API_BASE", "https://api.openai.com/v1")
    LLM_MAX_TOKENS: int = int(os.getenv("LLM_MAX_TOKENS", "1000"))
    LLM_TEMPERATURE: float = float(os.getenv("LLM_TEMPERATURE", "0.7"))
    # 逗号分隔的可用模型列表，供前端/API 切换
    LLM_AVAILABLE_MODELS: str = os.getenv("LLM_AVAILABLE_MODELS", "")

    # 可选：多 profile LLM（为不同角色预留，未配置时回退到上面的默认值）
    LLM_DEFAULT_MODEL: str | None = os.getenv("LLM_DEFAULT_MODEL")
    LLM_DEFAULT_API_BASE: str | None = os.getenv("LLM_DEFAULT_API_BASE")
    LLM_DEFAULT_API_KEY: str | None = os.getenv("LLM_DEFAULT_API_KEY")
    LLM_DEFAULT_MAX_TOKENS: int = int(os.getenv("LLM_DEFAULT_MAX_TOKENS", "0"))
    LLM_DEFAULT_TEMPERATURE: float = float(os.getenv("LLM_DEFAULT_TEMPERATURE", "0"))

    LLM_RESEARCH_MODEL: str | None = os.getenv("LLM_RESEARCH_MODEL")
    LLM_RESEARCH_API_BASE: str | None = os.getenv("LLM_RESEARCH_API_BASE")
    LLM_RESEARCH_API_KEY: str | None = os.getenv("LLM_RESEARCH_API_KEY")
    LLM_RESEARCH_MAX_TOKENS: int = int(os.getenv("LLM_RESEARCH_MAX_TOKENS", "0"))
    LLM_RESEARCH_TEMPERATURE: float = float(os.getenv("LLM_RESEARCH_TEMPERATURE", "0"))

    LLM_RISK_MODEL: str | None = os.getenv("LLM_RISK_MODEL")
    LLM_RISK_API_BASE: str | None = os.getenv("LLM_RISK_API_BASE")
    LLM_RISK_API_KEY: str | None = os.getenv("LLM_RISK_API_KEY")
    LLM_RISK_MAX_TOKENS: int = int(os.getenv("LLM_RISK_MAX_TOKENS", "0"))
    LLM_RISK_TEMPERATURE: float = float(os.getenv("LLM_RISK_TEMPERATURE", "0"))

    # 长期记忆（向量库 Chroma）
    CHROMA_PERSIST_PATH: str = os.getenv("CHROMA_PERSIST_PATH", "./data/chroma")
    EMBEDDING_MODEL: str = os.getenv("EMBEDDING_MODEL", "text-embedding-3-small")
    # Embedding 独立 provider（可选，未配置时回退到 LLM_API_*）
    EMBEDDING_API_BASE: str = os.getenv("EMBEDDING_API_BASE", "")
    EMBEDDING_API_KEY: str = os.getenv("EMBEDDING_API_KEY", "")
    
    # 请求频率限制配置
    RATE_LIMIT_ENABLED: bool = os.getenv("RATE_LIMIT_ENABLED", "True").lower() == "true"
    # 默认限制：每分钟60个请求
    RATE_LIMIT_DEFAULT_MINUTE: int = int(os.getenv("RATE_LIMIT_DEFAULT_MINUTE", "60"))
    # 搜索API限制：每分钟30个请求
    RATE_LIMIT_SEARCH_MINUTE: int = int(os.getenv("RATE_LIMIT_SEARCH_MINUTE", "30"))
    # 股票详情API限制：每分钟20个请求
    RATE_LIMIT_STOCK_INFO_MINUTE: int = int(os.getenv("RATE_LIMIT_STOCK_INFO_MINUTE", "20"))
    # AI分析API限制：每分钟10个请求
    RATE_LIMIT_AI_ANALYSIS_MINUTE: int = int(os.getenv("RATE_LIMIT_AI_ANALYSIS_MINUTE", "10"))
    # 后台任务API限制：每分钟5个请求
    RATE_LIMIT_TASK_MINUTE: int = int(os.getenv("RATE_LIMIT_TASK_MINUTE", "5"))
    
    # Celery配置
    CELERY_BROKER_URL: str = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")
    CELERY_RESULT_BACKEND: str = os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/0")
    CELERY_TASK_TRACK_STARTED: bool = True
    CELERY_TASK_TIME_LIMIT: int = 600  # 10分钟任务超时
    CELERY_WORKER_MAX_TASKS_PER_CHILD: int = 200  # 防止内存泄漏
    
    # 飞书 / Telegram 渠道配置（可选）
    FEISHU_APP_ID: str = os.getenv("FEISHU_APP_ID", "")
    FEISHU_APP_SECRET: str = os.getenv("FEISHU_APP_SECRET", "")
    FEISHU_API_BASE: str = os.getenv("FEISHU_API_BASE", "https://open.feishu.cn")
    
    TELEGRAM_BOT_TOKEN: str = os.getenv("TELEGRAM_BOT_TOKEN", "")
    
    # 外部 MCP / TrendRadar 等 HTTP 接入（可选）
    TRENDRADAR_MCP_HTTP_URL: str = os.getenv("TRENDRADAR_MCP_HTTP_URL", "")
    TRENDRADAR_MCP_API_KEY: str = os.getenv("TRENDRADAR_MCP_API_KEY", "")
    
    # Pydantic v2 配置
    model_config = SettingsConfigDict(
        extra='ignore',  # 忽略未定义的环境变量
        env_file='../../.env',  # 相对于当前文件的路径 (backend/app/core/ → 项目根目录)
        case_sensitive=True
    )

# 创建全局设置对象
settings = Settings() 