module SatMaps
  class ComposeMapName < BaseInteractor
    param :parsed
    # abcdefghijklmno wxyz
    ROWS_60 = %w[p q r s t u v xp xq xr xs xt xu xv]
    ROWS_76 = %w[t u v xt xu xv]
    ROWS_88 = %w[z xz]
    def call
      result << parsed.size << parsed.row << column
      result << kvadrat unless parsed.size == '001m'
      result.join('-')
    end

    def column
      return parsed.joined_column.join('_') if ROWS_60.include?(parsed.row)

      parsed.column
    end

    def kvadrat
      return parsed.joined_kvadrat.join('_') if ROWS_60.include?(parsed.row)

      parsed.kvadrat
    end

    def result
      @result ||= []
    end
  end
end
