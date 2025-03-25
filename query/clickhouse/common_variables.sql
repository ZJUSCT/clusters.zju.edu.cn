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
