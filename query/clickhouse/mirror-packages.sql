SELECT toStartOfInterval(
    Timestamp,
    -- 根据 grafana 的查询时间范围调整聚合粒度
    toIntervalMillisecond($__interval_ms * 30)
  ) as timestamp,
  replaceRegexpOne(
    -- 从 URL 中提取仓库名
    LogAttributes ['url.path'],
    '^/([^/]+)/.*',
    '\\1'
  ) AS repo,
  COUNT(*)
FROM default.otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND (
    ResourceAttributes ['cloud.region'] = 'zjusct-falcon'
  )
  AND (ResourceAttributes ['host.name'] = 'zjumirror')
  AND (LogAttributes ['log.file.name'] = 'otel.log')
  AND (
    -- extracts the first segment of a URL path after the initial slash
    match(LogAttributes ['url.path'], '^/([^/]+)/.*')
  )
GROUP BY ALL -- 按请求次数降序排列，然后对每个时间段取前 5 个
ORDER BY COUNT(*) DESC
LIMIT 5 BY timestamp;
