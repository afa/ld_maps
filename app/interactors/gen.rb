require 'mechanize'

# найти или создать страницу с урлем из path (статус инит)
# найти сто пкервых страниц со статусом инит, скачать страницы, сканировать ссылки и для всех ссылок создать страницы,
# для отсканированной страницы установить статус сканед
# найти страницы сканед, проверить наличие ссылок на файлы, создать для файлов страницы, установть статус в чекед
# найти чекед, проверить наличие файла если нет статус в доне, если удалось сохранить в савед
class Gen < BaseInteractor
  option :path
  option :skip_templates, default: -> { %w[] }

  attr_reader :session, :links, :logger

  LINKS_REGEXPS = {
    /^genshtab.php\?l=[a-z]{1,2}$/ => { lvl: 1 },
    /^genshtab.php\?sq=[0-9a-z]{2,4}/ => { lvl: 2 },
    /^genshtab.php\?lst=[a-z0-9_]{4,}/ => { lvl: 3 },
    /^http:\/\/satmaps\.info\/map\.php\?s=/ => { lvl: 4 }
  }.freeze

  def call
    @links = Struct.new(:map, :image).new([], [])
    # @logger = Dry.Logger(:genstab)
    ld_map_gen
    # ld_map_ggc(250, %w[]).to_result
  end

  private

  def ld_map_gen
    yield startup(App.config.fetch(:maps_url))
    pages = yield load_init_pages
    @session = yield init_mechanize
    yield scan_links_from(pages)
    raise
    initpage = load_init
    list = collect_links(initpage)
    load_links(list)
    pp Page.dataset.state_init.count,
       Page.dataset.state_scanned.count,
       Page.dataset.state_checked.count,
       Page.dataset.state_saved.count
  end

  def startup(url)
    Maybe(Page.where(url:).first)
      .or { Page.create(url:, state: :init) }
  end

  def init_mechanize
    Try {
      Mechanize.new
    }.to_result
  end

  def load_init_pages
    List(Page.dataset.state_init.limit(100).to_a)
      .fmap { |x| Maybe(x) }
      .typed(Maybe)
      .traverse
      .to_result
  end

  def scan_links_from(pages)
      pages.bind do |page|
        mech = session.get(page.url)
        list = yield parse_page_links(mech)
        pp list
        yield build_page_links(list)
        page.links = list.value
        page.state_scanned!
        page.save_changes
        [page]
      end
  end

  def parse_page_links(mech)
    Try {
      LINKS_REGEXPS.each_with_object({}) do |(regexp, opts), data|
        mech.links_with(href: regexp).each do |link|
          data.merge!(link.resolved_uri => { lvl: opts[:lvl], text: link.text })
        end
      end
    }
  end

  # -----------------
  # def load_init
  #   Try {
  #   agent = Mechanize.new
  #   initpage = agent.get(url)
  #   }.to_result
  # end

  def load_links(list)
    pp :loads, list.value.size
    list.bind { |item| extract_links(item, /download-map.php/) }.bind { |mech| [load_single_gif(mech)] }
    list.bind { |item| extract_links(item, /download-ref.php/) }.bind { |mech| [load_single_map(mech)] }
  end

  # def collect_links(initpage)
  #   lvl1 = scan_links(List([initpage]), /^genshtab.php\?l=[a-z]{1,2}$/)
  #   pp lvl1.head, lvl1.value.size
  #   lvl2 = scan_links(lvl1, /^genshtab.php\?sq=[0-9a-z]{2,4}/)
  #   pp lvl2.head, lvl2.value.size
  #   lvl3 = scan_links(lvl2, /^genshtab.php\?lst=[a-z0-9_]{4,}/)
  #   pp lvl3.head, lvl3.value.size
  #   lvl4 = scan_links(lvl3, /^http:\/\/satmaps\.info\/map\.php\?s=/)
  #   pp lvl4.head, lvl4.value.size
  #   lvl1 + lvl2 + lvl3 + lvl4
  # end

  def scan_links(list, regexp)
    list
      .bind { |item| extract_links(item, regexp) }
      .bind do |lnk1|
        print '.'
        [fetch_link(lnk1)]
      end
  end

  def load_single_gif(m_lnk)
    hsh = m_lnk.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    ld_it(m_lnk, "#{hsh['s']}-#{hsh['map']}.gif")
  end

  def load_single_map(r_lnk)
    hsh = r_lnk.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    ld_it(r_lnk, "#{hsh['s']}-#{hsh['map']}.map")
  end

  def extract_links(mech, ref)
    mech.bind { |m_page| List(yield Try { m_page.links_with(href: ref) }) }
  end

  def ld_it(link, fname = nil)
    resp = yield fetch_link(link)
    resp_save(resp, fname)
  end

  def fetch_link(link)
    10.times do |attempt|
      click_try(link)
        .bind { |rsp| return Success(rsp) }
        .or { puts "retry ##{attempt}"; sleep(rand(10)) }
    end
  end

  def click_try(link, fname = nil)
    Try { link.click }.to_result
  end

  def resp_save(resp, fname)
    Try {
      unless resp.response['content-type'] == 'text/html'
        # puts resp.filename
        # p resp.response['content-type'] #!!!
        # p resp.response['filename']
        # p resp.response
        # p resp.response.headers
        # p resp.header
        # exit
        # if resp.is_a?(Mechanize::File) && %w(.map .png .jpg .gif .tif .tiff .jpeg).include?(File.extname(resp.filename.downcase))
        if resp.is_a?(Mechanize::File)
          name = yield Maybe(fname).or(resp.filename)
          puts name
          resp.save(name)
        end
      end
    }.to_result
  end

  def ld_map_ggc(sz)
    Try {
      
      initpage = yield load_init("http://satmaps.info/map#{sz}.php")
      pp initpage
      initpage.links_with(href: /map#{sz}w\.php/).tap{|x|pp x}.each do |lnk1|
        pp :l1, lnk1
        page1 = yield do_retry{ lnk1.click }
        page1.links_with(href: /map#{sz}ww\.php/).each do |lnk2|
          # p lnk2
          page2 = yield do_retry{ lnk2.click }
          page2.links_with(href: /map#{sz}www\.php/).each do |lnk3|
            # p lnk3
            page3 = yield do_retry{ lnk3.click }
            page3.links_with(href: /show-map-#{sz}\.php/).each do |lnkmap|
              next if skip_templates.size > 0 && lnkmap.uri.to_s.split('?').last =~ /id_map=(#{ skip_templates.join('|') }).*/
              puts lnkmap.uri.to_s.split('?').last
              map = yield do_retry{ lnkmap.click }
              map.links_with(href: /download-map\.php/).each do |m_lnk|
                yield ld_it(m_lnk)
              end
              map.links_with(href: /download-ref\.php/).each do |r_lnk|
                yield ld_it(r_lnk)
              end
            end
          end
        end
      end
    }
  end
end
