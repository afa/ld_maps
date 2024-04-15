require 'dry-validation'

Dry::Validation.load_extensions(:monads)

class BaseContract < Dry::Validation::Contract; end
