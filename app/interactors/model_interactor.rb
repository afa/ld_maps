# frozen_string_literal: true

require 'dry/monads'

class ModelInteractor < BaseInteractor
  include Dry::Monads[:try, :result, :do]

  class << self
    def model_class(constant)
      define_method(:model_class) { constant }
    end
  end

  private

  # Standard find operation
  def find(id)
    Try { model_class.find(id) }.to_result
  end

  # Standard build operation
  def build
    Success(model_class.new)
  end

  # Standard attributes setting operation
  def set_attributes(model, attrs)
    model.attributes = attrs
    Success(model)
  end

  # Standard model validation operation
  def validate(model)
    model.valid? ? Success(model) : Failure(model.errors)
  end

  # Parameterized save operation
  def save_with_options(model, options = {})
    Try { model.tap { |x| x.save!(**options) } }.to_result
  end

  # Standard save operation
  alias save save_with_options

  # Non-validating aka "clean" save operation
  def clean_save(model)
    save(model, validate: false)
  end

  # Standard model destroy operation
  def destroy(id)
    Try { model_class.destroy(id) }.to_result
  end

  # Standard attributes setting pipeline
  #
  # model * attrs |> set_attributes >>= validate >>= save
  #
  def set_attrs_pipeline(model, attrs)
    yield set_attributes(model, attrs)
    yield validate(model)
    yield clean_save(model) if model.changed?
    Success(model)
  end

  # activerecord-import operation
  def import(objects)
    result = model_class.import(
      objects,
      on_duplicate_key_update: {
        columns: columns_to_update,
        conflict_target:
      }
    )
    return Success(result) if result.failed_instances.blank?

    Failure(result)
  end

  def conflict_target
    []
  end

  def columns_to_update
    model_class.column_names - conflict_target - %w[id created_at updated_at]
  end

  # Checks presence of model entry with given ID
  def check_presence(model, id)
    Try { model.find(id) }.to_result
  end
end
