module Types
  include Dry::Types()
end

module SatMaps
  class MapNameStruct < Dry::Struct
    attribute :size, Types::String
    attribute :row, Types::String
    attribute? :column, Types::String.optional
    attribute? :joined_column, Types::Array.of(Types::String)
    attribute? :kvadrat, Types::String.optional
    attribute? :joined_kvadrat, Types::Array.of(Types::String)
    attribute? :tail, Types::Array.of(Types::String)
  end
end
