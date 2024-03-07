module SatMaps
  class LoadPages < BaseInteractor
    def call(&blk)
      List(Page.dataset.yield_self { |set| blk.call(set) }.limit(1000).to_a)
        .fmap { |x| Maybe(x) }
        .typed(Maybe)
        .traverse
        .to_result
    end
  end
end