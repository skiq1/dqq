class TagsController < ApplicationController
  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @children = @tag.children.ordered

    # @posts = Post
    #   .joins(:post_tags)
    #   .where(post_tags: { tag_id: @tag.id })
    #   .where.not(status: :deleted)
    #   .includes(:user, :main_tag, files_attachments: :blob)
    #   .distinct
    #   .order(pinned: :desc, created_at: :desc)

    tag_ids = @tag.subtree_ids

    @posts = Post
      .joins(:post_tags)
      .where(post_tags: { tag_id: tag_ids })
      .where.not(status: :deleted)
      .includes(:user, :main_tag, files_attachments: :blob)
      .distinct
      .order(pinned: :desc, created_at: :desc)
  end
end
