class Folder < ApplicationRecord
  has_ancestry orphan_strategy: :restrict

  belongs_to :owner, class_name: "User", foreign_key: :user_id
  has_many :posts, dependent: :nullify

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :normalize_slug

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, length: { maximum: 100 }
  validates :slug, uniqueness: { scope: :ancestry }

  validates :slug, format: {
    with: /\A[a-z0-9\-_]+\z/,
    message: "can only contain lowercase letters, numbers, dashes and underscores"
  }


  validate :cannot_move_to_own_descendant

  scope :ordered, -> { order(:position, :name) }

  def breadcrumb
    path
  end

  def full_path
    path.map(&:slug).join("/")
  end

  def self.find_by_full_path!(full_path)
    slugs = full_path.to_s.split("/")

    current = nil

    slugs.each do |slug|
      scope = current ? current.children : roots
      current = scope.find_by!(slug: slug)
    end

    current
  end

  def self.visible_to(user)
    all
  end

  def editable_by?(user)
    return false if user.blank?
    return true if user.respond_to?(:admin?) && user.admin?
    return true if user_id == user.id

    ancestors.exists?(user_id: user.id)
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end

  def normalize_slug
    self.slug = slug.to_s.parameterize if slug.present?
  end

  def cannot_move_to_own_descendant
    return if parent.nil?
    return unless persisted?
    return unless parent.path_ids.include?(id)

    errors.add(:parent, "cannot be a descendant of itself")
  end
end
