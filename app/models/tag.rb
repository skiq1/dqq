class Tag < ApplicationRecord
  has_ancestry cache_depth: true

  enum :kind, {
    structure: "structure",
    topic: "topic",
    type: "type",
    meta: "meta"
  }, suffix: true

  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 120 }

  before_validation :set_slug, if: -> { slug.blank? }

  scope :ordered, -> { order(:position, :name) }

  def breadcrumb_tags
    ancestors.to_a + [self]
  end

  def breadcrumb_label
    breadcrumb_tags.map(&:name).join(" / ")
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize
  end
end
