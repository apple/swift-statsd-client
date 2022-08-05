# SwiftStatsDClient

a metrics backend for [swift-metrics](https://github.com/apple/swift-metrics) that uses the [statsd](https://github.com/b/statsd_spec) protocol, and can be used to integrate applications with observability solutions that support `statsd` including:
* [AWS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-statsd.html)
* [Azure](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-platform)
* [Google Cloud](https://cloud.google.com/monitoring/agent/plugins/statsd)
* [IBM Cloud](https://cloud.ibm.com/catalog/services/ibm-cloud-monitoring-with-sysdig)
* [Grafana](https://grafana.com)
* [Graphite](https://graphiteapp.org)
* Many others

## Getting started

Create an instance of the `StatsdClient` and boostrap the `MetricsSystem` in your application's `main`:

```swift
let statsdClient = try StatsdClient(host: host, port: port)
MetricsSystem.bootstrap(statsdClient)
```

See [selecting a metrics backend implementation](https://github.com/apple/swift-metrics#selecting-a-metrics-backend-implementation-applications-only) for more information.

Remember to also shutdown the client before you application terminates:

```swift
statsdClient.shutdown()
```

## Architecture

`StatsdClient` uses [SwiftNIO](https://github.com/apple/swift-nio) to establish a UDP connection to the `statsd` server.

Metrics types are mapped as following:
* Counter -> Counter
* Gauge -> Gauge
* Recorder -> Histogram
* Timer -> Timer

## Security

Please see [SECURITY.md](SECURITY.md) for details on the security process.

## Getting involved

Do not hesitate to get in touch as well, over on https://forums.swift.org/c/server
