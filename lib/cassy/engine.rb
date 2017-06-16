module Cassy
  class Engine < Rails::Engine
    config.config_file = ENV["RUBYCAS_CONFIG_FILE"]
    config.after_initialize do
      config.configuration = HashWithIndifferentAccess.new(YAML.load(ERB.new(File.read(config.config_file)).result))
    end
  end
end
