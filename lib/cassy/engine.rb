module Cassy
  class Engine < Rails::Engine
    config.config_file = ENV["RUBYCAS_CONFIG_FILE"]
    config.after_initialize do
      if config.config_file && File.exists?(config.config_file)
        config.configuration = HashWithIndifferentAccess.new(YAML.load_file(config.config_file))
      end
    end
  end
end
