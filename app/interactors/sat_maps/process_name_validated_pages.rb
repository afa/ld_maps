module SatMaps
  class ProcessNameValidatedPages < BaseInteractor
    option :session, default: ->() { Mechanize.new }

    def call
      load_name_validated_pages.bind { |pages| validate_for(pages) }
    end

    def load_name_validated_pages
      SatMaps::LoadPages.call(&:state_name_validated)
    end

    def validate_for(pages)
      pages.bind do |page|
        Try {
          yield setup_extension(page)
          yield setup_final_name(page)
          yield rename_file
        }
          .to_result
          .bind { forward(page) }
      end
        .typed(Try)
        .traverse
    end

    def setup_extension(page)
      # extract ext from q and r names, chtck for stored in file datatype, detect file type by its context
      Success()
    end

    def setup_final_name(page)
      # make struct from file names, build result file name, store to final
    end

    def rename_file(page)
    end

    def forward(page)
      # to stored
    end
  end
end
