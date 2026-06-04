module V2
  class FoldersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_folder, only: [:edit, :update, :destroy]
    before_action :authorize_folder!, only: [:edit, :update, :destroy]

    def new
      @parent = Folder.find(params[:parent_id]) if params[:parent_id].present?
      @folder = current_user.folders.new(parent: @parent)
    end

    def create
      @folder = current_user.folders.new(folder_params)

      if @folder.save
        redirect_to v2_explorer_folder_url(@folder), notice: "Folder created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @folder.update(folder_params)
        redirect_to v2_explorer_folder_url(@folder), notice: "Folder updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      parent = @folder.parent
      @folder.destroy!

      redirect_to(
        parent ? v2_explorer_folder_url(parent) : v2_explorer_path,
        notice: "Folder deleted."
      )
    rescue Ancestry::AncestryException, ActiveRecord::DeleteRestrictionError
      redirect_to v2_explorer_folder_url(@folder), alert: "Cannot delete folder with subfolders."
    end

    private

    def set_folder
      @folder = Folder.find(params[:id])
    end

    def authorize_folder!
      return if @folder.editable_by?(current_user)

      redirect_to v2_explorer_path, alert: "No permission."
    end

    def folder_params
      params.require(:folder).permit(:name, :slug, :parent_id, :position)
    end

    def v2_explorer_folder_url(folder)
      "/v2/explorer/#{folder.full_path}"
    end
  end
end
