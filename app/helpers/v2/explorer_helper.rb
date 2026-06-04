module V2::ExplorerHelper
  def v2_explorer_folder_path_for(folder)
    "/v2/explorer/#{folder.full_path}"
  end
end
