-- variables
-- cloud_region
SELECT ResourceAttributes ['cloud.region'] AS cloud_region
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND (NOT empty(cloud_region))
GROUP BY cloud_region;
-- host_name
SELECT ResourceAttributes ['host.name'] AS host_name
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND (NOT empty(host_name))
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
GROUP BY host_name;

-- container_name
SELECT ResourceAttributes ['container.name'] AS container_name
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND (NOT empty(container_name))
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
  AND (
    '$host_name' = 'ALL'
    OR ResourceAttributes ['host.name'] = '$host_name'
  )
GROUP BY container_name;

-- level
SELECT SeverityText as level
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
  AND (
    '$host_name' = 'ALL'
    OR ResourceAttributes ['host.name'] = '$host_name'
  )
  AND (
    '$service_name' = 'ALL'
    OR ResourceAttributes ['service.name'] = '$service_name'
  )
  AND (
    '$container_name' = 'ALL'
    OR ResourceAttributes ['container.name'] = '$container_name'
  )
GROUP BY level;
