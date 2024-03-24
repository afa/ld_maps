require 'spec_helper'
require_relative '../../data/map_mappings'

describe SatMaps::ParseMapName do
  let(:interactor_call) { described_class.call(name) }

  MapMappings::STRUCT_NAME_MAPPING.each do |hash, str|
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

  MapMappings::STRUCT_INVALID_MAPPING.each do |hash, str|
    context "with #{str}" do
      let(:name) { str }

      it 'raise' do
        expect { interactor_call }.to raise_exception
      end
    end
  end
end
