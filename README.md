# Ciseipdb Logstash Plugin

[![Build Status](https://travis-ci.org/sohonetlabs/logstash-filter-ciseipdb.svg?branch=master)](https://travis-ci.org/sohonetlabs/logstash-filter-ciseipdb)

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

This plugin allows you to search for matching IPs from a generated IP database file, and add that information into events.

This is intended to work with [generate-ipdatabase](https://github.com/sohonetlabs/generate-ipdatabase) which will create the Elasticsearch IP database entries, and <TBC> which generates the local database file.

Matching IPs are cached in redis.

Example:

    ciseipdb {
      database   => "/etc/logstash/ipdatabase.db"
      ipaddress  => "%{ip_dst}"
      target     => "dst_info"
      redis_host => "localhost'
    }
