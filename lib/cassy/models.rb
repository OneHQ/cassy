require 'cassy'

Dir[Cassy.root + "app/models/cassy/*.rb"].each do |file|
  require f
end