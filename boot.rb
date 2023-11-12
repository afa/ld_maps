ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

require 'sequel'
require_relative './app'

$LOAD_PATH << File.expand_path('../app/interactors', __FILE__)

# autoload classes (app/)
def autold(path)
  $LOAD_PATH << path if File.directory?(path)
  files = Dir[File.join(path, '**/*.rb')].map do |f|
    f.delete_suffix('.rb').delete_prefix(path + '/').delete_prefix(path).split('/')
  end.sort_by(&:size)
  flist = files.inject([]) { |ar, i| ar << i.dup }
  classes = flist.map { |lst| lst.pop.split('_').map(&:capitalize).join }
  mods = flist.map do |ar|
    ar.map { |i| i.split('_').map(&:capitalize).join }
  end
  classes.each_with_index do |cl, idx|
    if mods[idx].empty?
      autoload(cl.to_sym, files[idx].join('/'))
      next
    end
    m = mods[idx].inject(Object) do |rez, md|
      unless rez.const_defined?(md)
        rez.const_set(md, Module.new)
      end
      rez.const_get(md)
    end
    m.autoload(cl.to_sym, files[idx].join('/'))
  end
end
Dir['./app/*'].each { |p| autold(p) }

begin
  App.config = YAML.load_file('config.yml', symbolize_names: true)
rescue Exception => e
  puts "config not loaded with #{e.message}"
  raise
end

begin
  db_url = App.config[:db] || ENV['DATABASE_URL'] || 'postgres://localhost/load_map'
  App.db = Sequel.connect(db_url)
rescue Exception => e
  puts "db not connected with #{e.message}"
  raise
end
