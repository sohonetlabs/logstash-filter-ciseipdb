# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/plugin"
require "logstash/filters/ciseipdb"

describe LogStash::Filters::Ciseipdb do

  context "registration" do

    let(:plugin) { LogStash::Plugin.lookup("filter", "ciseipdb").new({}) }

    it "should not raise an exception" do
      expect {plugin.register}.to_not raise_error
    end
  end

end
