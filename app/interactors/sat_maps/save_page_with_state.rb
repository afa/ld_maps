module SatMaps
  class SavePageWithState < BaseInteractor
    param :page
    param :state
    param :lmbd, default: -> { ->(og) {} }

    def call
      Try {
        page.public_send(state)
        lmbd.call(page)
        page.save_changes
      }
        .to_result
    end
  end
end
