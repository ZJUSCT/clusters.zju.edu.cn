-- geoipv4
create table geoip_url(
  ip_range_start IPv4,
  ip_range_end IPv4,
  country_code Nullable(String),
  state1 Nullable(String),
  state2 Nullable(String),
  city Nullable(String),
  postcode Nullable(String),
  latitude Float64,
  longitude Float64,
  timezone Nullable(String)
) engine = URL(
  'https://raw.githubusercontent.com/sapics/ip-location-db/master/dbip-city/dbip-city-ipv4.csv.gz',
  'CSV'
);
create table geoip (
  cidr String,
  latitude Float64,
  longitude Float64,
  country_code String
) engine = MergeTree()
order by cidr;
insert into geoip with bitXor(ip_range_start, ip_range_end) as
  xor,
  if(
    xor != 0,
    ceil(
      log2(
        xor
      )
    ),
    0
  ) as unmatched,
  32 - unmatched as cidr_suffix,
  toIPv4(
    bitAnd(bitNot(pow(2, unmatched) - 1), ip_range_start)::UInt64
  ) as cidr_address
select concat(
    toString(cidr_address),
    '/',
    toString(cidr_suffix)
  ) as cidr,
  latitude,
  longitude,
  country_code
from geoip_url;
create dictionary ip_trie (
  cidr String,
  latitude Float64,
  longitude Float64,
  country_code String
) primary key cidr source(clickhouse(table 'geoip')) layout(ip_trie) lifetime(3600);
-- geoipv6
create table geoipv6_url(
  ip_range_start IPv6,
  ip_range_end IPv6,
  country_code Nullable(String),
  state1 Nullable(String),
  state2 Nullable(String),
  city Nullable(String),
  postcode Nullable(String),
  latitude Float64,
  longitude Float64,
  timezone Nullable(String)
) engine = URL(
  'https://raw.githubusercontent.com/sapics/ip-location-db/master/dbip-city/dbip-city-ipv6.csv.gz',
  'CSV'
);
create table geoipv6 (
  cidr String,
  latitude Float64,
  longitude Float64,
  country_code String
) engine = MergeTree()
order by cidr;
insert into geoipv6 with bitXor(ip_range_start, ip_range_end) as
  xor,
  if(
    xor != 0,
    ceil(
      log2(
        xor
      )
    ),
    0
  ) as unmatched,
  128 - unmatched as cidr_suffix,
  toIPv6(
    bitAnd(bitNot(pow(2, unmatched) - 1), ip_range_start)::UInt128
  ) as cidr_address
select concat(
    toString(cidr_address),
    '/',
    toString(cidr_suffix)
  ) as cidr,
  latitude,
  longitude,
  country_code
from geoipv6_url;
create dictionary ip_trie (
  cidr String,
  latitude Float64,
  longitude Float64,
  country_code String
) primary key cidr source(clickhouse(table 'geoip')) layout(ip_trie) lifetime(3600);
-- ipv4 materialized view
CREATE TABLE zjumirror_nginx_request_ipv4 (
  timestamp DateTime,
  ip IPv4,
  request_count UInt32,
  request_size UInt64 -- 名字取错了，这其实是 response size
) ENGINE = SummingMergeTree() -- SummingMergeTree 会按照 ORDER BY 的字段进行合并
ORDER BY (timestamp, ip);
CREATE MATERIALIZED VIEW zjumirror_nginx_request_ipv4_mv TO zjumirror_nginx_request_ipv4 AS
SELECT toStartOfMinute(Timestamp) as timestamp,
  toIPv4(LogAttributes ['client.address']) as ip,
  COUNT(*) as request_count,
  sum(
    toUInt64(LogAttributes ['http.response.body.size'])
  ) as request_size
FROM otel_logs
WHERE ResourceAttributes ['cloud.region'] = 'zjusct-falcon'
  AND ResourceAttributes ['host.name'] = 'zjumirror' -- 过滤 IPv4 地址
  AND isIPv4String(LogAttributes ['client.address'])
  AND LogAttributes ['log.file.name'] = 'otel.log'
GROUP BY timestamp,
  ip;
-- request count by ip
select timestamp,
  ip,
  request_count
from zjumirror_nginx_request_ipv4
where timestamp >= $__fromTime
  AND timestamp <= $__toTime
order by request_count desc -- 按请求数降序排列，然后对每个时间段取前 10 个
LIMIT 10 BY timestamp;
-- bandwidth sum by ip
select timestamp,
  ip,
  request_size / 60 -- 时间戳精度为分钟，Grafana 只有 byte/s 的单位
from zjumirror_nginx_request_ipv4
where timestamp >= $__fromTime
  AND timestamp <= $__toTime
order by request_size desc -- 按带宽降序排列，然后对每个时间段取前 10 个
LIMIT 10 BY timestamp;
-- request count by geohash
with coords as (
  with ip as (
    select ip,
      sum(request_count) as request_count
    from zjumirror_nginx_request_ipv4
    where (
        timestamp >= $__fromTime
        AND timestamp <= $__toTime
      )
    group by ip
  )
  select dictGet(
      'ip_trie',
      ('latitude', 'longitude'),
      tuple(ip)
    ) as coords,
    coords.1 as latitude,
    coords.2 as longitude,
    geohashEncode(longitude, latitude, 4) as geohash,
    request_count
  from ip
  where longitude != 0
    and latitude != 0
)
select geohash,
  sum(request_count) / date_diff('second', $__fromTime, $__toTime) as rps
from coords
group by geohash;
-- bandwidth sum by geohash
with coords as (
  with ip as (
    select ip,
      sum(request_size) as request_size
    from zjumirror_nginx_request_ipv4
    where (
        timestamp >= $__fromTime
        AND timestamp <= $__toTime
      )
    group by ip
  )
  select dictGet(
      'ip_trie',
      ('latitude', 'longitude'),
      tuple(ip)
    ) as coords,
    coords.1 as latitude,
    coords.2 as longitude,
    geohashEncode(longitude, latitude, 4) as geohash,
    request_size
  from ip
  where longitude != 0
    and latitude != 0
)
select geohash,
  sum(request_size) / date_diff('second', $__fromTime, $__toTime) as bandwidth
from coords
group by geohash;
