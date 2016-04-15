require "logstash/filters/base"
require "logstash/namespace"
require "base64"

# Search elasticsearch for matching IPs in sohonet IP databases and add that
# inforation into events.
# Cache matching IPs in redis.
#
# Example:
#
# sohonetipdb {
#    hosts   => [ "elasticsearch.elk.sohonet.internal" ]
#    indexes => [ "badip" ]
#    ipaddress => "%{ip_dst}"
#    target  => "dst_info"
# }

class LogStash::Filters::Sohonetipdb < LogStash::Filters::Base
  config_name "sohonetipdb"

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

    @logger.info("New ElasticSearch filter", :hosts => hosts)
    @client = Elasticsearch::Client.new hosts: hosts, transport_options: transport_options

    @redis = Redis.new
  end # def register

  public
  def filter(event)

    ipaddress = event.sprintf(@ipaddress)
    ipdb = Array.new

    # Check ip address in redis
    data = check_redis(ipaddress)

    # IP not in redis, lookup elasticsearch, add to redis
    if data.nil?
      data = search(ipaddress)
      update_redis(ipaddress, data)
    end

    # Update event
    event[@target] = { databases: data }
    filter_matched(event)

  end # def filter

  def search(ip)
    output = Array.new
    begin
      query = { query: { term: { IPADDRESS: ip } } }
      results = @client.search index: @indexes, body: query

      if results['hits']['total'] >= 1
        results['hits']['hits'].each do |hit|
          output << hit['_source']['database']['name']
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
