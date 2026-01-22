class AddExpiresAtToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :expires_at, :datetime, null: true
  end
end
