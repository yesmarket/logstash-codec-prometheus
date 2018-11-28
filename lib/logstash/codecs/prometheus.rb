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
    @lines.decode(data) do |event|
      unless event.get("message").start_with?("#")
        metric_name, metric_value = event.get("message").split(" ")
        unless metric_name.match(/^.+{.+}$/)
          yield LogStash::Event.new(metric_name => metric_value.to_f)
        else
          outside, inside = metric_name.match(/^(.+){(.+)}$/).captures
          vars = inside.split(",")
          vars.each do |var|
            key, value = var.split("=")
            custom_metric_name = [outside,key,value.gsub!(/^\"|\"?$/, "")].join('_')
            yield LogStash::Event.new(custom_metric_name => metric_value.to_f)
          end
        end
      end
    end
  end

  public
  def encode(event)
    h = {}
    event.to_hash.each do |metric_name,metric_value|
      h[metric_name] = metric_value
    end
    unless h.empty?
      @on_event.call(event, h.to_json)
    end
  end

end
