require 'mechanize'
def ld_it(link, fname = nil)
  att = 0
  begin
    # p link
    m = link.click
  rescue => e
    att += 1
    if att < 10
      puts "retry ##{att}"
      sleep(10)
      retry
    else
      Rails.logger.info "=== Failed attempt to load #{link.uri.to_s} -- #{e.to_s}"
      puts "=== Failed attempt to load #{link.uri.to_s} -- #{e.to_s}"
    end
  end
  unless m.response['content-type'] == 'text/html'
  # puts m.filename
  # p m.response['content-type'] #!!!
  # p m.response['filename']
  # p m.response
  # p m.response.headers
  # p m.header
  # exit
  # if m.is_a?(Mechanize::File) && %w(.map .png .jpg .gif .tif .tiff .jpeg).include?(File.extname(m.filename.downcase))
    if m.is_a?(Mechanize::File)
      puts fname || m.filename
      m.save(fname || m.filename)
    end
  end
end

def do_retry(*params, &blk)
  att = 0
  if blk
    begin
    val = blk.call(*params)
    rescue => e
      att += 1
      if att < 10
        puts "retry ##{att}"
        sleep 10
        retry
      else
      Rails.logger.info "=== Failed attempt -- #{e.to_s}"
      puts "=== Failed attempt -- #{e.to_s}"
      raise
      end
    end
    return val
  end
end

def ld_map_ggc(sz, ldd)
  agent = Mechanize.new
  initpage = agent.get("http://satmaps.info/map#{sz}.php")
  initpage.links_with(href: /map#{sz}w\.php/).each do |lnk1|
    # p lnk1
    page1 = do_retry{ lnk1.click }
    page1.links_with(href: /map#{sz}ww\.php/).each do |lnk2|
      # p lnk2
      page2 = do_retry{ lnk2.click }
      page2.links_with(href: /map#{sz}www\.php/).each do |lnk3|
        # p lnk3
        page3 = do_retry{ lnk3.click }
        page3.links_with(href: /show-map-#{sz}\.php/).each do |lnkmap|
          next if ldd.size > 0 && lnkmap.uri.to_s.split('?').last =~ /id_map=(#{ ldd.join('|') }).*/
          puts lnkmap.uri.to_s.split('?').last
          map = do_retry{ lnkmap.click }
          map.links_with(href: /download-map\.php/).each do |m_lnk|
            ld_it(m_lnk)
          end
          map.links_with(href: /download-ref\.php/).each do |r_lnk|
            ld_it(r_lnk)
          end
        end
      end
    end
  end
end

def ld_map_gen(ldd)
  agent = Mechanize.new
  initpage = agent.get("http://satmaps.info/genshtab.php")
  initpage.links_with(href: /^genshtab.php\?l=[a-z]{1,2}$/).each do |lnk1|
    # p 'lnk1', lnk1.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
    page1 = do_retry{ lnk1.click }
    page1.links_with(href: /^genshtab.php\?sq=[0-9a-z]{2,4}/).each do |lnk2|
    # p 'lnk2', lnk2.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
      next if ldd.size > 0 && lnk2.uri.to_s.split('?').last =~ /^sq=(#{ldd.join('|')})/
      page2 = do_retry{ lnk2.click }
      page2.links_with(href: /^genshtab.php\?lst=[a-z0-9_]{4,}/).each do |lnk3|
    # p 'lnk3', lnk3.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
        puts lnk3.uri.to_s.split('?').last
        page3 = do_retry{ lnk3.click }
        page3.links_with(href: /^http:\/\/satmaps\.info\/map\.php\?s=/).each do |lnk4|
          page4 = do_retry{lnk4.click}
          page4.links_with(href: /^download-map.php/).each do |m_lnk|
            hsh = m_lnk.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
            ld_it(m_lnk, "#{hsh['s']}-#{hsh['map']}.gif")
          end
          page4.links_with(href: /^download-ref.php/).each do |r_lnk|
            hsh = r_lnk.uri.query.split('&').map{|s| s.split('=') }.inject({}){|r, i| r.merge Hash[*i] }
            ld_it(r_lnk, "#{hsh['s']}-#{hsh['map']}.map")
          end

        end
      end
    end
  end
end

namespace :satmap do
  desc "load maps 1:25000"
  task map250: :environment do
    ld_map_ggc(250, %w(K- L-37- L-38-0 L-53-00 L-53-01 L-53-02 L-53-03 L-53-04 L-53-05))
  end

  desc "... 1:50000"
  task map500: :environment do
    ld_map_ggc(500, %w(K- L- M- N- O-0 O-1 O-2 O-3 O-4 O-50 O-51 O-52 O-53 O-54 O-55 O-56 O-57 O-58))
  end

  desc 'load genshtab maps 50k'
  task genshtab: :environment do
    ld_map_gen(%w(a b c d e f g h i j k l m n o p))
  end
  # namespace :genshtab do
  #   desc 'load genshtab maps 50k'
  #   task map050k: :environment do
  #     ld_map_gen(50, [])
  #   end
  # end
end
