module SatMaps
  class ProcessValidatingPages < BaseInteractor
    option :session, default: -> { Mechanize.new }

    def call
      load_validating_pages.bind { |pages| validate_names_for(pages) }
    end

    def load_validating_pages
      SatMaps::LoadPages.call(count: 10_000, &:state_validating)
    end

    def validate_names_for(pages)
      # return on first fail
      pages.bind do |page|
        Try {
          yield validate_invalid_name(page).or { back_to_reload(page) }
          yield validate_file_size(page).or { back_to_reload(page) }
          yield validate_names(page).or { to_invalid_names(page) }
        }
          .to_result
          .bind { forward(page) }
        [
          Success(page)
        ]
      end
        .typed(Try)
        .traverse
    end

    def validate_invalid_name(page)
      Try {
        return Failure(:file_too_many_response) if page.request_filename == 'too-many.gif'

        Success()
      }.to_result
    end

    def validate_file_size(page)
      Try {
        return Failure(:no_such_file, file) unless File.exist?(file(page))

        # rubocop:disable Style/ZeroLengthPredicate
        # erro in cop detection for file ststs .size method
        return Failure(:zero_file_size) if File.new(file(page)).stat.size.zero?
        # rubocop:enable Style/ZeroLengthPredicate

        Success()
      }.to_result
    end

    def back_to_reload(page)
      Try {
        print '-'
        FileUtils.rm_f(file(page))
        SatMaps::SavePageWithState.call(page, :state_waiting!)
      }
        .bind { Failure(:next_page) }
    end

    def validate_names(page)
      Try {
        qname =  SatMaps::ParseMapName.call(page.query_filename)
        rname =  SatMaps::ParseMapName.call(page.request_filename)
        compare_names(qname, rname)
      }
        .to_result
    end

    def compare_names(qname, rname)
      return Failure([:has_tail, qname.tail]) unless qname.tail.empty?

      return Failure([:has_tail, rname.tail]) unless rname.tail.empty?

      return Failure(:mismatch) unless qname == rname

      Success(:compared)
    end

    def forward(page)
      print '+'
      Try {
        SatMaps::SavePageWithState.call(page, :state_name_validated!)
      }
        .to_result
    end

    def to_invalid_names(page)
      print 'F'
      Try {
        SatMaps::SavePageWithState.call(page, :state_invalid_name!)
      }
        .to_result
        .bind { Failure(:next_page) }
    end

    def file(page)
      File.join(App.config[:temporary_path], page.filename)
    end
  end
end
