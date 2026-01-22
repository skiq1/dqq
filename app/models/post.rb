class Post < ApplicationRecord
  # enum :status => [:public, :unlisted, :private]
  has_secure_password :password, validations: false
  validates :password, presence: false, allow_blank: true

  belongs_to :user
  include AppendToHasManyAttached["files"]
  has_many_attached :files

  scope :not_expired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end


  before_validation :generate_slug, on: :create
  enum :status, { public: 0, unlisted: 1, private: 2, archived: 3, deleted: 4 }, suffix: true



  validates :title,
    presence: false,
    length: { maximum: 255 }

  validates :description,
    presence: false,
    length: { maximum: 100000 }

  validates :slug, presence: true, uniqueness: true, length: { maximum: 100 }
  validate :slug_has_correct_format
  validate :files_size_within_limit
  validate :filename_length_within_limit
  # validate :presence_of_user

  validates :redirect_url, format: URI.regexp(%w[http https]), allow_blank: true



  def slug_has_correct_format
    errors.add(:slug, "is invalid. (a-z, A-Z, 0-9, -, _, +)") unless slug.match? /^[a-zA-Z0-9\-+_]+$/
  end

  def files_size_within_limit
    files.each do |file|
      if file.blob.byte_size > 1.gigabyte
        errors.add(:files, "size should be less than 1GB")
      end
    end
  end

  def filename_length_within_limit
    files.each do |file|
      if file.blob.filename.to_s.length > 255
        errors.add(:files, "filename should be less than 255 characters")
      end
    end
  end

  # def presence_of_user
  #   errors.add(:user, "must exists.") if self.user_id.nil? and !current_user
  #   errors.add(:username, "must be empty.") if !self.user_id.nil? and current_user
  # end

  def generate_slug
    if slug.blank?
      self.slug = generate_random_slug
    end

    loop_protection = 0
    while Post.exists?(slug: self.slug)
      errors.add(:slug, "could not be generated.") if loop_protection > 50
      self.slug = generate_random_slug
      loop_protection += 1
    end
  end

  def generate_random_slug
    SecureRandom.alphanumeric(2).downcase
  end


  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "redirect_url", "slug", "title", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "files_attachment", "files_blobs" ]
  end
end
