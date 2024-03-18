module SatMaps
  class ParseMapName < BaseInteractor
    param :name

    SIZES = %(001m 500k 200k 100k).freeze
    def call
      yield split
        .fmap { |list| extract_size(list) }
        .fmap { |list| extract_row(list) }
        .fmap { |list| extract_column(list) }
        .fmap { |list| extract_kvadrat(list) }
        .fmap { |list| extract_tail(list) }
        .or { |f| pp hash, f }

      MapNameStruct.new(hash)
    end

    def split
      Maybe(List(name.split('.').first.split('-').map { |s| s.empty? ? nil : s }))
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
        .fmap { |_| hash.merge!(tail: list.value.map { |i| i.nil? ? '' : i }) }
    end

    def parse_row(str)
      str[0, 2].tr('0123456789_-', '')
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
  end
end
