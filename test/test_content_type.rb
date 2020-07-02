# frozen_string_literal: true

require_relative "helper"

describe CloudEvents::ContentType do
  it "recognizes simple media type and subtype" do
    content_type = CloudEvents::ContentType.new "application/cloudevents"
    assert_equal "application", content_type.media_type
    assert_equal "cloudevents", content_type.subtype
    assert_equal "cloudevents", content_type.subtype_base
    assert_nil content_type.subtype_format
  end

  it "normalizes media type and subtype case" do
    content_type = CloudEvents::ContentType.new "Application/CloudEvents"
    assert_equal "application", content_type.media_type
    assert_equal "cloudevents", content_type.subtype
    assert_equal "cloudevents", content_type.subtype_base
    assert_nil content_type.subtype_format
  end

  it "recognizes extended subtype" do
    content_type = CloudEvents::ContentType.new "application/cloudevents+json"
    assert_equal "cloudevents+json", content_type.subtype
    assert_equal "cloudevents", content_type.subtype_base
    assert_equal "json", content_type.subtype_format
  end

  it "recognizes charseet param" do
    content_type = CloudEvents::ContentType.new "application/json; charset=utf-8"
    assert_equal [["charset", "utf-8"]], content_type.params
    assert_equal "utf-8", content_type.charset
  end

  it "recognizes quoted charset param" do
    content_type = CloudEvents::ContentType.new "application/json; charset=\"utf-8\""
    assert_equal [["charset", "utf-8"]], content_type.params
    assert_equal "utf-8", content_type.charset
  end

  it "recognizes arbitrary quoted param values" do
    content_type = CloudEvents::ContentType.new "application/json; foo=\"hi\\\"\\\\ \" ;bar=ho"
    assert_equal [["foo", "hi\"\\ "], ["bar", "ho"]], content_type.params
  end

  it "remembers the input string" do
    header = "Application/CloudEvents+JSON; charset=utf-8"
    content_type = CloudEvents::ContentType.new header
    assert_equal header, content_type.string
  end

  it "produces a case-normalized canonical string" do
    header = "Application/CloudEvents+JSON; charset=utf-8"
    content_type = CloudEvents::ContentType.new header
    assert_equal header.downcase, content_type.canonical_string
  end

  it "produces canonical string with spaces normalized" do
    header = "Application /CloudEvents+JSON ; charset=utf-8 "
    content_type = CloudEvents::ContentType.new header
    assert_equal "application/cloudevents+json; charset=utf-8", content_type.canonical_string
  end

  it "produces canonical string with quoted values" do
    header = "application/cloudevents+json; foo=\"utf-8 \"; bar=\"hi\" ;baz=\"hi\\\"\""
    content_type = CloudEvents::ContentType.new header
    assert_equal "application/cloudevents+json; foo=\"utf-8 \"; bar=hi; baz=\"hi\\\"\"", content_type.canonical_string
  end

  it "drops comments" do
    header = "application/json (JSON rulz); ((oh btw) Ruby \\( rocks) charset=utf-8 (and so does unicode)(srsly)"
    content_type = CloudEvents::ContentType.new header
    assert_equal "application/json; charset=utf-8", content_type.canonical_string
  end

  it "uses the default in case of a parse error" do
    content_type = CloudEvents::ContentType.new ""
    assert_equal "text", content_type.media_type
    assert_equal "plain", content_type.subtype
    assert_equal "us-ascii", content_type.charset
    assert_equal "text/plain", content_type.canonical_string
    assert_equal "Failed to parse media type", content_type.error_message
  end
end
