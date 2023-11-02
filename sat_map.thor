require_relative 'boot'
require 'thor'
class SatMap < Thor
  desc '25', 'load gen 25000'
  def load25
    pp Gen.call(path: '')
  end

  desc 'gen25', 'load gen 25000'
  def gen25
    pp Gen.call(path: '', skip_templates: %w[])
  end
end

SatMap.start(ARGV)
