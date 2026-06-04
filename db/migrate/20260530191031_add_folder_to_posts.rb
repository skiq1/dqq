class AddFolderToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :folder, null: true, foreign_key: true
    add_index :posts, [:folder_id, :created_at]
    add_index :posts, [:user_id, :folder_id, :created_at]
  end
end
