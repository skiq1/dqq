# db/seeds.rb

require "faker"

puts "Cleaning database..."

ActiveRecord::Base.connection.disable_referential_integrity do
  ActiveRecord::Base.transaction do
    ActiveStorage::Attachment.delete_all if defined?(ActiveStorage::Attachment)
    ActiveStorage::Blob.delete_all if defined?(ActiveStorage::Blob)

    Post.delete_all
    Folder.delete_all
    User.delete_all
  end
end

Faker::UniqueGenerator.clear

puts "Creating users..."

users = 4.times.map do |i|
  User.create!(
    email: "user#{i + 1}@example.com",
    username: "user#{i + 1}",
    pin: "1111",
    password: "password",
    password_confirmation: "password"
  )
end

main_user = users.first

puts "Created users:"
users.each do |user|
  puts "  #{user.email} / password"
end

puts "Creating root folders..."

projects = Folder.create!(
  name: "Projects",
  slug: "projects",
  owner: main_user,
  position: 1
)

archive = Folder.create!(
  name: "Archive",
  slug: "archive",
  owner: users.second,
  position: 2
)

ideas = Folder.create!(
  name: "Ideas",
  slug: "ideas",
  owner: users.third,
  position: 3
)

shared = Folder.create!(
  name: "Shared",
  slug: "shared",
  owner: users.fourth,
  position: 4
)

puts "Creating nested folders..."

rails = Folder.create!(
  name: "Rails",
  slug: "rails",
  owner: users.second,
  parent: projects,
  position: 1
)

dqq = Folder.create!(
  name: "DQQ",
  slug: "dqq",
  owner: users.third,
  parent: rails,
  position: 1
)

frontend = Folder.create!(
  name: "Frontend",
  slug: "frontend",
  owner: main_user,
  parent: projects,
  position: 2
)

old_posts = Folder.create!(
  name: "Old Posts",
  slug: "old-posts",
  owner: users.fourth,
  parent: archive,
  position: 1
)

random_notes = Folder.create!(
  name: "Random Notes",
  slug: "random-notes",
  owner: users.second,
  parent: ideas,
  position: 1
)

deep_child = Folder.create!(
  name: "Deep Child",
  slug: "deep-child",
  owner: users.fourth,
  parent: dqq,
  position: 1
)

puts "Creating random folders..."

10.times do |i|
  parent = Folder.all.sample

  Folder.create!(
    name: Faker::App.unique.name,
    slug: "#{Faker::Internet.unique.slug}-#{i}",
    owner: users.sample,
    parent: parent,
    position: i + 10
  )
end

puts "Creating posts..."

folders = Folder.all.to_a

30.times do |i|
  post_user = users.sample
  folder = [folders.sample, nil].sample

  Post.create!(
    user: post_user,
    folder: folder,
    title: Faker::Lorem.sentence(word_count: 3),
    description: Faker::Lorem.paragraph(sentence_count: 3),
    slug: "#{Faker::Internet.unique.slug}-#{i}",
    status: "public"
  )
end

puts "Creating posts specifically inside known folders..."

[
  projects,
  rails,
  dqq,
  frontend,
  archive,
  ideas,
  shared,
  deep_child
].each do |folder|
  3.times do |i|
    post_user = users.sample

    Post.create!(
      user: post_user,
      folder: folder,
      title: "#{folder.name} Post #{i + 1}",
      description: Faker::Lorem.paragraph(sentence_count: 2),
      slug: "#{folder.full_path.tr('/', '-')}-post-#{i + 1}",
      status: "public"
    )
  end
end

puts "Creating root posts without folder..."

5.times do |i|
  post_user = users.sample

  Post.create!(
    user: post_user,
    folder: nil,
    title: "Root Post #{i + 1}",
    description: Faker::Lorem.paragraph(sentence_count: 2),
    slug: "root-post-#{i + 1}",
    status: "public"
  )
end

puts "Done."
puts
puts "Login users:"
users.each do |user|
  puts "  #{user.email} / password"
end
puts
puts "Useful paths:"
puts "  /v2"
puts "  /v2/explorer"
puts "  /v2/explorer/projects"
puts "  /v2/explorer/projects/rails"
puts "  /v2/explorer/projects/rails/dqq"
