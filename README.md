# ZJUSCT 可观测性系统

[可观测性 - ZJUSCT OpenDocs](https://zjusct.pages.zjusct.io/ops/opendocs/operation/observability/)

本仓库是 ZJUSCT 可观测性系统的配置文件。

## Todo

- [ ] Elastic Exporter
- [ ] InfluxDB Exporter
- [ ] Nginx Native Collector
- [ ] Grafana Provision DataSources
- [ ] Grafana Provision Dashboards
- [ ] Grafana Provision Alerts
- [ ] Wait for Prometheus 3.0, [native support for OpenTelemetry](https://prometheus.io/blog/2024/03/14/commitment-to-opentelemetry/) is coming.
- [ ] Wait for [journald - Consider parsing more known fields from logs · Issue #7298 · open-telemetry/opentelemetry-collector-contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/7298).

## 技术选型

We ❤️ Open Source

| 层次 | 组件 |
| --- | --- |
| 数据采集 | [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) |
| 数据存储 | [ClickHouse](https://github.com/ClickHouse/ClickHouse)、[Elasticsearch](https://github.com/elastic/elasticsearch)、[InfluxDB](https://github.com/influxdata/influxdb)、[Prometheus](https://github.com/prometheus/prometheus) |
| 数据分析、可视化和告警 | [Grafana](https://github.com/grafana/grafana) |

## 数据状态

为了方便运维管理，系统的状态应由仓库中的配置文件完全决定，Docker 是无状态的。需要持久化的数据使用 Docker Volume 存储在本地。

- 配置文件：能够使用 Git 管理的配置文件，通常是简单的文本，存储在本仓库中。依靠这些配置文件，我们只需要克隆仓库并 `docker compose up` 就能够快速部署整个系统，开箱即用。

    部分服务将配置保存到数据库中，比如 Grafana，它使用内置的 SQLite 3 存储配置、用户、仪表盘等数据。即使如此，它也提供了 [Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/) 功能，可以通过配置文件初始化各项配置。

- 数据库：服务的数据库需要持久化存储，Docker 官方建议使用 Volume 来存储数据库这类写入密集型的数据。

    > Use volumes for write-heavy workloads: Volumes provide the best and most predictable performance for write-heavy workloads. This is because they bypass the storage driver and do not incur any of the potential overheads introduced by thin provisioning and copy-on-write. Volumes have other benefits, such as allowing you to share data among containers and persisting even when no running container is using them.

    为了做到开箱即用，`compose.yml` 中的 Volume 均使用相对路径，Git 仓库保留 `database` 的空文件夹结构。

## 安全

区分四种访问范围：

| 区域 | 信任度 | 暴露的服务 |
| --- | --- | --- |
| Docker 内部、宿主机 | 受 Docker Engine 管理的通信，完全信任 | 所有 |
| 集群内部 | 安全状态良好，无需 TLS 加密 | 部分无认证和弱认证的服务，如 syslog、snmp |
| 校内网络 | 需要 TLS 加密，需要认证 | 仅 otel-collector 和 Grafana |
| 公网 | 阻断 | 无 |

认证 Token 托管在集群 VaultWarden 中。在 `compose.yml` 中设置为环境变量，通过 `get_credential.sh` 脚本生成 `.env` 文件，由 Docker Compose 读取。`.env` 文件不应当提交到 Git 仓库中。

## 细节

### OpenTelemetry

Collector 部署为 Agent + Gateway 模式。在这种模式下，为了方便配置，agent 尽可能只负责采集数据，更多的转换和处理逻辑交给 gateway。

```mermaid
flowchart TD
 subgraph s1["cloud.region"]
  n1(["agent"])
  subgraph s3["host.name"]
   n7(["agent"])
   
   n6["service.name"]
  end
  subgraph s2["host.name"]
   n5["service.name"]
   n4(["agent"])
   n2["service.name"]
  end
  
 end
 n3(["gateway"])
 n5 --> n4
 n2 --> n4
 n6 --> n7
 n7 --> n1
 n4 --> n1(["gateway"])
 n1(["gateway(cluster)"]) --- n3(["gateway(final)"])
```

不同层级的 Collector 需要附加不同的资源属性（Resource Attributes）。下面是基于

- Semantic Conventions 1.28.0
- OTel 1.38.0
- OTel Collector Contrib v0.111.0

在 ZJUSCT 可观测性系统中必须具备的资源属性及其来源：

- 节点 agent：
    - 服务名 `service.name`：
        - [`journaldreceiver`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/journaldreceiver) **使用 Operator 提取** `SYSLOG_IDENTIFIER` 字段。
        - [`filelogreceiver`](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/filelogreceiver/README.md) **使用 Operator 添加**。
    - 容器名 `container.name`：
        - [`dockerstatsreceiver`]() 自动添加。
        - [`]

        !!! warning ""

            修改 `daemon.json` 后，需要重建 docker 容器，日志选项才会生效。[linux - Docker daemon.json logging config not effective - Stack Overflow](https://stackoverflow.com/questions/46304780/docker-daemon-json-logging-config-not-effective)

    - 主机名 `host.name`：
        - `resourcedetector` 在流水线中添加
- 集群 gateway：
    - 集群名称 `cloud.region`：

除了上述资源属性和基本的 JSON 等格式解析，agent 尽可能不做任何配置。
