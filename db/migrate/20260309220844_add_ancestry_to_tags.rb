class AddAncestryToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :ancestry, :string
    add_column :tags, :ancestry_depth, :integer, default: 0, null: false

    add_index :tags, :ancestry
    add_index :tags, [ :ancestry, :position ]
  end
end
