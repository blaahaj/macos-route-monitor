require 'open3'
require 'io/wait'
require 'json'
require_relative 'macos_route_event'
require_relative 'macos_route_list'

buffer = ""
$stdout.sync = true

def emit(raw)
  event = MacosRouteEvent.parse(raw, Time.now.to_f)
  puts JSON.generate(event)
end

Open3.popen2("route", "-n", "monitor") do |i, o, t|
  i.close
  expected_stop = false

  Signal.trap "TERM" do
    Thread.new do
      expected_stop = true
      Process.kill "TERM", t.pid
    end
  end

  puts JSON.generate(MacosRouteList.parse(`netstat -rn`))

  while true
    if o.wait(:read, (buffer == "" ? 60.0 : 1.0))
      r = begin
            o.read_nonblock(100)
          rescue EOFError
            exit if expected_stop

            $stderr.puts "Error: `route -n monitor` exited unexpectedly"
            exit 1
          end

      buffer += r

      # Leading newline after a timeout
      buffer.sub!(/\A\n/, '')

      while buffer.include?("\n\n")
        parts = buffer.split("\n\n", -1)
        buffer = parts.pop
        parts.each { |part| emit part }
      end
    else
      if buffer != ""
        emit buffer
        buffer = ""
      end
    end
  end
end
