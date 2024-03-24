Sequel.migration do
  change do
    alter_table(:page) do
      add_column :prefix_path, String
    end
  end
end
