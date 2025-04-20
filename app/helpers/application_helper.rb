module ApplicationHelper
  def get_user(id)
    User.find_by(id: id)
  end

  # def github_last_commit
  #   Rails.cache.fetch("github_last_commit", expires_in: 1.hour) do
  #     puts "Fetching GitHub commit data... #{Time.now}"
  #     begin
  #       require "net/http"
  #       require "json"

  #       uri = URI("https://api.github.com/repos/skiq1/teleinf-app/commits/main")
  #       request = Net::HTTP::Get.new(uri)
  #       request["Accept"] = "application/vnd.github.v3+json"
  #       # GitHub token for higher rate limits
  #       if Rails.application.config.github_api_token
  #         request["Authorization"] = "token #{Rails.application.config.github_api_token}"
  #       end

  #       response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  #         http.request(request)
  #       end

  #       if response.code == "200"
  #         data = JSON.parse(response.body)
  #         {
  #           sha: data["sha"],
  #           time: Time.parse(data["commit"]["author"]["date"])
  #         }
  #       else
  #         nil
  #       end
  #     rescue => e
  #       Rails.logger.error "Error fetching GitHub commit: #{e.message}"
  #       nil
  #     end
  #   end
  # end
  def github_last_commit
    {
      sha: Rails.application.config.git_commit_sha,
      time: Time.parse(Rails.application.config.git_commit_time)
    }
  rescue => e
    Rails.logger.error "Error parsing Git commit info: #{e.message}"
    { sha: nil, time: Time.now }
  end
end
