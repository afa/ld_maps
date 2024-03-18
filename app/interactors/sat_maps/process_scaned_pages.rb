module SatMaps
  class ProcessScanedPages < BaseInteractor
    option :session, default: -> { Mechanize.new }

    FILE_LINKS_REGEXPS = {
      /download-map.php/ => :img,
      /download-ref.php/ => :map
    }.freeze

    def call
      load_scaned_pages.bind { |pages| scan_files_from(pages) }
    end

    def load_scaned_pages
      SatMaps::LoadPages.call(&:state_scaned)
    end

    def scan_files_from(pages)
      pages.bind do |page|
        list = yield SatMaps::FetchUrl.call(page.url, session:).bind { |mech| parse_file_links(mech) }
        yield build_file_links(page, list)
        [
          SatMaps::SavePageWithState.call(page, :state_checked!, ->(p) { p.files = list })
        ]
      end
        .typed(Try)
        .traverse
    end

    def build_file_links(page, list)
      List(
        list.map { |url, opts| Try { Page.create(parent_id: page.pk, url:, state: :waiting, files: opts) } }
      )
        .typed(Try)
        .traverse
    end

    def parse_file_links(mech)
      Try do
        FILE_LINKS_REGEXPS.each_with_object({}) do |(regexp, kind), data|
          mech.links_with(href: regexp).each do |link|
            data.merge!(link.resolved_uri.to_s => { kind:, text: link.text })
          end
        end
      end
    end
  end
end
