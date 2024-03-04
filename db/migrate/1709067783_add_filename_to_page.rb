Sequel.migration do
  up do
    alter_table(:page) do
      add_column :filename, String
    end
  end

  down do
    alter_table(:page) do
      drop_column :filename
    end
  end
end
