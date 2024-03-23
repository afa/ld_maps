module MapMappings
  STRUCT_NAME_MAPPING = [
    [{ size: '001m', row: 'a', column: '1' }, '001m-a-1'],
    [{ size: '001m', row: 't', joined_column: %w[1 2 3 4] }, '001m-t-1_2_3_4'],
    [{ size: '001m', row: 'z' }, '001m-z'],
    [{ size: '001m', row: 'p', joined_column: %w[1 2] }, '001m-p-1_2'],
    [{ size: '500k', row: 'a', column: '1', kvadrat: '1' }, '500k-a-1-1']
  ].freeze
  STRUCT_INVALID_MAPPING = [
    [{ size: '001m', row: 't', joined_column: %w[1 2] }, '001m-t-1_2'],
    [{ size: '001m', row: 'z', joined_column: %w[1 2] }, '001m-z-1_2'],
    [{ size: '001m', row: 'z', column: '1' }, '001m-z-1'],
    [{ size: '001m', row: 'p', joined_column: %w[1 2 3 4] }, '001m-p-1_2_3_4']
  ].freeze
end
