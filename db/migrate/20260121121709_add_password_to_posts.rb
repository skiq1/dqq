class AddPasswordToPosts < ActiveRecord::Migration[8.1]
  def change
      add_column :posts, :password_digest, :string
  end
end
