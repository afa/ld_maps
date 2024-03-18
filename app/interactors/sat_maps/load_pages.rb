module SatMaps
  class LoadPages < BaseInteractor
    option :count, default: -> { 1000 }

    def call(&blk)
      List(
        Page
        .dataset
        .then { |set| block_given? ? blk.call(set) : set }
        .select(Sequel.lit('*'), Sequel.function(:random).as(:rand))
        .order(:rand)
        .limit(count)
        .to_a
      )
        .fmap { |x| Maybe(x) }
        .typed(Maybe)
        .traverse
        .to_result
    end
  end
end
