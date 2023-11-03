require 'mechanize'

class Gen < BaseInteractor
  option :path
  option :skip_templates, default: -> { %w[] }

  attr_reader :links, :logger

  def call
    @links = Struct.new(:map, :image).new([], [])
    # @logger = Dry.Logger(:genstab)
    ld_map_gen
    # ld_map_ggc(250, %w[]).to_result
  end

  private

  def ld_map_gen
    # list =  List(
    #   [Try {
    #     agent = Mechanize.new
    #     initpage = agent.get('https://satmaps.info/map.php?s=001m&map=n-37')
    #   }.to_result]
    # )
    
    initpage = load_init("http://satmaps.info/genshtab.php")
    list = collect_links(initpage)
    load_links(list)
  end

  def load_links(list)
    pp :loads, list.value.size
    list.bind { |item| extract_links(item, /download-map.php/) }.bind { |mech| [load_single_gif(mech)] }
    list.bind { |item| extract_links(item, /download-ref.php/) }.bind { |mech| [load_single_map(mech)] }
    # list.bind { |item| extract_links(item, /download-map.php/) }.bind { |mech| pp mech.uri; [mech.uri] }
    # list.bind { |item| extract_links(item, /download-ref.php/) }.bind { |mech| pp mech.uri; [mech.uri] }
  end

  def collect_links(initpage)
    lvl1 = scan_links(List([initpage]), /^genshtab.php\?l=[a-z]{1,2}$/)
    pp lvl1.head, lvl1.value.size
    lvl2 = scan_links(lvl1, /^genshtab.php\?sq=[0-9a-z]{2,4}/)
    pp lvl2.head, lvl2.value.size
    lvl3 = scan_links(lvl2, /^genshtab.php\?lst=[a-z0-9_]{4,}/)
    pp lvl3.head, lvl3.value.size
    lvl4 = scan_links(lvl3, /^http:\/\/satmaps\.info\/map\.php\?s=/)
    pp lvl4.head, lvl4.value.size
    lvl1 + lvl2 + lvl3 + lvl4

    # extract_links(initpage, /^genshtab.php\?l=[a-z]{1,2}$/).fmap do |lnk1|
    #   pp lnk1
    #   # p 'lnk1', lnk1.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    #   page1 = do_retry{ click_try(lnk1) }.tap{|x| pp x}
    #   extract_links(page1, /^genshtab.php\?sq=[0-9a-z]{2,4}/).fmap do |lnk2|
    #     # p 'lnk2', lnk2.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    #     next if skip_templates.size > 0 && lnk2.uri.to_s.split('?').last =~ /^sq=(#{skip_templates.join('|')})/
    #     page2 = do_retry{ click_try(lnk2) }
    #     extract_links(page2, /^genshtab.php\?lst=[a-z0-9_]{4,}/).fmap do |lnk3|
    #       # p 'lnk3', lnk3.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    #       puts lnk3.uri.to_s.split('?').last
    #       page3 = do_retry{ click_try(lnk3) }
    #       pp links.image
    #       extract_links(page3, /^http:\/\/satmaps\.info\/map\.php\?s=/).fmap do |lnk4|
    #         page4 = do_retry{ click_try(lnk4) }
    #         pp page4
    #         extract_links(page4, /^download-map.php/).fmap do |m_lnk|
    #           links.image << m_lnk
    #           pp m_lnk
    #           # load_single_gif(m_lnk)
    #         end
    #         extract_links(page4, /^download-ref.php/).fmap do |r_lnk|
    #           links.map << r_lnk
    #           # load_single_map(r_lnk)
    #         end
    #       end
    #     end
    #   end
    # end

  end

  def scan_links(list, regexp)
    list
      .bind { |item| extract_links(item, regexp) }
      .bind do |lnk1|
        print '.'
        # p 'lnk1', lnk1.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
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
    # List
    mech.bind { |m_page| List(yield Try { m_page.links_with(href: ref) }) }
  end

  def load_init(url)
    Try {
    agent = Mechanize.new
    initpage = agent.get(url)
    }.to_result
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

  # def do_retry(*params, &blk)
  #   Try {
  #     att = 0
  #     if blk
  #       begin
  #         val = blk.call(*params)
  #       rescue => e
  #         att += 1
  #         if att < 10
  #           puts "retry ##{att}"
  #           sleep 10
  #           retry
  #         else
  #           Rails.logger.info "=== Failed attempt -- #{e.to_s}"
  #           puts "=== Failed attempt -- #{e.to_s}"
  #           raise
  #         end
  #       end
  #       return val
  #     end
  #   }
  # end

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
