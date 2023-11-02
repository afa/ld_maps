require 'dry/initializer'
require 'dry/monads'
class BaseInteractor
  extend Dry::Initializer

  class << self
    def inherited(klass)
      klass.include Dry::Monads[:do, :maybe, :result, :try, :list]
      super
    end

    # Instantiates and calls the service at once
    def call(*args, **kwargs, &)
      new(*args, **kwargs).call(&)
    end
  end
end
