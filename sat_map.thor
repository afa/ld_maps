require_relative 'boot'
require 'thor'
class SatMap < Thor
  desc 'gen25', 'load gen 25000'
  def gen25
    Gen.call(path: '', skip_templates: %w[])
  end
end

SatMap.start(ARGV)
