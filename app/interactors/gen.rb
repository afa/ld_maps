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
    prev_counts = counts
    yield SatMaps::PrepareStartupPages.call(App.config.fetch(:maps_url))
    puts 'startup'
    yield SatMaps::ProcessInitPages.call(session:)
    puts 'init'
    yield SatMaps::ProcessScanedPages.call(session:)
    puts 'scan'
    yield SatMaps::ProcessWaitingPages.call(session:)
    puts 'wait'
    yield SatMaps::ProcessValidatingPages.call(session:)
    puts 'validating'
    # yield SatMaps::ProcessNameValidatedPages.call(session:)
    # puts 'name validated'

    cur_counts = counts
    (prev_counts.keys + cur_counts.keys)
      .uniq
      .sort
      .each do |key|
        o = prev_counts.fetch(key, [0, nil])
        n = cur_counts.fetch(key, [0, nil])
        st = o[1] || n[1]
        dif = n[0] - o[0]
        puts "#{st}: #{n[0]}, #{dif}"
      end
  end

  def counts
    Page
      .select{[state, count(state)]}
      .group(:state)
      .each_with_object({}) { |p, hsh| hsh[p.values[:state]] = [p.values[:count], p.state]}
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
  #             next if skip_templates.size > 0
  #             && lnkmap.uri.to_s.split('?').last =~ /id_map=(#{ skip_templates.join('|') }).*/
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
