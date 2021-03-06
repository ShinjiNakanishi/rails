require 'erb'
require 'yaml'
require 'optparse'

OptionParser.new do |opt|
  opt.banner = "Usage: dbconsole [environment]"
  opt.parse!(ARGV)
  abort opt.to_s unless (0..1).include?(ARGV.size)
end

env = ARGV.first || ENV['RAILS_ENV'] || 'development'
unless config = YAML::load(ERB.new(IO.read(RAILS_ROOT + "/config/database.yml")).result)[env]
  abort "No database is configured for the environment '#{env}'"
end


def find_cmd(*commands)
  dirs_on_path = ENV['PATH'].to_s.split(File::PATH_SEPARATOR)
  commands += commands.map{|cmd| "#{cmd}.exe"} if RUBY_PLATFORM =~ /win32/
  commands.detect do |cmd|
    dirs_on_path.detect do |path|
      File.executable? File.join(path, cmd)
    end
  end || abort("Couldn't find database client: #{commands.join(', ')}. Check your $PATH and try again.")
end

case config["adapter"]
when "mysql"
  args = {
    'host'      => '--host',
    'port'      => '--port',
    'socket'    => '--socket',
    'username'  => '--user',
    'password'  => '--password',
    'encoding'  => '--default-character-set'
  }.map { |opt, arg| "#{arg}=#{config[opt]}" if config[opt] }.compact

  args << config['database']

  exec(find_cmd('mysql5', 'mysql'), *args)

when "postgresql"
  ENV['PGHOST']     = config["host"] if config["host"]
  ENV['PGPORT']     = config["port"].to_s if config["port"]
  ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
  exec(find_cmd('psql'), '-U', config["username"], config["database"])

when "sqlite"
  exec(find_cmd('sqlite'), config["database"])

when "sqlite3"
  exec(find_cmd('sqlite3'), config["database"])

else
  abort "Unknown command-line client for #{config['database']}. Submit a Rails patch to add support!"
end
