# Monitoring & Observability Stack

Complete monitoring and observability solution for the DevSecOps platform using Prometheus, Grafana, Fluent Bit, AlertManager, and CloudWatch integration.

## 📁 Directory Structure

```
06-monitoring/
├── README.md                           # This file
├── prometheus/                         # Prometheus monitoring
│   ├── deployment.yaml                # Prometheus deployment
│   ├── configmap.yaml                 # Prometheus configuration
│   ├── service.yaml                   # Prometheus service
│   ├── servicemonitor.yaml            # Service discovery
│   ├── recording-rules.yaml           # Recording rules for aggregations
│   └── rbac.yaml                      # RBAC for service discovery
├── grafana/                           # Grafana dashboards
│   ├── deployment.yaml                # Grafana deployment
│   ├── configmap.yaml                 # Grafana configuration
│   ├── service.yaml                   # Grafana service
│   ├── dashboards/                    # Dashboard definitions
│   │   ├── cluster-overview.json     # Kubernetes cluster metrics
│   │   ├── services-overview.json    # Microservices metrics
│   │   ├── api-performance.json      # API performance metrics
│   │   └── business-metrics.json     # Business KPIs
│   └── datasources.yaml              # Data source configurations
├── fluent-bit/                        # Log aggregation
│   ├── daemonset.yaml                # Fluent Bit DaemonSet
│   ├── configmap.yaml                # Fluent Bit configuration
│   ├── service.yaml                  # Fluent Bit service
│   ├── parsers.yaml                  # Log parsers
│   └── rbac.yaml                     # RBAC for log collection
├── alertmanager/                      # Alert management
│   ├── deployment.yaml               # AlertManager deployment
│   ├── configmap.yaml                # AlertManager configuration
│   ├── service.yaml                  # AlertManager service
│   ├── alert-rules.yaml              # Prometheus alert rules
│   └── templates/                    # Notification templates
│       ├── slack.tmpl                # Slack notification template
│       └── email.tmpl                # Email notification template
├── cloudwatch/                        # AWS CloudWatch
│   ├── dashboards/                   # CloudWatch dashboards
│   │   ├── eks-cluster.json         # EKS cluster dashboard
│   │   ├── rds-monitoring.json      # RDS monitoring
│   │   └── application-logs.json    # Application logs insights
│   ├── metric-filters.yaml           # Log metric filters
│   └── alarms.yaml                   # CloudWatch alarms
├── loki/                              # Loki log aggregation (optional)
│   ├── deployment.yaml               # Loki deployment
│   ├── configmap.yaml                # Loki configuration
│   └── service.yaml                  # Loki service
└── jaeger/                            # Distributed tracing (optional)
    ├── deployment.yaml               # Jaeger all-in-one
    ├── configmap.yaml                # Jaeger configuration
    └── service.yaml                  # Jaeger service
```

## 🎯 Monitoring Stack Overview

### Core Components

#### 1. **Prometheus** (Metrics Collection & Storage)
- **Purpose**: Time-series database for metrics collection
- **Features**:
  - Service discovery for automatic target detection
  - Recording rules for metric aggregation
  - Alert rule evaluation
  - PromQL for querying metrics
- **Retention**: 15 days (configurable)
- **Storage**: Persistent volume (50GB)
- **Scrape Interval**: 15 seconds

#### 2. **Grafana** (Visualization & Dashboards)
- **Purpose**: Metrics visualization and dashboarding
- **Features**:
  - Pre-configured dashboards for all services
  - Cluster overview dashboard
  - Business metrics dashboard
  - Alert integration with AlertManager
  - User authentication and RBAC
- **Datasources**: Prometheus, Loki (optional), CloudWatch
- **Default Credentials**: admin/admin (change on first login)

#### 3. **Fluent Bit** (Log Aggregation)
- **Purpose**: Lightweight log collector and forwarder
- **Features**:
  - DaemonSet on all nodes
  - Multi-line log parsing
  - JSON and structured logging support
  - Filtering and enrichment
  - Output to CloudWatch Logs
- **Log Retention**: 7 days in CloudWatch
- **Resource Limits**: 200Mi memory, 100m CPU

#### 4. **AlertManager** (Alert Routing & Notification)
- **Purpose**: Alert aggregation, deduplication, and routing
- **Features**:
  - Alert grouping and inhibition
  - Multiple notification channels (Slack, Email, PagerDuty)
  - Alert silencing and muting
  - Templated notifications
- **Alert Severity Levels**: critical, warning, info

#### 5. **CloudWatch** (AWS Native Monitoring)
- **Purpose**: AWS infrastructure and service monitoring
- **Features**:
  - EKS cluster metrics
  - RDS performance insights
  - Application logs with Log Insights
  - Custom metrics and alarms
  - SNS integration for notifications

## 📊 Metrics Collection

### Application Metrics

All microservices expose metrics on `/metrics` endpoint:

#### **User Service (Go)**
```
# HTTP Metrics
http_requests_total{method="GET",path="/api/v1/users",status="200"}
http_request_duration_seconds{method="GET",path="/api/v1/users",quantile="0.95"}
http_requests_in_flight{method="GET",path="/api/v1/users"}

# Business Metrics
user_registrations_total
user_logins_total
active_sessions_gauge

# Database Metrics
db_connections_active
db_query_duration_seconds
db_errors_total
```

#### **Auth Service (Node.js)**
```
# HTTP Metrics
http_request_duration_ms{method="POST",route="/api/v1/auth/login",status_code="200"}
http_requests_total{method="POST",route="/api/v1/auth/login"}

# Authentication Metrics
auth_login_attempts_total{status="success"}
auth_token_generation_total
auth_refresh_token_total
auth_failed_logins_total

# Rate Limiting
rate_limit_exceeded_total{endpoint="/api/v1/auth/login"}
```

#### **Notification Service (Python)**
```
# Notification Metrics
notifications_sent_total{channel="email",status="success"}
notifications_failed_total{channel="sms"}
notification_queue_length
notification_processing_duration_seconds

# Celery Metrics
celery_tasks_total{task="send_email",state="SUCCESS"}
celery_workers_active
celery_queue_length{queue="default"}
```

#### **Analytics Service (Java)**
```
# JVM Metrics
jvm_memory_used_bytes{area="heap"}
jvm_gc_pause_seconds_sum
jvm_threads_current

# Application Metrics
events_processed_total{event_type="page_view"}
events_failed_total
analytics_query_duration_seconds

# Cache Metrics
cache_hits_total{cache="redis"}
cache_misses_total{cache="redis"}
cache_evictions_total
```

#### **Frontend (React)**
```
# Custom metrics exposed via backend proxy
page_loads_total{page="/dashboard"}
api_calls_total{endpoint="/api/v1/users",status="200"}
user_interactions_total{action="button_click"}
```

### Infrastructure Metrics

#### **Kubernetes Cluster**
- Node CPU, Memory, Disk usage
- Pod CPU, Memory, Network I/O
- Container restarts
- PV/PVC usage
- Ingress request rate and latency

#### **AWS Services**
- EKS control plane metrics
- RDS CPU, connections, IOPS
- ElastiCache memory, CPU, evictions
- ALB request count, latency, errors

## 📈 Pre-configured Dashboards

### 1. **Cluster Overview Dashboard**
- **Panels**:
  - Cluster CPU/Memory utilization
  - Node status and count
  - Pod count by namespace
  - Container restart rate
  - Network I/O by namespace
  - Persistent volume usage
- **Time Range**: Last 6 hours (configurable)
- **Refresh**: 30 seconds

### 2. **Services Overview Dashboard**
- **Panels**:
  - Request rate (req/s) per service
  - P50, P95, P99 latency per service
  - Error rate (4xx, 5xx) per service
  - Active connections per service
  - Pod replicas per service
  - Health check status
- **Time Range**: Last 1 hour
- **Refresh**: 10 seconds

### 3. **API Performance Dashboard**
- **Panels**:
  - Request rate by endpoint
  - Response time heatmap
  - Error rate by status code
  - Top slowest endpoints
  - Request payload size distribution
  - Rate limiting violations
- **Time Range**: Last 30 minutes
- **Refresh**: 5 seconds

### 4. **Business Metrics Dashboard**
- **Panels**:
  - User registrations (daily, weekly, monthly)
  - Active users (DAU, MAU)
  - Authentication success rate
  - Notifications sent by channel
  - Events processed by type
  - Revenue/conversion metrics (if applicable)
- **Time Range**: Last 7 days
- **Refresh**: 1 minute

## 🚨 Alert Rules

### Critical Alerts (PagerDuty + Slack)

#### **High Error Rate**
```yaml
alert: HighErrorRate
expr: |
  rate(http_requests_total{status=~"5.."}[5m]) / 
  rate(http_requests_total[5m]) > 0.05
for: 5m
severity: critical
summary: High error rate detected (>5%)
```

#### **Service Down**
```yaml
alert: ServiceDown
expr: up{job=~".*-service"} == 0
for: 2m
severity: critical
summary: Service {{ $labels.job }} is down
```

#### **High Memory Usage**
```yaml
alert: HighMemoryUsage
expr: |
  container_memory_usage_bytes / 
  container_spec_memory_limit_bytes > 0.9
for: 5m
severity: critical
summary: Container memory usage >90%
```

#### **Pod Crash Looping**
```yaml
alert: PodCrashLooping
expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
for: 5m
severity: critical
summary: Pod {{ $labels.pod }} is crash looping
```

### Warning Alerts (Slack only)

#### **High Latency**
```yaml
alert: HighLatency
expr: |
  histogram_quantile(0.95, 
    rate(http_request_duration_seconds_bucket[5m])
  ) > 1.0
for: 10m
severity: warning
summary: P95 latency >1s for {{ $labels.service }}
```

#### **Database Connection Pool Exhaustion**
```yaml
alert: DatabaseConnectionPoolNearLimit
expr: |
  db_connections_active / 
  db_connections_max > 0.8
for: 5m
severity: warning
summary: Database connection pool >80% utilized
```

#### **Disk Space Low**
```yaml
alert: DiskSpaceLow
expr: |
  (node_filesystem_avail_bytes / 
   node_filesystem_size_bytes) < 0.2
for: 10m
severity: warning
summary: Disk space <20% on {{ $labels.instance }}
```

### Info Alerts (Slack only)

#### **High Request Rate**
```yaml
alert: HighRequestRate
expr: rate(http_requests_total[5m]) > 1000
for: 5m
severity: info
summary: High request rate (>1000 req/s)
```

## 📝 Log Aggregation

### Fluent Bit Configuration

#### **Input Plugins**
- **tail**: Collect logs from all containers
- **systemd**: Collect system logs from nodes

#### **Filter Plugins**
- **kubernetes**: Enrich logs with K8s metadata (namespace, pod, container)
- **parser**: Parse JSON logs from applications
- **modify**: Add custom fields (cluster, environment)
- **throttle**: Prevent log flooding

#### **Output Plugins**
- **cloudwatch**: Send logs to CloudWatch Logs
- **loki**: Send logs to Loki (optional)
- **elasticsearch**: Send logs to Elasticsearch (optional)

### Log Parsing Examples

#### **Go Service Logs (JSON)**
```json
{
  "timestamp": "2025-10-05T10:30:45Z",
  "level": "info",
  "service": "user-service",
  "message": "User created successfully",
  "user_id": "12345",
  "duration_ms": 45
}
```

#### **Node.js Service Logs (JSON)**
```json
{
  "timestamp": "2025-10-05T10:30:45.123Z",
  "level": "info",
  "service": "auth-service",
  "message": "Login successful",
  "user_id": "12345",
  "ip": "192.168.1.100"
}
```

#### **Python Service Logs (Text)**
```
2025-10-05 10:30:45,123 INFO [notification-service] Notification sent successfully type=email recipient=user@example.com
```

## 🔧 Setup Instructions

### 1. Install Prometheus Stack

```bash
# Apply Prometheus RBAC
kubectl apply -f 06-monitoring/prometheus/rbac.yaml

# Apply Prometheus ConfigMap
kubectl apply -f 06-monitoring/prometheus/configmap.yaml

# Deploy Prometheus
kubectl apply -f 06-monitoring/prometheus/deployment.yaml
kubectl apply -f 06-monitoring/prometheus/service.yaml

# Verify Prometheus
kubectl get pods -n monitoring -l app=prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Access: http://localhost:9090
```

### 2. Install Grafana

```bash
# Apply Grafana ConfigMap and Datasources
kubectl apply -f 06-monitoring/grafana/configmap.yaml
kubectl apply -f 06-monitoring/grafana/datasources.yaml

# Deploy Grafana
kubectl apply -f 06-monitoring/grafana/deployment.yaml
kubectl apply -f 06-monitoring/grafana/service.yaml

# Get Grafana password
kubectl get secret -n monitoring grafana-admin -o jsonpath='{.data.password}' | base64 -d

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Access: http://localhost:3000
# Login: admin / <password>
```

### 3. Install Fluent Bit

```bash
# Apply Fluent Bit RBAC
kubectl apply -f 06-monitoring/fluent-bit/rbac.yaml

# Apply Fluent Bit ConfigMap
kubectl apply -f 06-monitoring/fluent-bit/configmap.yaml
kubectl apply -f 06-monitoring/fluent-bit/parsers.yaml

# Deploy Fluent Bit DaemonSet
kubectl apply -f 06-monitoring/fluent-bit/daemonset.yaml

# Verify Fluent Bit
kubectl get pods -n monitoring -l app=fluent-bit
kubectl logs -n monitoring -l app=fluent-bit --tail=50
```

### 4. Install AlertManager

```bash
# Apply AlertManager ConfigMap
kubectl apply -f 06-monitoring/alertmanager/configmap.yaml

# Deploy AlertManager
kubectl apply -f 06-monitoring/alertmanager/deployment.yaml
kubectl apply -f 06-monitoring/alertmanager/service.yaml

# Apply Alert Rules
kubectl apply -f 06-monitoring/alertmanager/alert-rules.yaml

# Access AlertManager
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
# Access: http://localhost:9093
```

### 5. Configure CloudWatch (Optional)

```bash
# Create CloudWatch log groups
aws logs create-log-group --log-group-name /aws/eks/devsecops/cluster
aws logs create-log-group --log-group-name /aws/eks/devsecops/application

# Create CloudWatch dashboards
aws cloudwatch put-dashboard --dashboard-name devsecops-eks \
  --dashboard-body file://06-monitoring/cloudwatch/dashboards/eks-cluster.json

# Create CloudWatch alarms
kubectl apply -f 06-monitoring/cloudwatch/alarms.yaml
```

## 🔔 Notification Configuration

### Slack Integration

1. **Create Slack App**: https://api.slack.com/apps
2. **Add Incoming Webhook**: Copy webhook URL
3. **Update AlertManager ConfigMap**:

```yaml
receivers:
  - name: 'slack-critical'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts-critical'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

### Email Integration

Update AlertManager ConfigMap with SMTP settings:

```yaml
receivers:
  - name: 'email-alerts'
    email_configs:
      - to: 'ops-team@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'alertmanager@example.com'
        auth_password: '<app-password>'
        headers:
          Subject: '[{{ .Status }}] {{ .GroupLabels.alertname }}'
```

### PagerDuty Integration

```yaml
receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: '<your-pagerduty-service-key>'
        severity: 'critical'
```

## 📊 Querying Metrics

### Useful PromQL Queries

#### **Request Rate**
```promql
sum(rate(http_requests_total[5m])) by (service)
```

#### **P95 Latency**
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))
```

#### **Error Rate**
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)
```

#### **Pod Memory Usage**
```promql
sum(container_memory_usage_bytes{namespace="devsecops"}) by (pod)
```

#### **Active Users**
```promql
active_sessions_gauge{service="user-service"}
```

## 🔍 Log Queries

### CloudWatch Insights Queries

#### **Error Logs Last Hour**
```
fields @timestamp, service, level, message
| filter level = "error"
| sort @timestamp desc
| limit 100
```

#### **Slow API Requests**
```
fields @timestamp, service, path, duration_ms
| filter duration_ms > 1000
| sort duration_ms desc
| limit 50
```

#### **Authentication Failures**
```
fields @timestamp, service, message, user_id, ip
| filter service = "auth-service" and message like /failed/
| stats count() by ip
| sort count desc
```

## 🎯 Best Practices

1. **Metric Naming**: Use consistent naming conventions (service_subsystem_metric_unit)
2. **Label Cardinality**: Keep label cardinality low to prevent metric explosion
3. **Recording Rules**: Pre-aggregate expensive queries
4. **Alert Fatigue**: Set appropriate thresholds to avoid false positives
5. **Dashboard Organization**: Group related metrics logically
6. **Log Sampling**: Sample high-volume logs to control costs
7. **Retention Policies**: Balance storage costs vs. data retention needs
8. **Resource Limits**: Set appropriate limits for monitoring components
9. **High Availability**: Run multiple replicas of critical components
10. **Regular Review**: Periodically review and update alerts and dashboards

## 🔧 Troubleshooting

### Prometheus Not Scraping Targets

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n monitoring

# Check Prometheus logs
kubectl logs -n monitoring -l app=prometheus

# Verify service endpoints
kubectl get endpoints -n devsecops

# Check RBAC permissions
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:prometheus
```

### Grafana Dashboards Not Loading

```bash
# Check Grafana logs
kubectl logs -n monitoring -l app=grafana

# Verify datasource
kubectl exec -n monitoring -it <grafana-pod> -- \
  curl http://localhost:3000/api/datasources

# Check Prometheus connectivity
kubectl exec -n monitoring -it <grafana-pod> -- \
  curl http://prometheus:9090/-/healthy
```

### Fluent Bit Not Forwarding Logs

```bash
# Check Fluent Bit logs
kubectl logs -n monitoring -l app=fluent-bit --tail=100

# Verify CloudWatch log groups
aws logs describe-log-groups --log-group-name-prefix /aws/eks/devsecops

# Check IAM permissions
kubectl describe sa -n monitoring fluent-bit
```

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)

## ✅ Task 9 Deliverables

- [x] Prometheus deployment with service discovery
- [x] Grafana dashboards for all services
- [x] Fluent Bit log aggregation
- [x] AlertManager with notification routing
- [x] CloudWatch integration
- [x] Alert rules for critical scenarios
- [x] Recording rules for optimization
- [x] Complete documentation

**Status**: Monitoring stack ready for deployment! 📊
