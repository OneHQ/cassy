module Cassy
  class Engine < Rails::Engine
    config.config_file = ENV["RUBYCAS_CONFIG_FILE"]
    config.after_initialize do
      file = File.read(config.config_file)
      config.configuration = HashWithIndifferentAccess.new(YAML.load(ERB.new(file).result))
    end
  end
end
