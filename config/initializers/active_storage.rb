ActiveSupport.on_load(:active_storage_blob) do
  def self.ransackable_attributes(auth_object = nil)
    %w[filename]
  end
end
