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
        .or { raise ParsingError.new(message: 'In parse size') }
        .bind { |size| parse_row(list.tail) }
      col_list = take_column(check_column(row_list) ? row_list : row_list.tail)
        .bind { |item| extract_year(item) ? [] : [item] }
      tail_list = parse_kvadrat(col_list)
      parse_tail(tail_list)
      pp hash
      SatMaps::ParseMapNameContract
        .new
        .call(hash)
        .to_monad
        .fmap { |c| SatMaps::MapNameStruct.new(c.to_h) }

      # yield split
      #   .fmap { |list| extract_size(list) }
      #   .fmap { |list| extract_row(list) }
      #   .fmap { |list| extract_column(list) }
      #   .fmap { |list| extract_kvadrat(list) }
      #   .fmap { |list| extract_tail(list) }
      #   .or { |f| pp hash, f }

      # MapNameStruct.new(hash)
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

    def strip_digits(c)
      c.gsub(/[^1234567890_,]/, '')
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
      end.tap{|x|pp x}
    end

    def parse_map(size, list)
      METHODS_FOR_SIZE.fetch(size, :parse_tail).to_proc.call(self, list)
    end

    def parse10(list)
      row = yield parse_row(list)
      row_list = parse_col10(row, list)
      row_list.bind { |r| parse_tail(r) }
      row_list.bind { |r| r.fmap { |item| Maybe(item) }.typed(Maybe).traverse }
    end

    def parse_col10(row, list)
      parse_col(row, list) do |rr, rl|
        if ROWS_76.include?(rr)
          return None() unless rl.size == 4

          hash.merge!(joined_column: rl)
        elsif ROWS_60.include?(rr)
          return None() unless rl.size == 2

          hash.merge!(joined_column: rl)
        else
          hash.merge!(column: rl.first)
        end
      end
    end

    def parse_col(row, list)
      e = check_col(list)
      if ROWS_88.include?(row)
        return list.fmap { |item| Maybe(item) }.typed(Maybe).traverse unless e.empty?

        return list.tail.fmap { |item| Maybe(item) }.typed(Maybe).traverse
      end

      l = e.empty? ? list.tail : list
      e = check_col(list.tail) if e.empty?

      rl = e.split(/[_,]/)
      yield(row, rl)
      l.tail.fmap { |i| Maybe(i) }.typed(Maybe).traverse
    end

    def check_col(list)
      c = yield list.head
      c.gsub(/[^1234567890_,]/, '')
    end

    def parse05(list)
      row = yield parse_row(list)
      row_list = parse_col05(row, list).bind { |lst|
        parse_kvadrat05(row, lst)
      }
      row_list.bind { |r| parse_tail(r) }
      row_list.bind { |r| r.fmap { |item| Maybe(item) }.typed(Maybe).traverse }
    end

    def parse_col05(row, list)
      parse_col(row, list) do |_rr, rl|
        return None() unless rl.size == 1

        hash.merge!(column: rl.first)
      end
    end

    def parse_kvadrat05(row, list)
      str = yield list.head
      kv = str.split(/[_,]/)
      if ROWS_60.include?(row)
        return None() unless kv.size == 2

        hash[:joined_kvadrat] = kv
      else
        return None() unless kv.size == 1

        hash[:kvadrat] = kv.first
      end
      list.tail.fmap { |i| Maybe(i) }.typed(Maybe).traverse
    end

    def parse02(list)
      row = yield parse_row(list)
      row_list = parse_col02(row, list).bind { |lst|
        parse_kvadrat02(row, lst)
      }
      row_list.bind { |r| parse_tail(r) }
      row_list.bind { |r| r.fmap { |item| Maybe(item) }.typed(Maybe).traverse }
    end

    def parse_col02(row, list)
      parse_col(row, list) do |_rr, rl|
        return None() unless rl.size == 1

        hash.merge!(column: rl.first)
      end
    end

    def parse_kvadrat02(row, list)
      str = yield list.head
      kv = str.split(/[_,]/)
      if ROWS_76.include?(row)
        return None() unless kv.size == 3

        hash[:joined_kvadrat] = kv
      elsif ROWS_60.include?(row)
        return None() unless kv.size == 2

        hash[:joined_kvadrat] = kv
      else
        return None() unless kv.size == 1

        hash[:kvadrat] = kv.first
      end
      list.tail.fmap { |i| Maybe(i) }.typed(Maybe).traverse
    end

    def parse_tail(list)
      Try {
        hash.merge!(tail: list.value.compact) unless list.value.compact.empty?
      }
        .to_result
    end

    # --------------

    # def split
    #   Maybe(List(name.split('.').first.split('-').map { |s| s.empty? ? nil : s }))
    # end

    # def extract_size(list)
    #   list
    #     .head
    #     .maybe { |s| SIZES.include?(s) ? s : nil }
    #     .fmap { |s| hash[:size] = s }
    #     .or { List([]) }
    #     .bind { list.tail }
    # end

    # def extract_row(list)
    #   list
    #     .head
    #     .fmap { |s| hash[:row] = parse_row(s) }
    #     .or {
    #       list
    #         .tail
    #         .head
    #         .fmap { |s| parse_row(s) }
    #     }
    #     .fmap { |s| hash[:row] = s }
    #     .or { List([]) }
    #     .bind { list.tail }
    # end

    # def extract_column(list)
    #   list
    #     .head
    #     .fmap { |s| hash.merge!(parse_column(s)) }
    #     .or { List([]) }
    #     .bind { |_| list.tail }
    # end

    # def extract_kvadrat(list)
    #   list
    #     .head
    #     .fmap { |s| hash.merge!(parse_kvadrat(s)) }
    #     .or { List([]) }
    #     .bind { |_| list.tail }
    # end

    # def extract_tail(list)
    #   Maybe(list.value)
    #     .maybe { |_| hash.merge!(tail: list.value.map { |i| i.nil? ? '' : i }) unless list.value.empty? }
    # end

    # def parse_row(str)
    #   str[0, 2].tr('0123456789_', '')
    # end

    # def parse_column(str)
    #   lst = str.gsub(/[^1234567890_,]/, '').split(/[_,]/)
    #   return { column: lst.first } if lst.size == 1

    #   { joined_column: lst }
    # end

    # def parse_kvadrat(str)
    #   lst = str.split(/[_,]/)
    #   return { kvadrat: lst.first } if lst.size == 1

    #   { joined_kvadrat: lst }
    # end

    def hash
      @hash ||= {}
    end

    class ParsingError < Error; end
  end
end
