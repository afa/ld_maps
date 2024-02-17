Sequel.migration do
  up do
    extension :pg_array, :pg_json
    create_table :page do
      primary_key :id
      String :url, null: false
      column :state, :integer, null: false, default: 0
      column :page, :text
      jsonb :links

      # TrueClass :processed_tree
      # TrueClass :taken_links
      # TrueClass :is_file
      # TrueClass :file_saved
      foreign_key :parent_id, :page
    end
  end

  down do
    drop_table :page
  end
end
