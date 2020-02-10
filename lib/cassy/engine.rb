module Cassy
  class Engine < Rails::Engine
    config.config_file = ENV["RUBYCAS_CONFIG_FILE"]
    config.after_initialize do
      config.configuration = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(config.config_file))
    end
  end
end
