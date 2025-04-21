# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
start_date = 2.months.ago.to_date
end_date = Date.today

(start_date..end_date).each do |date|
  num_posts = rand(0..5)
  # Start from the beginning of the day
  current_time = date.beginning_of_day + rand(0..3600) # add up to an hour randomly at start

  num_posts.times do
    # Add a random gap (e.g., 10 to 120 minutes) to keep things in order
    time_gap = rand(10..120).minutes
    current_time += time_gap

    Post.create(
      title: Faker::Lorem.sentence(word_count: 3),
      description: Faker::Lorem.paragraph(sentence_count: 5),
      user_id: 1,
      created_at: current_time,
      updated_at: current_time
    )
  end
end
