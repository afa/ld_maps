module SatMaps
  class ComposeMapName < BaseInteractor
    param :parsed

    def call
      Try {
        result << parsed.size << parsed.row << column
        result << kvadrat
        result << special
        result.compact.join('-')
      }
        .to_result
    end

    private

    def column
      parsed.column || parsed.joined_column&.join('_')
    end

    def kvadrat
      parsed.kvadrat || parsed.joined_kvadrat&.join('_')
    end

    def special
      "(#{parsed.special.year})" if parsed.special&.year
    end

    def result
      @result ||= []
    end
  end
end
