class AddRedirectUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :redirect_url, :string
  end
end
