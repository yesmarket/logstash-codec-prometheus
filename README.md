This codec translates prometheus data into json. For example:

The following prometheus data:
```ruby
# HELP go_memstats_mallocs_total Total number of mallocs.
# TYPE go_memstats_mallocs_total counter
go_memstats_mallocs_total 
# HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures.
# TYPE go_memstats_mcache_inuse_bytes gauge
go_memstats_mcache_inuse_bytes 3472
# HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 600118.2
node_cpu_seconds_total{cpu="0",mode="iowait"} 967.03
```
would get tanslated to

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

Can be used with the [http_poller](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-http_poller.html) to scrape metrics endpoints. See logstash config below:
```ruby
input {
   http_poller {
      urls => {
         myurl => "https://test:1234"
      }
      keepalive => true
      automatic_retries => 1
      schedule => { cron => "* * * * * UTC"}
      codec => "prometheus"
   }
}
```