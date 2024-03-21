module SatMaps
  class StorePage < BaseInteractor
    param :page
    param :data

    def call
      Try {
        page.set(data)
        page.save_changes
      }
        .to_result
    end
  end
end
