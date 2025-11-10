# frozen_string_literal: true

require_relative "helper"

require "io/wait"

require "toys/compat"
require "toys/utils/exec"

describe "examples" do
  let(:exec_util) { Toys::Utils::Exec.new }
  let(:examples_dir) { File.join(File.dirname(__dir__), "examples") }
  let(:client_dir) { File.join(examples_dir, "client") }
  let(:server_dir) { File.join(examples_dir, "server") }

  def expect_read(io, content, timeout)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    received = String.new
    loop do
      time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      assert(time < deadline, "Did not receive content in time: #{content}")
      next unless io.wait_readable((deadline - time).ceil)
      received.concat(io.readpartial(1024))
      return if received.include?(content)
    end
  end

  it "sends and receives an event" do
    skip if Toys::Compat.jruby?
    skip if Toys::Compat.truffleruby?
    skip if Toys::Compat.windows?
    Bundler.with_unbundled_env do
      assert(exec_util.exec(["bundle", "install"], out: :null, chdir: server_dir).success?, "server bundle failed")
      assert(exec_util.exec(["bundle", "install"], out: :null, chdir: client_dir).success?, "client bundle failed")
      exec_util.exec(["bundle", "exec", "ruby", "app.rb"], chdir: server_dir,
                     in: :controller, out: :controller, err: :controller) do |server_control|
        expect_read(server_control.out, "* Listening on http", 5)
        client_result = exec_util.exec(["bundle", "exec", "ruby", "send.rb"], chdir: client_dir)
        assert(client_result.success?)
        expect_read(server_control.err, "Hello, CloudEvents!", 5)
      ensure
        server_control.kill("TERM")
      end
    end
  end
end
