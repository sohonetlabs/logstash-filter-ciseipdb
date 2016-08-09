require "logstash/filters/base"
require "logstash/namespace"
require "base64"

# Search elasticsearch for matching IPs in Elasticsearch IP database indexes i
# and add that information into events.
#
# Caches matching IPs in redis.
#
# Example:
#
# ciseipdb {
#    hosts   => [ "elasticsearch" ]
#    indexes => [ "ipdatabase" ]
#    ipaddress => "%{ip_dst}"
#    target  => "dst_info"
# }

class LogStash::Filters::Ciseipdb < LogStash::Filters::Base
  config_name "ciseipdb"

  # List of elasticsearch hosts to use for querying.
  config :hosts, :validate => :array, :required => true

  # List of indexes to perform the search query against.
  config :indexes, :validate => :array, :default => [""]

  # IP Addresses
  config :ipaddress, :validate => :string, :required => true

  # Target field for added fields
  config :target, :validate => :string, :required => true

  # Basic Auth - username
  config :user, :validate => :string

  # Basic Auth - password
  config :password, :validate => :password

  # SSL
  config :ssl, :validate => :boolean, :default => false

  # SSL Certificate Authority file
  config :ca_file, :validate => :path

  # Redis host
  config :redis_host, :validate => :string, :default => "localhost"

  # Redis key TTL
  config :redis_ttl, :validate => :number, :default => 3600


  public
  def register
    require "elasticsearch"
    require "redis"

    transport_options = {}

    if @user && @password
      token = Base64.strict_encode64("#{@user}:#{@password.value}")
      transport_options[:headers] = { Authorization: "Basic #{token}" }
    end

    hosts = if @ssl then
      @hosts.map {|h| { host: h, scheme: 'https' } }
    else
      @hosts
    end

    if @ssl && @ca_file
      transport_options[:ssl] = { ca_file: @ca_file }
    end

    @logger.info("New CISE IPDB filter", :hosts => hosts)
    @client = Elasticsearch::Client.new hosts: hosts, transport_options: transport_options

    @redis = Redis.new(:host => redis_host)
  end # def register

  public
  def filter(event)

    ipaddress = event.sprintf(@ipaddress)

    # Check ip address in redis
    data = check_redis(ipaddress)

    # IP not in redis, lookup elasticsearch, add to redis
    if data.nil?
      data = search(ipaddress)
      update_redis(ipaddress, data)
    end

    # Update event
    data.each_pair do |k,v|
      targetname = "#{@target}_#{k}"
      event[targetname] = v
    end
    filter_matched(event)

  end # def filter

  def search(ip)
    output = Hash.new

    begin
      query = {
        query: {
          filtered: {
            filter: {
              and: [
                { term: { IPADDRESS: ip } },
                { range: { "@timestamp" => { gte: "now-1d/d", lt: "now" } } }
              ]
            }
          }
        }
      }
      results = @client.search index: @indexes, body: query

      if results['hits']['total'] >= 1
        output['databases'] = Array.new
        output['reputation_score'] = 0
        results['hits']['hits'].each do |hit|
          output['databases'] << hit['_source']['database']['shortname']
          output['reputation_score'] += hit['_source']['database']['reputation_score'].to_i

          # Extra data from nipap
          if hit['_source']['database']['shortname'] == 'nipap'
            output['service_slug'] = hit['_source']['service_slug']
            output['description'] = hit['_source']['description']
            output['router'] = hit['_source']['router']
          end
        end
      end

    rescue => e
      @logger.debug("No hits for ipaddresses", :query => query, :error => e)
    end #begin..rescue

    output
  end # def search

  def check_redis(ip)
    begin
      output = @redis.get(ip)
      if output.nil?
        output
      else
        eval(output)
      end
    rescue => e
      @logger.warn("Problem getting key from redis", :ip => ip, :error => e)
    end
  end # def check_redis

  def update_redis(ip, data)
    begin
      @redis.set(ip, data)
      @redis.expire(ip, @redis_ttl)
    rescue => e
      @logger.warn("Problem updating redis", :ip => ip, :data => data , :error => e)
    end
  end # def update_redis

end # class LogStash::Filters::Elasticsearch
