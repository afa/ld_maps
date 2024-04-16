module SatMaps
  class ProcessNameValidatedPages < BaseInteractor
    option :session, default: -> { Mechanize.new }

    KINDS = {
      'map' => %w[map],
      'img' => %w[gif png]
    }.freeze

    def call
      load_name_validated_pages.bind { |pages| validate_for(pages) }
    end

    def load_name_validated_pages
      SatMaps::LoadPages.call(&:state_name_validated)
    end

    def validate_for(pages)
      pages.bind do |page|
        [
          Try {
            print '.'
            yield setup_extension(page)
            yield setup_final_name(page)
            yield rename_file(page)
          }
            .to_result
            .bind { forward(page) }
            .or { Success() }
        ]
      end
        .typed(Try)
        .traverse
    end

    def setup_extension(page)
      # extract ext from q and r names, chtck for stored in file datatype, detect file type by its context
      extract_extension(page).fmap { |ext| SatMaps::StorePage.call(page, { extension: ext }) }
    end

    def extract_extension(page)
      Maybe(page.files&.fetch('kind')).fmap { |kind|
        rext = File.extname(page.request_filename).split('.').last
        qext = File.extname(page.query_filename).split('.').last
        [rext, qext].compact.select { |n| KINDS[kind].include?(n) }.first
      }
        .to_result
    end

    def setup_final_name(page)
      # make struct from file names, build result file name, store to final
      SatMaps::ParseMapName.call(page.request_filename).bind { |map|
        prefix = File.join(page.files['kind'], map.size, map.row)
        SatMaps::ComposeMapName.call(map).bind { |name|
          SatMaps::StorePage.call(page, { final_filename: name, prefix_path: prefix })
        }
      }
        .or { |_| back(page) }
    end

    def rename_file(page)
      Try {
        FileUtils.mkdir_p(File.join(App.config[:files_base_path], page.prefix_path))
        FileUtils.mv(
          File.join(App.config[:temporary_path], page.filename),
          File.join(App.config[:files_base_path], page.prefix_path, "#{page.final_filename}.#{page.extension}")
        )
      }
        .to_result
    end

    def back(page)
      SatMaps::SavePageWithState.call(page, :state_validating!)
    end

    def forward(page)
      SatMaps::SavePageWithState.call(page, :state_stored!)
    end
  end
end
