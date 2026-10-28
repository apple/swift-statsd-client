# Deprecation Notice:

swift-statsd-client has not seen active development for a long time, and will be deprecated and will no longer be maintained. The package will receive critical bug and security fixes for 6-months and then archived. Please migrate to swift-metrics with an appropriate backend such as swift-otel, opentelemetry-swift or swift-prometheus as the replacement.

# Reason:

Since this package was introduced we have observed a shift in the ecosystem towards Prometheus and OpenTelemetry based solutions. Adoption and engagement around the swift-statsd-client package has remained relatively low. With all of this in mind, we’ve decided to focus our efforts on maintaining these other heavily used metrics backend.

# Migration Guide:

Visit the swift-metrics repository for documentation and setup instructions.

Thank you to all of the contributors of swift-statsd-client.

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

### Run CI checks locally

You can run the GitHub Actions workflows locally using [act](https://github.com/nektos/act). For detailed steps on how to do this please see [https://github.com/swiftlang/github-workflows?tab=readme-ov-file#running-workflows-locally](https://github.com/swiftlang/github-workflows?tab=readme-ov-file#running-workflows-locally).
