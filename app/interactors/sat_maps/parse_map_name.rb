module SatMaps
  class ParseMapName < BaseInteractor
    param :name

    SIZES = %(001m 500k 200k 100k).freeze
    ROWS_60 = %w[p q r s t u v xp xq xr xs xt xu xv].freeze
    ROWS_76 = %w[t u v xt xu xv].freeze
    ROWS_88 = %w[z xz].freeze

    def call
      list = split2
      parse_size(list)
        .or { raise ParsingError.new(message: 'In parse size') }
        .bind { |size| parse_map(size, list.tail) }
        .or { raise ParsingError.new(message: 'In parse map') }
      pp hash
      MapNameStruct.new(hash)

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

    def split2
      List(name.split('.').first.split('-')).bind { |s| s.empty? ? [] : [s] }
    end

    def parse_map(size, list)
      case size
      when '001m'
        parse10(list)
      when '500k'
        parse5(list)
      when '200k'
        parse2(list)
      when '100k'
        parse1(list)
      else
        parse_tail(list)
      end
    end

    def parse10(list)
      row = yield parse_row10(list)
      row_list = parse_col10(row, list)
      row_list.bind { |r| parse_tail(r) }
      row_list.bind { |r| r.typed(Maybe).traverse }
    end

    def parse_row10(list)
      row = Maybe(list.head.bind { |h| h[0, 2].tr('0123456789_', '') })
      hash[:row] = yield row
      row
    end

    def parse_col10(row, list)
      l = list
      if ROWS_88.include?(row)
        rl = []
      else
        c = yield l.head
        e = c.gsub(/[^1234567890_,]/, '')
        if e.empty?
          l = list.tail
          c = yield l.head
          e = c.gsub(/[^1234567890_,]/, '')
        end
        rl = e.split(/[_,]/)
      end
      if ROWS_88.include?(row)
        # hash.merge!(column: nil)
      elsif ROWS_76.include?(row)
        return None() unless rl.size == 4
        hash.merge!(joined_column: rl)
      elsif ROWS_60.include?(row)
        return None() unless rl.size == 2
        hash.merge!(joined_column: rl)
      else
        hash.merge!(column: rl.first)
      end
      l.tail.typed(Maybe).tap{|x|pp x}.traverse
    end

    def parse_tail(list)
      Try {
        hash.merge!(tail: list.value) unless list.value.empty?
      }
        .to_result
    end

    # --------------

    def split
      Maybe(List(name.split('.').first.split('-').map { |s| s.empty? ? nil : s }))
    end

    def parse_size(list)
      list
        .head
        .maybe { |s| SIZES.include?(s) ? s : nil }
        .fmap { |s| hash[:size] = s }
    end

    def extract_size(list)
      list
        .head
        .maybe { |s| SIZES.include?(s) ? s : nil }
        .fmap { |s| hash[:size] = s }
        .or { List([]) }
        .bind { list.tail }
    end

    def extract_row(list)
      list
        .head
        .fmap { |s| hash[:row] = parse_row(s) }
        .or {
          list
            .tail
            .head
            .fmap { |s| parse_row(s) }
        }
        .fmap { |s| hash[:row] = s }
        .or { List([]) }
        .bind { list.tail }
    end

    def extract_column(list)
      list
        .head
        .fmap { |s| hash.merge!(parse_column(s)) }
        .or { List([]) }
        .bind { |_| list.tail }
    end

    def extract_kvadrat(list)
      list
        .head
        .fmap { |s| hash.merge!(parse_kvadrat(s)) }
        .or { List([]) }
        .bind { |_| list.tail }
    end

    def extract_tail(list)
      Maybe(list.value)
        .maybe { |_| hash.merge!(tail: list.value.map { |i| i.nil? ? '' : i }) unless list.value.empty? }
    end

    def parse_row(str)
      str[0, 2].tr('0123456789_', '')
    end

    def parse_column(str)
      lst = str.gsub(/[^1234567890_,]/, '').split(/[_,]/)
      return { column: lst.first } if lst.size == 1

      { joined_column: lst }
    end

    def parse_kvadrat(str)
      lst = str.split(/[_,]/)
      return { kvadrat: lst.first } if lst.size == 1

      { joined_kvadrat: lst }
    end

    def hash
      @hash ||= {}
    end

    class ParsingError < Error; end
  end
end
