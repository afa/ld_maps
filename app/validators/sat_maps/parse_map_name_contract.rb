module SatMaps
  class ParseMapNameContract < BaseContract
    SIZES = %(001m 500k 200k 100k).freeze
    ROWS_60 = %w[p q r s t u v xp xq xr xs xt xu xv].freeze
    ROWS_76 = %w[t u v xt xu xv].freeze
    ROWS_88 = %w[z xz].freeze

    JOINS_COLUMN = {
      '001m' => {'z'..'z' => 0, 'xz'..'xz' => 0, 'a'..'o' => 1, 'p'..'s' => 2, 'xp'..'xs' => 2, 't'..'v' => 4, 'xt'..'xv' => 4},
      '500k' => {},
      '200k' => {},
      '100k' => {}
    }.freeze
    JOINS_KVADRAT = {
      '001m' => {'a'..'z' => 0, 'xa'..'xz' => 0},
      '500k' => {},
      '200k' => {},
      '100k' => {}
    }.freeze
    schema do
      required(:size).filled(:string, included_in?: %w[001m 100k 200k 500k])
      required(:row).filled(:string)
      optional(:column).filled(:string)
      optional(:joined_column).array(:string)
      optional(:kvadrat).filled(:string)
      optional(:joined_kvadrat).array(:string)
      optional(:year).filled(:string)
      optional(:tail).array(:string)
    end

    rule(:row) do
      key.failure('is invalid row') unless value =~ /x?[a-vz]/
    end

    rule(:column) do
      if value
        unless values[:joined_column].nil? || values[:joined_column].empty?
          key.failure('should be skipped if joined_column defined')
        end

        unless select_column_count(values[:size], values[:row]) == 1
          key.failure("no columns for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:joined_column) do
      if value
        unless values[:column].nil? || values[:column].empty?
          key.failure('should be skipped if column defined')
        end

        unless select_column_count(values[:size], values[:row]) == value.size
          key.failure("unexpected columns count for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:kvadrat) do
      if value
        unless values[:joined_kvadrat].nil? || values[:joined_kvadrat].empty?
          key.failure('should be skipped if joined_kvadrat defined')
        end

        unless select_column_count(values[:size], values[:row]) == 1
          key.failure("no columns for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:joined_kvadrat) do
      if value
        unless values[:kvadrat].nil? || values[:kvadrat].empty?
          key.failure("should be skipped(#{value.inspect}) if kvadrat defined")
        end

        unless select_column_count(values[:size], values[:row]) == value.size
          key.failure("unexpected columns count for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:tail) do
      key.failure("unexpected tail in parsing: #{value.inspect}") if value
    end

    def select_column_count(size, row)
      JOINS_COLUMN.fetch(size, []).select { |k, v| k.include?(row) }.values.first
    end

    def select_kvadrat_count(size, row)
      JOINS_KVADRAT.fetch(size, []).select { |k, v| k.include?(row) }.values.first
    end
  end
end
