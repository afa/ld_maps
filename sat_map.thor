require_relative 'boot'
require 'thor'
require 'fileutils'
class SatMap < Thor
  desc 'gen25', 'load gen 25000'
  def gen25
    Gen.call(path: '', skip_templates: %w[])
  end

  desc 'clean', 'remove data and pages'
  def clean
    # Page.dataset.trunc
    FileUtils.rm_f(Dir.glob(File.join(App.config[:temporary_path], '*')))
  end
end

SatMap.start(ARGV)
