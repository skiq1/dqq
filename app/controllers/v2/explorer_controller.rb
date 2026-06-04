module V2
  class ExplorerController < ApplicationController
    before_action :authenticate_user!

    def show
      @current_folder =
        if params[:path].present?
          Folder.find_by_full_path!(params[:path])
        end

      @sidebar_tree = Folder.visible_to(current_user).arrange(order: :position)

      @breadcrumbs =
        @current_folder ? @current_folder.path : []

      @folders =
        if @current_folder
          @current_folder.children.ordered
        else
          Folder.visible_to(current_user).roots.ordered
        end

      @posts =
        if @current_folder
          @current_folder.posts.order(created_at: :desc)
        else
          Post.where(folder_id: nil).order(created_at: :desc)
        end
    end
  end
end
