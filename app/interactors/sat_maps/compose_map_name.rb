module SatMaps
  class ComposeMapName < BaseInteractor
    param :parsed

    # abcdefghijklmno wxyz
    ROWS_60 = %w[p q r s t u v xp xq xr xs xt xu xv].freeze
    ROWS_76 = %w[t u v xt xu xv].freeze
    ROWS_88 = %w[z xz].freeze

    def call
      result << parsed.size << parsed.row << column
      result << kvadrat unless parsed.size == '001m'
      result.join('-')
    end

    private

    def column
      return parsed.column unless ROWS_60.include?(parsed.row)

      return '' if ROWS_88.include?(parsed.row)

      return parsed.joined_column.first(4).join('_') if ROWS_76.include?(parsed.row)

      parsed.joined_column.first(2).join('_')
    end

    def kvadrat
      return parsed.kvadrat unless ROWS_60.include?(parsed.row)

      parsed.joined_kvadrat.join('_')
    end

    def result
      @result ||= []
    end
  end
end
