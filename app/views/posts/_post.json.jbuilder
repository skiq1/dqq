json.extract! post, :id, :slug, :title, :description, :status, :created_at, :updated_at
json.url post_url(post, format: :json)
