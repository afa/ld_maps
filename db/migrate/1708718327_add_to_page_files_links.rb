Sequel.migration do
  up do
    extension :pg_array, :pg_json
    alter_table(:page) do
      add_column :files, :jsonb
      drop_column :page
    end
  end

  down do
    alter_table(:page) do
      add_column :page, :text
      drop_column :files
    end
  end
end
