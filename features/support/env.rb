dir = ::File.expand_path "../../lib", __dir__
$LOAD_PATH.unshift dir unless $LOAD_PATH.include? dir
require "cloud_events"
