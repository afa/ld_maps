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
            .or do
              puts "retry ##{attempt}"
              sleep(rand(10))
            end
        # try_get do |m|
        #   m.success do |rsp|
        #     pp m
        #     print '.'
        #     return Success(rsp)
        #   end
        #   m.failure do |er|
        #     pp m
        #     pp er
        #     puts "retry ##{attempt}"

        #     sleep(rand(10))
        #   end
        # end
      end
      Failure("url #{url} load error")
    end

    def try_get
      Try { session.get(url) }.to_result
    end
  end
end
