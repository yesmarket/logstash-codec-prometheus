# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require 'json'

class LogStash::Codecs::Prometheus < LogStash::Codecs::Base
  config_name "prometheus"

  public
  def register
    @lines = LogStash::Codecs::Line.new
  end

  public
  def decode(data)
    metrics = []
    previous_message = nil
    @lines.decode(data) do |event|
      unless event.get("message").start_with?("#")
        name, value = event.get("message").split(" ")
        type = previous_message.match(/^# TYPE .+ (.+)$/).captures.first unless previous_message.nil?
        metric = {}
        unless name.match(/^.+{.+}$/)
          metric['name'] = name
          metric['value'] = value.to_f
          metric['type'] = type unless type.nil?
        else
          outside, inside = name.match(/^(.+){(.+)}$/).captures
          metric['name'] = outside
          metric['value'] = value.to_f
          metric['type'] = type unless type.nil?
          kvps = inside.split(",")
          dimensions = {}
          kvps.each do |kvp|
            key, value = kvp.split("=")
            dimensions[key.downcase] = value.gsub!(/^\"|\"?$/, "")
          end
          metric['dimensions'] = dimensions
        end
        metrics << metric
      end
      previous_message = event.get("message").match(/^# TYPE .+ .+$/) ? event.get("message") : nil
    end
    unless metrics.empty?
      yield LogStash::Event.new({"metrics" => metrics})
    end
  end

  public
  def encode(event)
    @on_event.call(event, event.to_json)
  end

end
