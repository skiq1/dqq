class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :user, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.string :ancestry

      t.timestamps
    end

    add_index :folders, :ancestry

    add_index :folders,
              [:ancestry, :slug],
              unique: true,
              where: "ancestry IS NOT NULL"

    add_index :folders,
              :slug,
              unique: true,
              where: "ancestry IS NULL"

    add_index :folders, [:ancestry, :position]
  end
end
