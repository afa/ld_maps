require 'spec_helper'
require_relative '../../data/map_mappings'

describe SatMaps::ComposeMapName do
  let(:interactor_call) { described_class.call(map_name) }
  let(:map_name) { SatMaps::MapNameStruct.new(name_hash) }

  MapMappings::STRUCT_NAME_MAPPING.each do |hash, str|
    context "with #{str}" do
      let(:name_hash) { hash }

      it 'returns valid name' do
        expect(interactor_call).to eq(str)
      end
    end
  end
end
