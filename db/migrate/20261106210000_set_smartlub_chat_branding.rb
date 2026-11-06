# [custom] Renames the installation to "Smartlub Chat".
class SetSmartlubChatBranding < ActiveRecord::Migration[7.2]
  NAMES = %w[INSTALLATION_NAME BRAND_NAME].freeze

  def up
    set_names('Smartlub Chat')
  end

  def down
    set_names('Chatwoot')
  end

  private

  def set_names(value)
    NAMES.each do |name|
      config = InstallationConfig.find_by(name: name)
      next unless config

      config.value = value
      config.save!
    end
    GlobalConfig.clear_cache
  end
end
