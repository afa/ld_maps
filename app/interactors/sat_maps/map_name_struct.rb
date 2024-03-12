module Types
  include Dry::Types()
end

module SatMaps
  class MapNameStruct < Dry::Struct
    attribute :row, Types::String
    attribute? :column, Types::Coercible::Integer.optional
    # attribute? :doubled_column_1m, Types::Array.of(Dry::Struct) do
    #   attribute :first, Types::Coercible::Integer
      # attribute :second, Types::Coercible::Integer
    # end
    attribute? :doubled_column_1m, Dry::Struct do
      attribute :first, Types::Coercible::Integer
      attribute :second, Types::Coercible::Integer
    end


  end
end
