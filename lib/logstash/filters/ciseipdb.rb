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

  public
  def register
    require "gdbm"
    require "json"

    @logger.info("New CISE IPDB filter", :database => database)
    @gdbm = GDBM.new(database)
  end # def register

  public
  def filter(event)

    ipaddress = event.sprintf(@ipaddress)
    data = check_gdbm(ipaddress)

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
      nil
    end
  end # def check_gdbm

end # class LogStash::Filters::Ciseipdb
