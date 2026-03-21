class PostTag < ApplicationRecord
  belongs_to :post
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :post_id }
  validate :only_one_main_tag_per_post

  scope :main, -> { where(main: true) }

  private

  def only_one_main_tag_per_post
    return unless main?

    scope = PostTag.where(post_id: post_id, main: true)
    scope = scope.where.not(id: id) if persisted?

    errors.add(:main, "already exists for this post") if scope.exists?
  end
end
