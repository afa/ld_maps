module SatMaps
  class MapNameStruct < BaseStruct
    attribute :size, Types::String
    attribute :row, Types::String
    attribute? :column, Types::String.optional
    attribute? :joined_column, Types::Array.of(Types::String)
    attribute? :kvadrat, Types::String.optional
    attribute? :joined_kvadrat, Types::Array.of(Types::String)
    attribute? :tail, Types::Array.of(Types::String)
  end
end
