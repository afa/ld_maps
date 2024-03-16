module SatMaps
  class SavePageWithState < BaseInteractor
    param :page
    param :state

    def call(&blk)
      Try do
        page.public_send(state)
        blk.call(page) if block_given?
        page.save_changes
      end
        .to_result
    end
  end
end
