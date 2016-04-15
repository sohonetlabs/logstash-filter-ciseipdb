# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/plugin"
require "logstash/filters/sohonetipdb"

describe LogStash::Filters::Sohonetipdb do

  context "registration" do

    let(:plugin) { LogStash::Plugin.lookup("filter", "sohonetipdb").new({}) }

    it "should not raise an exception" do
      expect {plugin.register}.to_not raise_error
    end
  end

end
