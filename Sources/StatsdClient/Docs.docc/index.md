# ``StatsdClient``

A metrics backend implementation using the StatsD protocol.

## Overview

StatsdClient is a metrics backend for [SwiftMetrics](https://github.com/apple/swift-metrics) that uses the [StatsD](https://github.com/b/statsd_spec) protocol, and can be used to integrate applications with observability solutions that support StatsD including:
* [AWS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-statsd.html)
* [Azure](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-platform)
* [Google Cloud](https://cloud.google.com/monitoring/agent/plugins/statsd)
* [IBM Cloud](https://cloud.ibm.com/catalog/services/ibm-cloud-monitoring-with-sysdig)
* [Grafana](https://grafana.com)
* [Graphite](https://graphiteapp.org)
* Many others

## Getting started

Create an instance of the ``StatsdClient/StatsdClient`` and boostrap the `MetricsSystem` in your application's `main`:

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

``StatsdClient/StatsdClient`` uses [SwiftNIO](https://github.com/apple/swift-nio) to establish a UDP connection to the `statsd` server.

Metrics types are mapped as following:
* Counter -> Counter
* Gauge -> Gauge
* Recorder -> Histogram
* Timer -> Timer
                                              
## Topics

### Client API

- ``StatsdClient/init(eventLoopGroupProvider:host:port:metricNameSanitizer:)``
- ``StatsdClient/shutdown(_:)``
                                              
### Metrics API

- ``StatsdClient/makeCounter(label:dimensions:)``
- ``StatsdClient/makeRecorder(label:dimensions:aggregate:)``
- ``StatsdClient/makeTimer(label:dimensions:)``
