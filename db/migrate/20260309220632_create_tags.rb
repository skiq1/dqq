class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :kind, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :tags, :slug, unique: true
  end
end
