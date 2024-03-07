Sequel.migration do
  change do
    alter_table(:page) do
      add_column :query_filename, String
      add_column :request_filename, String
      add_column :extension, String
    end
  end
end
