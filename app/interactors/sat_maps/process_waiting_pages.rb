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
              SatMaps::SavePageWithState.call(
                page,
                :state_validating!,
                ->(p) { p.set_fields(names, %i[filename query_filename request_filename]) }
              )
            )
          end
            .or { print_fail }
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
          query_filename: parse_query(mech.uri.query),
          request_filename: mech.extract_filename
        }
      }
    end

    def parse_query(str)
      str.split('&').to_h { |x| x.split('=') }.then { |h| "#{h['s']}-#{h['map']}.gif" }
    end

    def print_fail
      print 'F'
      nil
    end
  end
end
