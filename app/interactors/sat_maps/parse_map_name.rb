module SatMaps
  class ParseMapName < BaseInteractor
    param :name

    SIZES = %(001m 500k 200k 100k).freeze
    ROWS_88 = %w[z xz].freeze
    METHODS_FOR_SIZE = {
      '001m' => :parse10,
      '500k' => :parse05,
      '200k' => :parse02,
      '100k' => :parse01
    }.freeze

    def call
      list = split
      row_list = parse_size(list)
                 .or { return Failure(message: 'In parse size') }
                 .bind { |_size| parse_row(list.tail) }
      col_list = take_column(check_column(row_list) ? row_list : row_list.tail)
                 .bind { |item| extract_year(item) ? [] : [item] }
      tail_list = parse_kvadrat(col_list)
      parse_tail(tail_list)
      # pp hash
      SatMaps::ParseMapNameContract
        .new
        .call(hash)
        .to_monad
        .fmap { |c| SatMaps::MapNameStruct.new(c.to_h) }
    end

    private

    def split
      List(name.split('.').first.split('-')).bind { |s| s.empty? ? [] : [s] }
    end

    def parse_size(list)
      list
        .head
        .maybe { |s| SIZES.include?(s) ? s : nil }
        .fmap { |s| hash[:size] = s }
    end

    def parse_row(list)
      row = Maybe(list.head.bind { |h| h[0, 2].tr('0123456789_,', '') })
      hash[:row] = yield row
      list
    end

    def check_column(list)
      c = yield list.head
      !strip_digits(c).empty?
    end

    def strip_digits(str)
      str.gsub(/[^1234567890_,]/, '')
    end

    def take_column(list)
      if with_columns?
        c = yield list.head
        cols = strip_digits(c).split(/[_,]/)
        if cols.size == 1
          hash[:column] = cols.first
        else
          hash[:joined_column] = cols
        end
        list.tail
      else
        list
      end
    end

    def with_columns?
      !ROWS_88.include?(hash[:row])
    end

    def with_kvadrat?
      hash[:size] != '001m'
    end

    def parse_kvadrat(list)
      if with_kvadrat?
        c = yield list.head
        cols = strip_digits(c).split(/[_,]/)
        if cols.size == 1
          hash[:kvadrat] = cols.first
        else
          hash[:joined_kvadrat] = cols
        end
        list.tail
      else
        list
      end
    end

    def extract_year(item)
      /^\(([1234567890]{4})\)$/.match(item) do |m|
        hash[:special] ||= {}
        hash[:special][:year] = m[1]
      end
    end

    def check_col(list)
      c = yield list.head
      c.gsub(/[^1234567890_,]/, '')
    end

    def parse_tail(list)
      Try {
        hash.merge!(tail: list.value.compact) unless list.value.compact.empty?
      }
        .to_result
    end

    def hash
      @hash ||= {}
    end

    class ParsingError < Error; end
  end
end
