require 'spec_helper'
require_relative '../../data/map_mappings'

describe SatMaps::ParseMapName do
  let(:interactor_call) { described_class.call(name) }
  let(:value) { interactor_call.value! }

  MapMappings::STRUCT_NAME_MAPPING.each do |hash, str, _valid_str|
    context "with #{str}" do
      let(:name) { str }

      it 'valid' do
        expect(interactor_call).to be_success
      end

      it 'return expected struct' do
        expect(value).to eq(SatMaps::MapNameStruct.new(hash))
      end
    end
  end

  # rubocop:disable Style/HashEachMethods
  MapMappings::STRUCT_INVALID_MAPPING.each do |_hash, str|
    context "with #{str}" do
      let(:name) { str }

      it 'fails' do
        # expect { interactor_call }.to raise_exception(SatMaps::ParseMapName::ParsingError)
        expect(interactor_call).to be_failure
      end
    end
  end
  # rubocop:enable Style/HashEachMethods

  # MapMappings::STRUCT_BAD_MAPPING.each do |hash, str|
  #   context "with #{str}" do
  #     let(:name) { str }

  #     it 'not raise' do
  #       expect(interactor_call).to be_success
  #     end

  #     it 'return valid struct' do
  #       expect(value).to eq(SatMaps::MapNameStruct.new(hash))
  #       # expect(interactor_call).to eq(SatMaps::MapNameStruct.new(hash))
  #     end
  #   end
  # end
end
