# frozen_string_literal: true

require_relative "../helper"

describe CloudEvents::Event::Opaque do
  let(:my_content_type_string) { "text/plain; charset=us-ascii" }
  let(:my_content_type) { CloudEvents::ContentType.new(my_content_type_string) }
  let(:my_content) { "12345" }

  it "handles non-batch" do
    event = CloudEvents::Event::Opaque.new(my_content, my_content_type)
    assert_equal my_content, event.content
    assert_equal my_content_type, event.content_type
    refute event.batch?
    assert Ractor.shareable?(event) if defined? Ractor
  end

  it "handles batch" do
    event = CloudEvents::Event::Opaque.new(my_content, my_content_type, batch: true)
    assert_equal my_content, event.content
    assert_equal my_content_type, event.content_type
    assert event.batch?
    assert Ractor.shareable?(event) if defined? Ractor
  end

  it "checks equality" do
    event1 = CloudEvents::Event::Opaque.new(my_content, my_content_type)
    event2 = CloudEvents::Event::Opaque.new(my_content, my_content_type)
    event3 = CloudEvents::Event::Opaque.new(my_content, my_content_type, batch: true)
    assert_equal event1, event2
    refute_equal event1, event3
  end
end
