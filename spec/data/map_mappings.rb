module MapMappings
  STRUCT_NAME_MAPPING = [
    [{ size: '001m', row: 'a', column: '1' }, '001m-a-1'],
    [{ size: '001m', row: 'a', column: '1', special: { year: '1970' } }, '001m-a-1-(1970)'],
    [{ size: '001m', row: 'a', column: '1' }, '001m--a1', '001m-a-1'],
    [{ size: '001m', row: 'a', column: '1' }, '001m-a1', '001m-a-1'],
    [{ size: '001m', row: 't', joined_column: %w[1 2 3 4] }, '001m-t-1_2_3_4'],
    [{ size: '001m', row: 'z' }, '001m-z', '001m-z'],
    [{ size: '001m', row: 'z' }, '001m--z', '001m-z'],
    [{ size: '001m', row: 'p', joined_column: %w[1 2] }, '001m-p-1_2'],

    [{ size: '500k', row: 'a', column: '1', kvadrat: '1' }, '500k-a-1-1'],
    [{ size: '500k', row: 'p', column: '1', joined_kvadrat: %w[1 2] }, '500k-p-1-1_2'],
    [{ size: '500k', row: 'v', column: '1', joined_kvadrat: %w[1 2] }, '500k-v-1-1_2'],
    [{ size: '500k', row: 'z', kvadrat: '1' }, '500k-z-1'],

    [{ size: '200k', row: 'a', column: '1', kvadrat: '1' }, '200k-a-1-1'],
    [{ size: '200k', row: 'p', column: '1', joined_kvadrat: %w[1 2] }, '200k-p-1-1_2'],
    [{ size: '200k', row: 'v', column: '1', joined_kvadrat: %w[1 2 3] }, '200k-v-1-1_2_3'],
    [{ size: '200k', row: 'z', kvadrat: '1' }, '200k-z-1'],

    [{ size: '100k', row: 'a', column: '1', kvadrat: '001' }, '100k-a-1-001'],
    [{ size: '100k', row: 'z', kvadrat: '001' }, '100k-z-001']
  ].freeze
  STRUCT_INVALID_MAPPING = [
    [{ size: '001m', row: 't', joined_column: %w[1 2] }, '001m-t-1_2'],
    [{ size: '001m', row: 'p', joined_column: %w[1 2 3 4] }, '001m-p-1_2_3_4'],
    [{ size: '500k', row: 'v', column: '1', kvadrat: '1' }, '500k-v-1-1'],
    [{ size: '500k', row: 'a', column: '1', joined_kvadrat: %w[1 2] }, '500k-a-1-1_2'],
    [{ size: '200k', row: 'v', column: '1', kvadrat: '1' }, '200k-v-1-1'],
    [{ size: '200k', row: 'v', column: '1', joined_kvadrat: %w[1 2] }, '200k-v-1-1_2'],
    [{ size: '200k', row: 'p', column: '1', joined_kvadrat: %w[1 2 3] }, '200k-p-1-1_2_3'],
    [{ size: '200k', row: 'a', column: '1', joined_kvadrat: %w[1 2] }, '200k-a-1-1_2'],
    [{ size: '100k', row: 'p', column: '1', joined_kvadrat: %w[001 002] }, '100k-p-1-001_002'],
    [{ size: '100k', row: 'v', column: '1', joined_kvadrat: %w[001 002 003] }, '100k-v-1-001_002_003'],
    [{ size: '001m', row: 'z', tail: %w[1_2] }, '001m-z-1_2'],
    [{ size: '001m', row: 'z', tail: ['1'] }, '001m-z-1']
  ].freeze
  STRUCT_BAD_MAPPING = [].freeze
end
