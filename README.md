# swift-statsd-client

a metrics backend for [swift-metrics](https://github.com/apple/swift-metrics) that uses the [statsd](https://github.com/b/statsd_spec) protocol, and can be used to integrate applications with observability solutions that support `statsd` including:
* [aws](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-statsd.html)
* [azure](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-platform)
* [google cloud](https://cloud.google.com/monitoring/agent/plugins/statsd)
* [ibm cloud](https://cloud.ibm.com/catalog/services/ibm-cloud-monitoring-with-sysdig)
* [grafana](https://grafana.com)
* [graphite](https://graphiteapp.org)
* many others

## getting started

create an instance of the `StatsdClient` and boostrap the `MertricsSystem`  in your application's main:

```swift
let statsdClient = try StatsdClient(host: host, port: port)
MetricsSystem.bootstrap(statsdClient)
```

see https://github.com/apple/swift-metrics#selecting-a-metrics-backend-implementation-applications-only

remeber to also shutdown the client before you application terminates:

```swift
statsdClient.shutdown()
```


## architecture

the statsd client uses [swift-nio](https://github.com/apple/swift-nio) to establish a UDP connection to the statsd server

metrics types are mapped as follwoing:
* Counter -> Counter
* Gauge -> Gauge
* Recorder -> Histogram
* Timer -> Timer
