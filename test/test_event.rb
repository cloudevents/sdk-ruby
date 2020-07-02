# frozen_string_literal: true

require_relative "helper"

describe CloudEvents::Event do
  let(:my_id) { "my_id" }
  let(:my_source) { "/my_source" }
  let(:my_type) { "my_type" }

  it "recognizes spec version 0" do
    event = CloudEvents::Event.create id:           my_id,
                                      source:       my_source,
                                      type:         my_type,
                                      spec_version: "0.3"
    assert_instance_of CloudEvents::Event::V0, event
  end

  it "recognizes spec version 1" do
    event = CloudEvents::Event.create id:           my_id,
                                      source:       my_source,
                                      type:         my_type,
                                      spec_version: "1.0"
    assert_instance_of CloudEvents::Event::V1, event
  end

  it "rejects spec version 2" do
    assert_raises CloudEvents::SpecVersionError do
      CloudEvents::Event.create id:           my_id,
                                source:       my_source,
                                type:         my_type,
                                spec_version: "2.0"
    end
  end
end
