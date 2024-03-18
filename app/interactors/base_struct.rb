require 'dry/types'
require 'dry/struct'

module Types
  include Dry::Types()
end

class BaseStruct < Dry::Struct
end
