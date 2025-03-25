-- Example Log:
-- Timestamp:          2025-03-25 04:25:44.920000000
-- TimestampTime:      2025-03-25 04:25:44
-- TraceId:
-- SpanId:
-- TraceFlags:         0
-- SeverityText:
-- SeverityNumber:     0
-- ServiceName:
-- Body:
-- ResourceSchemaUrl:
-- ResourceAttributes: {'cloud.region':'zjusct-cluster'}
-- ScopeSchemaUrl:
-- ScopeName:          otelcol/netflowreceiver
-- ScopeVersion:
-- ScopeAttributes:    {'receiver':'netflow'}
-- LogAttributes:      {'destination.address':'10.78.18.247','destination.port':'11349','flow.end':'1742876744920000000','flow.io.bytes':'377','flow.io.packets':'1','flow.sampler_address':'172.25.3.254','flow.sampling_rate':'0','flow.sequence_num':'1','flow.start':'1742876744920000000','flow.time_received':'1742876776236499353','flow.type':'netflow_v9','network.transport':'udp','network.type':'ipv4','source.address':'210.32.148.87','source.port':'29915'}
-- VARIABLES
-- flow_sampler_address
SELECT LogAttributes ['flow.sampler_address'] AS flow_sampler_address
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND ScopeName = 'otelcol/netflowreceiver'
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
GROUP BY flow_sampler_address;
-- flow_type
SELECT LogAttributes ['flow.type'] AS flow_type
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND ScopeName = 'otelcol/netflowreceiver'
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
GROUP BY flow_type;
-- transport_type
SELECT LogAttributes ['network.transport'] AS transport_type
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND ScopeName = 'otelcol/netflowreceiver'
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
GROUP BY transport_type;
-- PANELS
-- network transport type volume
SELECT toStartOfInterval(
    Timestamp,
    toIntervalMillisecond($__interval_ms * 6)
  ) AS timestamp,
  sumIf(
    toUInt64(LogAttributes ['flow.io.bytes']),
    LogAttributes ['network.transport'] = 'icmp'
  ) AS icmp,
  sumIf(
    toUInt64(LogAttributes ['flow.io.bytes']),
    LogAttributes ['network.transport'] = 'udp'
  ) AS udp,
  sumIf(
    toUInt64(LogAttributes ['flow.io.bytes']),
    LogAttributes ['network.transport'] = 'tcp'
  ) AS tcp
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND ScopeName = 'otelcol/netflowreceiver'
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
GROUP BY timestamp
ORDER BY timestamp DESC;
-- top 5 destination(ip and port) with speed
SELECT concat(
    LogAttributes ['destination.address'],
    ':',
    LogAttributes ['destination.port']
  ) AS destination,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) AS total_bytes,
  sum(toUInt64(LogAttributes ['flow.io.packets'])) AS total_packets,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) / (($__toTime - $__fromTime) / 1000) AS bytes_per_second
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND ScopeName = 'otelcol/netflowreceiver'
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
  AND (
    '$transport_type' = 'ALL'
    OR LogAttributes ['network.transport'] = '$transport_type'
  )
GROUP BY destination
ORDER BY bytes_per_second DESC
LIMIT 5;
-- top 5 source(ip and port) with speed
SELECT concat(
    LogAttributes ['source.address'],
    ':',
    LogAttributes ['source.port']
  ) AS source,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) AS total_bytes,
  sum(toUInt64(LogAttributes ['flow.io.packets'])) AS total_packets,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) / (($__toTime - $__fromTime) / 1000) AS bytes_per_second
FROM otel_logs
WHERE (
    Timestamp >= $__fromTime
    AND Timestamp <= $__toTime
  )
  AND ScopeName = 'otelcol/netflowreceiver'
  AND (
    '$cloud_region' = 'ALL'
    OR ResourceAttributes ['cloud.region'] = '$cloud_region'
  )
  AND (
    '$transport_type' = 'ALL'
    OR LogAttributes ['network.transport'] = '$transport_type'
  )
GROUP BY source
ORDER BY bytes_per_second DESC
LIMIT 5;
