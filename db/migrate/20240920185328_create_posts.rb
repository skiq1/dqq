class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.string :slug
      t.string :title
      t.text :description
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
