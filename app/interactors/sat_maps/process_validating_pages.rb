module SatMaps
  class ProcessValidatingPages < BaseInteractor
    option :session, default: -> { Mechanize.new }

    def call
      load_validating_pages.bind { |pages| validate_names_for(pages) }
    end

    def load_validating_pages
      SatMaps::LoadPages.call(&:state_validating)
    end

    def validate_names_for(pages)
      # return on first fail
      pages.bind do |page|
        Try {
        yield validate_invalid_name(page).or { back_to_reload(page) }
        yield validate_file_size(page).or { back_to_reload(page) }
        yield validate_names(page).bind { forward(page) }.or { to_invalid_names(page) }
        }
        [
          Success(page)
          # SatMaps::FetchUrl.call(page.url, session:).bind do |resp|
          #   names = yield extract_names(resp)
          #   yield store_temporary(names[:filename], resp)
          #   Success(
          #     SatMaps::SavePageWithState.call(page, :state_validating!) do |p|
          #       p.set_fields(names, %i[filename query_filename request_filename])
          #     end
          #   )
          # end.or { print 'F'; nil }
        ]
      end
        .typed(Try)
        .traverse
    end

    def validate_invalid_name(page)
      Try {
        return Failure(:file_too_many_response) if page.request_filename == 'too-many.gif'

        print '.'
        Success()
      }.to_result
    end

    def validate_file_size(page)
      Try {
        file = File.join(App.config[:temporary_path], page.filename)
        return Failure(:no_such_file, file) unless File.exists?(file)

        return Failure(:zero_file_size) if File.new(file).stat.size.zero?

        print '.'
        Success()
      }.to_result
    end

    def back_to_reload(page)
      Try {
        print 'F'
        FileUtils.rm_f([File.join(App.config[:temporary_path], page.filename)])
        SatMaps::SavePageWithState.call(page, :state_waiting!) {  }
      }
        .bind { Failure(:next_page) }
    end

    def validate_names(page)
      # do nothing
      Success()
    end

    def forward(page)
      Success()
    end

    def to_invalid_names(page)
      Success()
    end

    # def store_temporary(filename, mech)
    #   Try {
    #     name = File.join(App.config[:temporary_path], filename)
    #     mech.save(name)
    #   }
    # end

    # def extract_names(mech)
    #   Try {
    #     {
    #       filename: SecureRandom.hex(8),
    #       query_filename: mech.uri.query.split('&').map { |x| x.split('=') }.to_h.then { |h| "#{h['s']}-#{h['map']}.gif" },
    #       request_filename: mech.extract_filename
    #     }
    #   }
    # end

    # def build_name(resp)
    #   Try {
    #     extracted_name = resp.extract_filename
    #     hsh = resp.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    #     pp :exname, extracted_name, :hsh, hsh
    #     yield validate_names(extracted_name, name_from_hash(hsh))
    #     "#{hsh['s']}-#{hsh['map']}.gif"
    #   }
    #   # pp "#{hsh['s']}-#{hsh['map']}.gif"
    #   # pp resp.uri.to_s
    #   # pp resp.body.size, resp.code, resp.each.map{|k, v| "#{k}: #{v}"}
    # end

    # def validate_names(extracted, generated)
    #   pp :extr, extracted
    #   return Failure(:too_many) if extracted == 'too_many.gif'
    #   Success()
    # end

    # def name_from_hash(hash)
    #   "#{hash['s']}-#{hash['map']}.gif"
    # end
  end
end

