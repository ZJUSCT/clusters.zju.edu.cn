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
SELECT sumIf(
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
  AND (
    '$flow_sampler_address' = 'ALL'
    OR LogAttributes ['flow.sampler_address'] = '$flow_sampler_address'
  )
  AND (
    '$flow_type' = 'ALL'
    OR LogAttributes ['flow.type'] = '$flow_type'
  );
-- top 5 destination(ip and port) with speed
SELECT concat(
    LogAttributes ['destination.address'],
    ':',
    LogAttributes ['destination.port']
  ) AS destination,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) AS total_bytes,
  sum(toUInt64(LogAttributes ['flow.io.packets'])) AS total_packets,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) / (($__toTime - $__fromTime)) AS bytes_per_second
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
    '$flow_sampler_address' = 'ALL'
    OR LogAttributes ['flow.sampler_address'] = '$flow_sampler_address'
  )
  AND (
    '$flow_type' = 'ALL'
    OR LogAttributes ['flow.type'] = '$flow_type'
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
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) / (($__toTime - $__fromTime)) AS bytes_per_second
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
    '$flow_sampler_address' = 'ALL'
    OR LogAttributes ['flow.sampler_address'] = '$flow_sampler_address'
  )
  AND (
    '$flow_type' = 'ALL'
    OR LogAttributes ['flow.type'] = '$flow_type'
  )
  AND (
    '$transport_type' = 'ALL'
    OR LogAttributes ['network.transport'] = '$transport_type'
  )
GROUP BY source
ORDER BY bytes_per_second DESC
LIMIT 5;
-- top 5 dst and src with speed
SELECT concat(
    LogAttributes ['source.address'],
    ':',
    LogAttributes ['source.port'],
    ' -> ',
    LogAttributes ['destination.address'],
    ':',
    LogAttributes ['destination.port']
  ) AS flow,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) AS total_bytes,
  sum(toUInt64(LogAttributes ['flow.io.packets'])) AS total_packets,
  sum(toUInt64(LogAttributes ['flow.io.bytes'])) / (($__toTime - $__fromTime)) AS bytes_per_second
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
    '$flow_sampler_address' = 'ALL'
    OR LogAttributes ['flow.sampler_address'] = '$flow_sampler_address'
  )
  AND (
    '$flow_type' = 'ALL'
    OR LogAttributes ['flow.type'] = '$flow_type'
  )
  AND (
    '$transport_type' = 'ALL'
    OR LogAttributes ['network.transport'] = '$transport_type'
  )
GROUP BY flow
ORDER BY bytes_per_second DESC
LIMIT 5;
-- top 5 flow with speed
SELECT concat(
    LogAttributes ['source.address'],
    ':',
    LogAttributes ['source.port'],
    ' -> ',
    LogAttributes ['destination.address'],
    ':',
    LogAttributes ['destination.port']
  ) AS flow,
  LogAttributes ['flow.io.bytes'] AS total_bytes,
  LogAttributes ['flow.io.packets'] AS total_packets,
  fromUnixTimestamp(
    intDiv(
      toUInt64(LogAttributes ['flow.start']),
      1000000000
    )
  ) AS start_time,
  fromUnixTimestamp(
    intDiv(toUInt64(LogAttributes ['flow.end']), 1000000000)
  ) AS end_time,
  intDiv(
    (
      toUInt64(LogAttributes ['flow.end']) - toUInt64(LogAttributes ['flow.start'])
    ),
    1000000000
  ) AS duration,
  if(
    duration = 0,
    0,
    toUInt64(LogAttributes ['flow.io.bytes']) / duration
  ) AS average_speed
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
    '$flow_sampler_address' = 'ALL'
    OR LogAttributes ['flow.sampler_address'] = '$flow_sampler_address'
  )
  AND (
    '$flow_type' = 'ALL'
    OR LogAttributes ['flow.type'] = '$flow_type'
  )
  AND (
    '$transport_type' = 'ALL'
    OR LogAttributes ['network.transport'] = '$transport_type'
  )
ORDER BY average_speed DESC
LIMIT 500;