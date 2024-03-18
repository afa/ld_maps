Sequel.migration do
  change do
    alter_table(:page) do
      add_column :final_filename, String
    end
  end
end
