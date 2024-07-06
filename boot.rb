ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

require 'zeitwerk'
require 'sequel'
require 'yaml'
require_relative 'app'

# autoload classes (app/)
loader = Zeitwerk::Loader.new
Dir['./app/*'].each { |p| loader.push_dir(p) }
loader.setup

begin
  App.config = YAML.load_file('config.yml', symbolize_names: true)
rescue Exception => e
  puts "config not loaded with #{e.message}"
  raise
end

begin
  db_url = App.config[:db] || ENV['DATABASE_URL'] || 'postgres://localhost/load_map'
  App.db = Sequel.connect(db_url)
  App.db.extension :pg_json
  # App.db.wrap_json_primitives = true
rescue Exception => e
  puts "db not connected with #{e.message}"
  raise
end
