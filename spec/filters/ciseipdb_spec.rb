# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/plugin"
require "logstash/filters/ciseipdb"

describe LogStash::Filters::Ciseipdb do

  let (:cise_config) {{
    'hosts'      => [ 'elasticsearch' ],
    'ipaddress'  => '127.0.0.1',
    'target'     => 'destination',
  }}

  context "registration" do

    let(:plugin) { LogStash::Plugin.lookup("filter", "ciseipdb").new(cise_config) }

    it "should not raise an exception" do
      expect {plugin.register}.to_not raise_error
    end
  end

end
