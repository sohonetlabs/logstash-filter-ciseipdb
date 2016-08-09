# Ciseipdb Logstash Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

This plugin allows you to search elasticsearch for matching IPs in Elasticsearch IP database indexes and add that information into events.

Matching IPs are cached in redis.

Example:

    ciseipdb {
      hosts   => [ "elasticsearch" ]
      indexes => [ "ipdatabase" ]
      ipaddress => "%{ip_dst}"
      target  => "dst_info"
    }
