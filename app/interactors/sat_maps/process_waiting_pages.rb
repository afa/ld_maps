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
      # обдумать как скипать
      pages.bind do |page|
        [
          SatMaps::FetchUrl.call(page.url, session:).bind do |resp|
            names = yield extract_names(resp)
            yield store_temporary(names[:filename], resp)
            Success(
              SatMaps::SavePageWithState.call(page, :state_validating!) do |p|
                p.set_fields(names, %i[filename query_filename request_filename])
              end
            )
          end.or { print 'F'; nil }
        ].compact
      end
        .typed(Try)
        .traverse
    end

    def store_temporary(filename, mech)
      Try {
        name = File.join(App.config[:temporary_path], filename)
        mech.save(name)
      }
    end

    def extract_names(mech)
      Try {
        {
          filename: SecureRandom.hex(8),
          query_filename: mech.uri.query.split('&').map { |x| x.split('=') }.to_h.then { |h| "#{h['s']}-#{h['map']}.gif" },
          request_filename: mech.extract_filename
        }
      }
    end

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
