require 'spec_helper'

describe SatMaps::ComposeMapName do
  let(:interactor_call) { described_class.call(map_name) }

  let(:map_name) { SatMaps::MapNameStruct.new(name_hash) }

  [
    [{ size: '001m', row: '1', column: '1' }, '001m-1-1']
  ]
    .each do |hash, str|
      context "valid for #{str}" do
        let(:name_hash) { hash }

        it 'returns valid name' do
          expect(interactor_call).to eq(str)
        end
      end
    end
end
