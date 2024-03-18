module SatMaps
  class ProcessInitPages < BaseInteractor
    option :session, default: -> { Mechanize.new }

    LINKS_REGEXPS = {
      /^genshtab.php\?l=[a-z]{1,2}$/ => { lvl: 1 },
      /^genshtab.php\?sq=[0-9a-z]{2,4}/ => { lvl: 2 },
      /^genshtab.php\?lst=[a-z0-9_]{4,}/ => { lvl: 3 },
      %r{^http://satmaps\.info/map\.php\?s=} => { lvl: 4 } # %r for regexps
    }.freeze

    def call
      load_init_pages.bind { |pages| scan_links_from(pages) }
    end

    def load_init_pages
      SatMaps::LoadPages.call(&:state_init)
    end

    def scan_links_from(pages)
      pages.bind do |page|
        list = yield SatMaps::FetchUrl.call(page.url, session:).bind { |mech| parse_page_links(mech) }
        yield build_page_links(page, list)
        [
          SatMaps::SavePageWithState.call(page, :state_scaned!, ->(p) { p.links = list })
        ]
      end
        .typed(Try)
        .traverse
    end

    def parse_page_links(mech)
      Try do
        LINKS_REGEXPS.each_with_object({}) do |(regexp, opts), data|
          mech.links_with(href: regexp).each do |link|
            data.merge!(link.resolved_uri.to_s => { lvl: opts[:lvl], text: link.text })
          end
        end
      end
    end

    def build_page_links(page, list)
      List(
        list.map { |url, _opts| Try { Page.create(parent_id: page.pk, url:) } }
      ).typed(Try).traverse
    end
  end
end
