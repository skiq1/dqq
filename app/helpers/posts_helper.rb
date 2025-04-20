module PostsHelper
  def safe_redirect_url(post)
    uri = URI.parse(post.redirect_url)
    uri.scheme.in?(%w[http https]) ? post.redirect_url : "#"
  rescue URI::InvalidURIError
    "#"
  end

  def file_icon_class(file)
    case file.content_type
    when /pdf/
      "fas fa-file-pdf"
    when /zip|rar|tar|gz|7z/
      "fas fa-file-archive"
    when /image/
      "fas fa-file-image"
    when /text|javascript|ruby|python|java|cpp|c\+\+|php|html|css|xml|json/
      "fas fa-file-code"
    when /audio/
      "fas fa-file-audio"
    when /video/
      "fas fa-file-video"
    when /excel|spreadsheet|csv/
      "fas fa-file-excel"
    when /word|doc/
      "fas fa-file-word"
    when /powerpoint|presentation/
      "fas fa-file-powerpoint"
    else
      "fas fa-file"
    end
  end
end
