# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/prometheus"
require "logstash/event"

describe LogStash::Codecs::Prometheus do
  subject do
    next LogStash::Codecs::Prometheus.new
  end

  context "#encode" do

  end

  context "#decode" do

  end

end