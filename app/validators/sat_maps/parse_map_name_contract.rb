module SatMaps
  class ParseMapNameContract < BaseContract
    SIZES = %(001m 500k 200k 100k).freeze
    ROWS_60 = %w[p q r s t u v xp xq xr xs xt xu xv].freeze
    ROWS_76 = %w[t u v xt xu xv].freeze
    ROWS_88 = %w[z xz].freeze

    JOINS_COLUMN = {
      '001m' => {
        'z'..'z' => 0, 'xz'..'xz' => 0,
        'a'..'o' => 1, 'xa'..'xo' => 1,
        'p'..'s' => 2, 'xp'..'xs' => 2,
        't'..'v' => 4, 'xt'..'xv' => 4
      },
      '500k' => {
        'z'..'z' => 0, 'xz'..'xz' => 0,
        'a'..'v' => 1, 'xa'..'xv' => 1
      },
      '200k' => {
        'z'..'z' => 0, 'xz'..'xz' => 0,
        'a'..'v' => 1, 'xa'..'xv' => 1
      },
      '100k' => {
        'z'..'z' => 0, 'xz'..'xz' => 0,
        'a'..'v' => 1, 'xa'..'xv' => 1
      }
    }.freeze
    JOINS_KVADRAT = {
      '001m' => { 'a'..'z' => 0, 'xa'..'xz' => 0 },
      '500k' => {
        'a'..'o' => 1, 'xa'..'xo' => 1,
        'p'..'v' => 2, 'xp'..'xv' => 2,
        'z'..'z' => 1, 'xz'..'xz' => 1
      },
      '200k' => {
        'a'..'o' => 1, 'xa'..'xo' => 1,
        'p'..'s' => 2, 'xp'..'xs' => 2,
        't'..'v' => 3, 'xt'..'xv' => 3,
        'z'..'z' => 1, 'xz'..'xz' => 1
      },
      '100k' => {
        'a'..'o' => 1, 'xa'..'xo' => 1,
        'p'..'s' => 1, 'xp'..'xs' => 1,
        't'..'v' => 1, 'xt'..'xv' => 1,
        'z'..'z' => 1, 'xz'..'xz' => 1
      }
    }.freeze
    schema do
      required(:size).filled(:string, included_in?: %w[001m 100k 200k 500k])
      required(:row).filled(:string)
      optional(:column).filled(:string)
      optional(:joined_column).array(:string)
      optional(:kvadrat).filled(:string)
      optional(:joined_kvadrat).array(:string)
      optional(:special).hash do
        optional(:year).filled(:string)
      end
      optional(:tail).array(:string)
    end

    rule(:row) do
      key.failure('is invalid row') unless value =~ /x?[a-vz]/
    end

    rule(:column) do
      if key?
        unless values[:joined_column].nil? || values[:joined_column].empty?
          key.failure('should be skipped if joined_column defined')
        end

        unless select_column_count(values[:size], values[:row]) == 1
          key.failure("no columns for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:joined_column) do
      if key?
        key.failure('should be skipped if column defined') unless values[:column].nil? || values[:column].empty?

        unless select_column_count(values[:size], values[:row]) == value.size
          key.failure("unexpected columns count for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:kvadrat) do
      if key?
        unless values[:joined_kvadrat].nil? || values[:joined_kvadrat].empty?
          key.failure('should be skipped if joined_kvadrat defined')
        end

        unless select_kvadrat_count(values[:size], values[:row]) == 1
          key.failure("no kvadrat for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:joined_kvadrat) do
      if key?
        unless values[:kvadrat].nil? || values[:kvadrat].empty?
          key.failure("should be skipped(#{value.inspect}) if kvadrat defined")
        end

        unless select_kvadrat_count(values[:size], values[:row]) == value.size
          key.failure("unexpected kvadrats count for #{values[:size]}:#{values[:row]}")
        end
      end
    end

    rule(:tail) do
      key.failure("unexpected tail in parsing: #{value.inspect}") if key?
    end

    def select_column_count(size, row)
      JOINS_COLUMN.fetch(size, []).select { |k, _| k.include?(row) }.values.first
    end

    def select_kvadrat_count(size, row)
      JOINS_KVADRAT.fetch(size, []).select { |k, _| k.include?(row) }.values.first
    end
  end
end
