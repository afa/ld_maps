require 'mechanize'

# найти или создать страницу с урлем из path (статус инит)
# найти сто пкервых страниц со статусом инит, скачать страницы, сканировать ссылки и для всех ссылок создать страницы,
# для отсканированной страницы установить статус сканед
# найти страницы сканед, проверить наличие ссылок на файлы, создать для файлов страницы, установть статус в чекед
# найти чекед, проверить наличие файла если нет статус в доне, если удалось сохранить в савед
class Gen < BaseInteractor
  option :path
  option :skip_templates, default: -> { %w[] }
  option :session, default: -> { Mechanize.new }

  attr_reader :logger

  def call
    session.verify_mode = 0 # fix after certification repaired

    # @links = Struct.new(:map, :image).new([], [])
    # @logger = Dry.Logger(:genstab)
    ld_map_gen
  end

  private

  def ld_map_gen
    # yield SatMaps::PrepareStartupPages.call(App.config.fetch(:maps_url))
    # puts 'startup'
    # yield SatMaps::ProcessInitPages.call(session:)
    # puts 'init'
    # yield SatMaps::ProcessScanedPages.call(session:)
    puts 'scan'
    yield SatMaps::ProcessWaitingPages.call(session:)
    puts 'wait'

    pp Page.dataset.state_init.count,
       Page.dataset.state_scaned.count,
       Page.dataset.state_checked.count,
       Page.dataset.state_saved.count,
       Page.dataset.state_waiting.count,
       Page.dataset.state_validating.count
  end

  def load_checked_pages
    SatMaps::LoadPages.call(&:state_checked)
  end


  # -----------------
  # def load_links(list)
  #   list.bind { |item| extract_links(item, /download-map.php/) }.bind { |mech| [load_single_gif(mech)] }
  #   list.bind { |item| extract_links(item, /download-ref.php/) }.bind { |mech| [load_single_map(mech)] }
  # end

  def load_single_gif(m_lnk)
    hsh = m_lnk.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    ld_it(m_lnk, "#{hsh['s']}-#{hsh['map']}.gif")
  end

  def load_single_map(r_lnk)
    hsh = r_lnk.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    ld_it(r_lnk, "#{hsh['s']}-#{hsh['map']}.map")
  end

  def ld_it(link, fname = nil)
    resp = yield fetch_link(link)
    resp_save(resp, fname)
  end

  def resp_save(resp, fname)
    Try {
      unless resp.response['content-type'] == 'text/html'
        if resp.is_a?(Mechanize::File)
          name = yield Maybe(fname).or(resp.filename)
          puts name
          resp.save(name)
        end
      end
    }.to_result
  end

  # def ld_map_ggc(sz)
  #   Try {

  #     initpage = yield load_init("http://satmaps.info/map#{sz}.php")
  #     pp initpage
  #     initpage.links_with(href: /map#{sz}w\.php/).tap{|x|pp x}.each do |lnk1|
  #       pp :l1, lnk1
  #       page1 = yield do_retry{ lnk1.click }
  #       page1.links_with(href: /map#{sz}ww\.php/).each do |lnk2|
  #         # p lnk2
  #         page2 = yield do_retry{ lnk2.click }
  #         page2.links_with(href: /map#{sz}www\.php/).each do |lnk3|
  #           # p lnk3
  #           page3 = yield do_retry{ lnk3.click }
  #           page3.links_with(href: /show-map-#{sz}\.php/).each do |lnkmap|
  #             next if skip_templates.size > 0 && lnkmap.uri.to_s.split('?').last =~ /id_map=(#{ skip_templates.join('|') }).*/
  #             puts lnkmap.uri.to_s.split('?').last
  #             map = yield do_retry{ lnkmap.click }
  #             map.links_with(href: /download-map\.php/).each do |m_lnk|
  #               yield ld_it(m_lnk)
  #             end
  #             map.links_with(href: /download-ref\.php/).each do |r_lnk|
  #               yield ld_it(r_lnk)
  #             end
  #           end
  #         end
  #       end
  #     end
  #   }
  # end
end
