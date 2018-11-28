# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require 'json'

class LogStash::Codecs::Prometheus < LogStash::Codecs::Base
  config_name "prometheus"

  # create individual events for each metric
  config :multi_event, :validate => :boolean, :default => false

  public
  def register
    @lines = LogStash::Codecs::Line.new
  end

  public
  def decode(data)
    events = []
    @lines.decode(data) do |event|
      unless event.get("message").start_with?("#")
        metric_name, metric_value = event.get("message").split(" ")
        unless metric_name.match(/^.+{.+}$/)
          events << {metric_name => metric_value.to_f}
        else
          outside, inside = metric_name.match(/^(.+){(.+)}$/).captures
          vars = inside.split(",")
          labels = {}
          keys = []
          vars.each do |var|
            key, value = var.split("=")
            keys << key
            labels[key.downcase] = value.gsub!(/^\"|\"?$/, "")
          end
          custom_metric_name = keys.unshift(outside.downcase).join('_')
          events << {custom_metric_name => {outside.downcase => metric_value.to_f, "labels" => labels}}
        end
      end
    end
    unless events.empty?
      if @multi_event
        events.each do |event|
          yield LogStash::Event.new(event)
        end
      else
        hash = {}
        events.each do |event|
          event.to_h.each do |metric_name, metric_value|
            hash[metric_name] = metric_value
          end
        end
        yield LogStash::Event.new(hash)
      end
    end
  end

  public
  def encode(event)
    @on_event.call(event, event.to_json)
  end

end
