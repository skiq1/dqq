module V2::FoldersHelper
  def folder_options_for_select(folders, selected_id = nil)
    roots = folders.select(&:root?)

    options = roots.flat_map do |folder|
      folder_option_tree(folder)
    end

    options_for_select(options, selected_id)
  end

  private

  def folder_option_tree(folder, depth = 0)
    label = "#{'— ' * depth}#{folder.name}"

    [[label, folder.id]] + folder.children.ordered.flat_map do |child|
      folder_option_tree(child, depth + 1)
    end
  end
end
