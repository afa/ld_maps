module SatMaps
  class ProcessWaitingPages < BaseInteractor
    option :session, default: -> { Mechanize.new }

    # выбрать порцию страниц, 
    def call
      load_waiting_pages.bind { |pages| save_files_from(pages) }
    end

    def load_waiting_pages
      SatMaps::LoadPages.call(&:state_waiting)
    end

    def save_files_from(pages)
      pages.bind do |page|
        resp = yield SatMaps::FetchUrl.call(page.url, session:)
        names = yield extract_names(resp)
        yield store_temporary(names[:filename], resp)
        SatMaps::SavePageWithState
          .call(page, :state_validating!) { |p| p.set_fields(names, %i[filename query_filename request_filename]) }

        # yield build_name(resp)
        #   .bind { |name, _calc_name|
        #     yield store_file(resp, name)
        #     [
        #       Success(SatMaps::SavePageWithState.call(page, :state_validating!) { |p| p.filename = name })
        #     ]
        #   }
        #     .or { Success([]) }
      end
        .typed(Try)
        .traverse
    end

    def build_name(resp)
      Try {
        extracted_name = resp.extract_filename
        hsh = resp.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
        pp :exname, extracted_name, :hsh, hsh
        yield validate_names(extracted_name, name_from_hash(hsh))
        "#{hsh['s']}-#{hsh['map']}.gif"
      }
      # pp "#{hsh['s']}-#{hsh['map']}.gif"
      # pp resp.uri.to_s
      # pp resp.body.size, resp.code, resp.each.map{|k, v| "#{k}: #{v}"}
    end

    def validate_names(extracted, generated)
      pp :extr, extracted
      return Failure(:too_many) if extracted == 'too_many.gif'
      Success()
    end

    def store_file(resp, name)
    end

    def name_from_hash(hash)
      "#{hash['s']}-#{hash['map']}.gif"
    end
  end
end
