require 'spec_helper'

describe SatMaps::ComposeMapName do
  let(:interactor_call) { described_class.call(map_name)}

  let(:map_name) { SatMaps::MapNameStruct.new(name_hash) }
  let(:name_hash) { { size: '001m', row: '1', column: '1' } }

  it 'returns valid name' do
    expect(interactor_call).to eq('001m-1-1')
  end
end
