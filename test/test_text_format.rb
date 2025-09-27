# frozen_string_literal: true

require_relative "helper"

require "date"
require "json"
require "stringio"
require "uri"

describe CloudEvents::TextFormat do
  let(:text_format) { CloudEvents::TextFormat.new }
  let(:content) { '{"foo":"bar"}' }

  describe "decode_data" do
    [
      "text/plain",
      "text/plain; charset=utf-8",
      "text/html",
      "application/octet-stream"
    ].each do |content_type|
      it "decodes content type #{content_type}" do
        content_type = CloudEvents::ContentType.new content_type
        result = text_format.decode_data content: content, content_type: content_type
        assert_equal content, result[:data]
        assert_equal content_type, result[:content_type]
      end
    end

    it "fails to decode content type application/json" do
      content_type = CloudEvents::ContentType.new "application/json"
      result = text_format.decode_data content: content, content_type: content_type
      assert_nil result
    end
  end

  describe "encode_data" do
    [
      "text/plain",
      "text/plain; charset=utf-8",
      "text/html",
      "application/octet-stream"
    ].each do |content_type|
      it "encodes content type #{content_type}" do
        content_type = CloudEvents::ContentType.new content_type
        result = text_format.encode_data data: content, content_type: content_type
        assert_equal content, result[:content]
        assert_equal content_type, result[:content_type]
      end
    end

    it "fails to encode content type application/json" do
      content_type = CloudEvents::ContentType.new "application/json"
      result = text_format.encode_data data: content, content_type: content_type
      assert_nil result
    end
  end
end
