module SatMaps
  class FetchUrl < BaseInteractor
    param :url
    option :session, default: -> { Mechanize.new }

    def call
      10.times do |attempt|
        try_get
          .bind do |rsp|
            print '.'
            return Success(rsp)
          end
            .or do |f|
              puts "retry ##{attempt}"
              pp f
              sleep(rand(10))
            end
      end
      Failure("url #{url} load error")
    end

    def try_get
      Try { session.get(url) }.to_result
    end
  end
end
