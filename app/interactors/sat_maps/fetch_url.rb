module SatMaps
  class FetchUrl < BaseInteractor
    param :url
    option :session, default: -> { Mechanize.new }

    def call
      10.times do |attempt|
        try_get
          .bind { |rsp| return point_and_return(Success(rsp)) }
          .or do |f|
            puts "retry ##{attempt}"
            pp f
            sleep(rand(10))
          end
      end
      Failure("url #{url} load error")
    end

    def point_and_return(val)
      print '.'
      val
    end

    def try_get
      Try { session.get(url) }.to_result
    end
  end
end
