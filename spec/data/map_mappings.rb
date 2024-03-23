module MapMappings
  STRUCT_NAME_MAPPING = [
    [{ size: '001m', row: 'a', column: '1' }, '001m-a-1'],
    [{ size: '001m', row: 't', joined_column: %w[1 2 3 4] }, '001m-t-1_2_3_4'],
    [{ size: '001m', row: 'p', joined_column: %w[1 2] }, '001m-p-1_2']
  ].freeze
end
