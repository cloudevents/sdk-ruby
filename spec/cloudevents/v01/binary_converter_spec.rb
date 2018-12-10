require "spec_helper"

describe Cloudevents::V01::BinaryConverter do
  describe "#can_read?" do
    context "supported content type" do
      it "returns true" do
        converter = Cloudevents::V01::BinaryConverter.new

        converter.can_read?("application/json").must_equal(true)
        converter.can_read?("application/xml").must_equal(true)
        converter.can_read?("application/octet-stream").must_equal(true)
      end
    end

    context "unsupported content type" do
      it "returns false" do
        converter = Cloudevents::V01::BinaryConverter.new

        converter.can_read?("application/soap+xml").must_equal(false)
      end
    end
  end
end
