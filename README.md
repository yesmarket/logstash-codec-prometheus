# Overview

This codec translates prometheus data into json.

**Q**: Since Prometheus is pull based; why do we even need Logstash involved?</br>
**A**: An approach to monitoring that reduces the chance of being tied to a specific monitoring solution might be preferable for some. The prometheus metrics format for exposing metrics can be thought of independently to the underlying Prometheus monitoring solution - it's really a display format. Prometheus metrics should be able to get consumed by any monitoring solution. If we want a monitoring solution that's agentless and has no embedded SDKs in the application layer, then a solution that involves Logstash scraping Prometheus metrics (via the http_poller input plugin) and pushing them to one or more configurable outputs, is one possible way to achieve this goal. Basically, this means the application layer can be completely solution/product agnostic when it comes to monitoring (aside from Prometheus metrics format, which has been described by many articles and blogs as the de-facto format for exposing metrics). Applications just exposes a prometheus metrics endpoint and Logstash handles the routing.

# Example

Using the [http_poller](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-http_poller.html) input plugin to scrape prometheus metrics:
```ruby
input {
   http_poller {
      urls => {
         myurl => "https://test:1234/metrics"
      }
      keepalive => true
      automatic_retries => 1
      schedule => { cron => "* * * * * UTC"}
      codec => "prometheus"
   }
}
```

The following prometheus data:
```ruby
# HELP go_memstats_mallocs_total Total number of mallocs.
# TYPE go_memstats_mallocs_total counter
go_memstats_mallocs_total 1.1002486092e+10
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures.
# TYPE go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_inuse_bytes 3472
# HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 600118.2
node_cpu_seconds_total{cpu="0",mode="iowait"} 967.03
```

Can get tanslated to:
```json
{
  "metrics": [
    {
      "name": "go_memstats_mallocs_total",
      "type": "counter",
      "value": 11002486092
    },
    {
      "name": "go_memstats_mcache_inuse_bytes",
      "type": "gauge",
      "value": 3472
    },
    {
      "name": "node_cpu_seconds_total",
      "type": "counter",
      "value": 600118.2,
      "dimensions": {
        "cpu": "0",
        "mode": "idle"
      }
    },
    {
      "name": "node_cpu_seconds_total",
      "type": "counter",
      "value": 967.03,
      "dimensions": {
        "cpu": "0",
        "mode": "iowait"
      }
    }
  ]
}
```
