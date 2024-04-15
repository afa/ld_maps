module SatMaps
  class ProcessCheckedPages < BaseInteractor
    option :session, default: -> { Mechanize.new }
    
  end
end
