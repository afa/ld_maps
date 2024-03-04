module SatMaps
  class PrepareStartupPages < BaseInteractor
    param :url

    def call
      Maybe(Page.where(url:).first)
        .or { Maybe(Page.create(url:, state: :init)) }
    end
  end
end
