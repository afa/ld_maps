require 'spec_helper'
require_relative '../../data/map_mappings'

describe SatMaps::ParseMapName do
  let(:interactor_call) { described_class.call(name) }

  MapMappings::STRUCT_NAME_MAPPING.each do |hash, str, _valid_str|
    context "with #{str}" do
      let(:name) { str }

      it 'not raise' do
        expect { interactor_call }.not_to raise_exception
      end

      it 'return valid struct' do
        expect(interactor_call).to eq(SatMaps::MapNameStruct.new(hash))
      end
    end
  end

  # rubocop:disable Style/HashEachMethods
  MapMappings::STRUCT_INVALID_MAPPING.each do |_hash, str|
    context "with #{str}" do
      let(:name) { str }

      it 'raise' do
        expect { interactor_call }.to raise_exception(SatMaps::ParseMapName::ParsingError)
      end
    end
  end
  # rubocop:enable Style/HashEachMethods

  MapMappings::STRUCT_BAD_MAPPING.each do |hash, str|
    context "with #{str}" do
      let(:name) { str }

      it 'not raise' do
        expect { interactor_call }.not_to raise_exception
      end

      it 'return valid struct' do
        expect(interactor_call).to eq(SatMaps::MapNameStruct.new(hash))
      end
    end
  end
end
