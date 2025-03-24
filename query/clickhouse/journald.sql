-- service_name
SELECT ResourceAttributes ['service.name'] AS service_name
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND (NOT empty(service_name))
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
  AND (
    '$host_name' = 'ALL'
    OR ResourceAttributes ['host.name'] = '$host_name'
  )
GROUP BY service_name;
-- log volume
SELECT toStartOfInterval(
    Timestamp,
    toIntervalMillisecond($__interval_ms * 6)
  ) as timestamp,
  countIf(
    SeverityNumber >= 21
    AND SeverityNumber <= 24
  ) as fatal,
  countIf(
    SeverityNumber >= 17
    AND SeverityNumber <= 20
  ) as error,
  countIf(
    SeverityNumber >= 13
    AND SeverityNumber <= 16
  ) as warn,
  countIf(
    SeverityNumber >= 9
    AND SeverityNumber <= 12
  ) as info,
  countIf(
    SeverityNumber >= 5
    AND SeverityNumber <= 8
  ) as debug,
  countIf(
    SeverityNumber >= 1
    AND SeverityNumber <= 4
  ) as trace,
  countIf(
    SeverityNumber = 0
    OR SeverityNumber >= 25
  ) as unknown
FROM default.otel_logs
WHERE (
    timestamp >= $__fromTime
    AND timestamp <= $__toTime
  )
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
  AND (
    '$host_name' = 'ALL'
    OR ResourceAttributes ['host.name'] = '$host_name'
  ) --- map key must exist
  AND mapContains(ResourceAttributes, 'service.name')
  AND (
    '$service_name' = 'ALL'
    OR ResourceAttributes ['service.name'] = '$service_name'
  )
  AND (Body LIKE '%$content%')
  AND (
    SeverityText IN (
      SELECT *
      FROM
      VALUES($level)
    )
  )
GROUP BY timestamp
ORDER BY timestamp DESC;
-- log details
SELECT Timestamp as "timestamp",
  Body as "body",
  SeverityText as "level",
  SeverityNumber as "level_number",
  mapConcat(LogAttributes, ResourceAttributes) as "labels",
  TraceId as "traceID"
FROM "default"."otel_logs"
WHERE (
    timestamp >= $__fromTime
    AND timestamp <= $__toTime
  )
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
  AND (
    '$host_name' = 'ALL'
    OR ResourceAttributes ['host.name'] = '$host_name'
  ) --- map key must exist
  AND mapContains(ResourceAttributes, 'service.name')
  AND (
    '$service_name' = 'ALL'
    OR ResourceAttributes ['service.name'] = '$service_name'
  )
  AND (body LIKE '%$content%')
  AND (
    SeverityText IN (
      SELECT *
      FROM
      VALUES($level)
    )
  )
ORDER BY timestamp DESC
LIMIT 500;
