require 'rbconfig'

unless defined?(Mongrel) 
  puts "PROBLEM: Mongrel is not available on your system (or not in your path)"
  exit 1
end

require 'optparse'

detach = false
ip = nil
port = nil

ARGV.clone.options do |opt|
  opt.on("-p", "--port=port", Integer,
          "Runs Rails on the specified port.",
          "Default: 3000") { |p| port = p }
  opt.on("-a", "--binding=ip", String,
          "Binds Rails to the specified ip.",
          "Default: 0.0.0.0") { |i| ip = i }
  opt.on('-h', '--help', 'Show this message.') { puts opt; exit 0 }
  opt.on('-d', '-d', 'Call with -d to detach') { detach = true }
  opt.parse!
end

default_port, default_ip = 3000, '0.0.0.0'
puts "=> Rails application started on http://#{ip || default_ip}:#{port || default_port}"

if !detach
  puts "=> Call with -d to detach"
  puts "=> Ctrl-C to shutdown server"
  detach = false
end

trap(:INT) { exit }

tail_thread = nil

begin
  ARGV.unshift("start")
  load 'mongrel_rails'
ensure
  unless detach
    tail_thread.kill if tail_thread
    puts 'Exiting'
  end
end