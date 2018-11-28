# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/prometheus"
require "logstash/event"
require "logstash/json"
require 'json'
require "insist"

describe LogStash::Codecs::Prometheus do

	let(:cfg) {{"multi_event" => false}}

	let(:codec) {LogStash::Codecs::Prometheus.new(cfg)}

	before do
		codec.register
	end

	context "#decode" do

		it "should ignore comments" do
			event_returned = false
			codec.decode("#test 1\n") do |event|
				event_returned = true
			end
			insist {!event_returned}
		end

		it "should return an event from single full prometheus line" do
			codec.decode("test 1\n") do |event|
				insist {event.is_a?(LogStash::Event)}
				insist {event.get("test")} == 1.to_f
			end
		end

		it "should return single event given multiple prometheus lines" do
			counter = 0
			codec.decode("test1 1\ntest2 2\n") do |event|
				insist {event.is_a?(LogStash::Event)}
				insist {event.get("test1")} == 1.to_f
				insist {event.get("test2")} == 2.to_f
				counter += 1
			end
			insist {counter} == 1
		end

		it "should return single event given a labeled metric" do

			counter = 0
			codec.decode("test{a=\"b\",x=\"y\"} 1\n") do |event|
				insist {event.is_a?(LogStash::Event)}
				insist {event.get("test_a_x")} == { "test" => 1.0, "labels" => { "a" => "b", "x" => "y" }}
				counter += 1
			end
			insist {counter} == 1
		end

		it "should return event with labels for labeled metric" do
			codec.decode("test{a=\"b\"} 1\n") do |event|
				insist {event.is_a?(LogStash::Event)}
				insist {event.get("test_a")} == { "test" => 1.0, "labels" => { "a" => "b" }}
			end
		end

	end

	context "#encode" do

		it "should return json data" do
			data = {"foo" => 1.0, "bar" => { "value" => 2.0, "labels" => { "a" => "b" }}}
			event = LogStash::Event.new(data)
			got_event = false
			codec.on_event do |event, message|
				insist {message.chomp} == event.to_json
				insist {LogStash::Json.load(message)["foo"]} == data["foo"]
				insist {LogStash::Json.load(message)["bar"]} == data["bar"]
				got_event = true
			end
			codec.encode(event)
			insist {got_event}
		end

	end
end