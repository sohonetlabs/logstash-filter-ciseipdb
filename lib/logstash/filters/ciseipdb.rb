require "logstash/filters/base"
require "logstash/namespace"
require "base64"

# Search for matching IPs in GDBM database of IP addresses
# and add that information into events.
#
# Caches matching IPs in redis.
#
# Example:
#
# ciseipdb {
#    database => "/etc/logstash/ipdatabase.db"
#    ipaddress => "%{ip_dst}"
#    target  => "dst_info"
# }

class LogStash::Filters::Ciseipdb < LogStash::Filters::Base
  config_name "ciseipdb"

  # Database file location
  config :database, :validate => :string, :required => true

  # IP Addresses
  config :ipaddress, :validate => :string, :required => true

  # Target field for added fields
  config :target, :validate => :string, :required => true

  # Redis host
  config :redis_host, :validate => :string, :default => "localhost"

  # Redis key TTL
  config :redis_ttl, :validate => :number, :default => 3600


  public
  def register
    require "gdbm"
    require "redis"
    require "json"

    @logger.info("New CISE IPDB filter", :database => database)
    @gdbm = GDBM.new(database)
    @redis = Redis.new(:host => redis_host)
  end # def register

  public
  def filter(event)

    ipaddress = event.sprintf(@ipaddress)

    # Check ip address in redis
    data = check_redis(ipaddress)

    # IP not in redis, lookup elasticsearch, add to redis
    if data.nil?
      data = check_gdbm(ipaddress)
      update_redis(ipaddress, data)
    end

    # Update event
    unless data.nil?
      data.each_pair do |k,v|
        targetname = "#{@target}_#{k}"
        event[targetname] = v
      end
      filter_matched(event)
    end

  end # def filter

  def check_gdbm(ip)
    begin
      output = @gdbm[ip]
      if output.nil?
        output
      else
        JSON.parse(output)
      end
    rescue => e
      @logger.warn("Problem getting data from database", :ip => ip, :error => e)
    end
  end # def check_gdbm

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

end # class LogStash::Filters::Ciseipdb
