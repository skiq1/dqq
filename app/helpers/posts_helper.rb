module PostsHelper
  def safe_redirect_url(post)
    uri = URI.parse(post.redirect_url)
    uri.scheme.in?(%w[http https]) ? post.redirect_url : "#"
  rescue URI::InvalidURIError
    "#"
  end
end
