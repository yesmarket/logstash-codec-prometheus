# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"

class LogStash::Codecs::Prometheus < LogStash::Codecs::Base
  config_name "prometheus"

  # Include only regex matched metric names
  config :include_metrics, :validate => :array, :default => [ ".*" ]

  # Exclude regex matched metric names, by default exclude unresolved %{field} strings
  config :exclude_metrics, :validate => :array, :default => [ "%\{[^}]+\}" ]

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
          outside, inside = string.match(/^(.+){(.+)}$/).captures
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
    messages = []
    event.to_hash.each do |metric_name,metric_value|
      next unless @include_metrics.empty? || @include_metrics.any? { |regexp| metric_name.match(regexp) }
      next if @exclude_metrics.any? {|regexp| metric_name.match(regexp)}
      messages << "#{metric_name} #{metric_value.to_s}"
    end
    unless messages.empty?
      message = messages.join(NL) + NL
      @on_event.call(event, message)
    end
  end

end
