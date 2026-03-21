class CreatePostTags < ActiveRecord::Migration[8.1]
  def change
    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.boolean :main, null: false, default: false

      t.timestamps
    end

    add_index :post_tags, [ :post_id, :tag_id ], unique: true
    add_index :post_tags, [ :post_id, :main], unique: true, where: "main = true"
    add_index :post_tags, [ :tag_id, :main ]
  end
end
