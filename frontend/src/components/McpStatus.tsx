'use client';

import React, { useState } from 'react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { ScrollArea } from './ui/scroll-area';
import { Badge } from './ui/badge';
import { Puzzle, ChevronDown, ChevronUp, Server, Wrench, CheckCircle2, XCircle } from 'lucide-react';

interface McpTool {
  name: string;
  llm_name: string;
  description: string;
  full_name: string;
}

interface McpServer {
  id: string;
  base_url: string;
  connected: boolean;
  tool_count: number;
  tools: McpTool[];
}

interface McpStatusProps {
  servers: McpServer[];
  enabled: boolean;
}

export function McpStatus({ servers, enabled }: McpStatusProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [expandedServers, setExpandedServers] = useState<Set<string>>(new Set());

  const toggleServer = (serverId: string) => {
    setExpandedServers(prev => {
      const newSet = new Set(prev);
      if (newSet.has(serverId)) {
        newSet.delete(serverId);
      } else {
        newSet.add(serverId);
      }
      return newSet;
    });
  };

  // 计算总工具数
  const totalTools = servers.reduce((sum, s) => sum + s.tool_count, 0);
  const connectedCount = servers.filter(s => s.connected).length;

  if (!enabled || servers.length === 0) {
    return (
      <Button
        variant="outline"
        size="sm"
        className="gap-1 opacity-50 cursor-not-allowed"
        disabled
        title="未配置 MCP 服务器"
      >
        <Puzzle className="h-4 w-4" />
        <span className="text-xs hidden md:inline">MCP</span>
        <span className="ml-1 h-2 w-2 rounded-full bg-gray-300"></span>
      </Button>
    );
  }

  return (
    <div className="relative">
      <Button
        variant="outline"
        size="sm"
        className="gap-1"
        onClick={() => setIsOpen(!isOpen)}
        title={`${connectedCount} 个 MCP 服务器，共 ${totalTools} 个工具`}
      >
        <Puzzle className="h-4 w-4" />
        <span className="text-xs hidden md:inline">MCP</span>
        <Badge variant="secondary" className="ml-1 text-xs px-1.5 py-0 h-4 min-w-[1.25rem] flex items-center justify-center">
          {totalTools}
        </Badge>
        <span className={`ml-1 h-2 w-2 rounded-full ${connectedCount > 0 ? 'bg-green-500' : 'bg-gray-300'}`}></span>
        {isOpen ? <ChevronUp className="h-3 w-3 ml-1" /> : <ChevronDown className="h-3 w-3 ml-1" />}
      </Button>

      {isOpen && (
        <Card className="absolute right-0 top-full mt-2 w-80 md:w-96 z-50 shadow-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900">
          <div className="p-3 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Puzzle className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                <span className="font-medium text-sm">MCP 服务器状态</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <span>{connectedCount}/{servers.length} 在线</span>
                <span className="text-gray-300">|</span>
                <span>{totalTools} 工具</span>
              </div>
            </div>
          </div>

          <ScrollArea className="h-80">
            <div className="p-2">
              {servers.length === 0 ? (
                <div className="text-center py-4 text-sm text-gray-500">
                  未配置 MCP 服务器
                </div>
              ) : (
                <div className="space-y-2">
                  {servers.map((server) => (
                    <div
                      key={server.id}
                      className="border border-gray-200 dark:border-gray-700 rounded-md overflow-hidden"
                    >
                      <button
                        className="w-full px-3 py-2 flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors text-left"
                        onClick={() => toggleServer(server.id)}
                      >
                        <div className="flex items-center gap-2 min-w-0">
                          <Server className="h-4 w-4 text-gray-400 flex-shrink-0" />
                          <span className="text-sm font-medium truncate">{server.id}</span>
                          {server.connected ? (
                            <CheckCircle2 className="h-3.5 w-3.5 text-green-500 flex-shrink-0" />
                          ) : (
                            <XCircle className="h-3.5 w-3.5 text-red-500 flex-shrink-0" />
                          )}
                        </div>
                        <div className="flex items-center gap-2 flex-shrink-0">
                          <Badge variant="secondary" className="text-xs px-1.5 py-0 h-5">
                            {server.tool_count}
                          </Badge>
                          {expandedServers.has(server.id) ? (
                            <ChevronUp className="h-3.5 w-3.5 text-gray-400" />
                          ) : (
                            <ChevronDown className="h-3.5 w-3.5 text-gray-400" />
                          )}
                        </div>
                      </button>

                      {expandedServers.has(server.id) && (
                        <div className="border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                          <div className="px-3 py-2">
                            <div className="text-xs text-gray-500 mb-2 break-all">
                              {server.base_url}
                            </div>
                            {server.tools.length > 0 ? (
                              <ScrollArea className="h-48">
                                <div className="space-y-1 pr-1">
                                {server.tools.map((tool) => (
                                  <div
                                    key={tool.full_name}
                                    className="flex items-start gap-2 p-1.5 rounded bg-white dark:bg-gray-700 text-xs"
                                  >
                                    <Wrench className="h-3 w-3 text-gray-400 mt-0.5 flex-shrink-0" />
                                    <div className="min-w-0">
                                      <div className="font-medium text-gray-700 dark:text-gray-200 truncate">
                                        {tool.name}
                                      </div>
                                      {tool.description && (
                                        <div className="text-gray-500 dark:text-gray-400 line-clamp-2 mt-0.5">
                                          {tool.description}
                                        </div>
                                      )}
                                    </div>
                                  </div>
                                ))}
                                </div>
                              </ScrollArea>
                            ) : (
                              <div className="text-xs text-gray-400 italic">
                                未发现可用工具
                              </div>
                            )}
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </ScrollArea>

          <div className="p-2 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
            <div className="text-xs text-gray-500 text-center">
              智能助手可使用上述工具扩展能力
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}

export default McpStatus;
