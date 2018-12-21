# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/prometheus"
require "logstash/event"
require "logstash/json"
require 'json'
require "insist"

describe LogStash::Codecs::Prometheus do

	let(:codec) {LogStash::Codecs::Prometheus.new()}

	before do
		codec.register
	end

	context "#decode" do

		# it "should ignore comments" do
		# 	event_returned = false
		# 	codec.decode("#test 1\n") do |event|
		# 		event_returned = true
		# 	end
		# 	insist {!event_returned}
		# end

		# it "should return an single metric given single prometheus line" do
		# 	codec.decode("test 1\n") do |event|
		# 		insist {event.is_a?(LogStash::Event)}
		# 		insist {event.get("metrics")} == [{"name"=>"test","value"=>1.to_f}]
		# 	end
		# end

		# it "should return multiple metrics given multiple prometheus lines" do
		# 	codec.decode("test1 1\ntest2 2\n") do |event|
		# 		insist {event.is_a?(LogStash::Event)}
		# 		insist {event.get("metrics")} == [{"name"=>"test1","value"=>1.to_f},{"name"=>"test2","value"=>2.to_f}]
		# 	end
		# end

		# it "should return metric with dimensions for a dimensional metric" do
		# 	codec.decode("test{a=\"b\",x=\"y\"} 1\n") do |event|
		# 		insist {event.is_a?(LogStash::Event)}
		# 		insist {event.get("metrics")} == [{"name"=>"test","value"=>1.to_f,"dimensions"=>{"a"=>"b","x"=>"y"}}]
		# 	end
		# end

		# it "should include type if exists in comment" do
		# 	codec.decode("# TYPE test1 counter\ntest1 1\n") do |event|
		# 		insist {event.is_a?(LogStash::Event)}
		# 		insist {event.get("metrics")} == [{"name"=>"test1","value"=>1.to_f,"type"=>"counter"}]
		# 	end
		# end

		it "should be able to process high precision numbers" do
			codec.decode("test 1.1002486092e+10") do |event|
				insist {event.is_a?(LogStash::Event)}
				insist {event.get("metrics")} == [{"name"=>"test","value"=>1.1002486092e+10.to_f}]
			end
		end

	end

	# context "#encode" do

	# 	it "should return json data" do
	# 		data = {"metrics"=>[{"name"=>"test","value"=>1.to_f,"dimensions"=>{"a"=>"b"}}]}
	# 		event = LogStash::Event.new(data)
	# 		got_event = false
	# 		codec.on_event do |event, message|
	# 			insist {message.chomp} == event.to_json
	# 			got_event = true
	# 		end
	# 		codec.encode(event)
	# 		insist {got_event}
	# 	end

	# end
end