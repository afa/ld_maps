class App
  class << self
    attr_accessor :db, :config
  end

  # rack placeholder for racksh. remove when sinatred
  def call(_env)
    [200, { 'Content-Type' => 'text/html' }, ['Rack!']]
  end
end
