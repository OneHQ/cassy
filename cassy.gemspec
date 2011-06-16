# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "cassy"
  s.summary = "Insert Cassy summary."
  s.description = "Insert Cassy description."
  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.version = "0.0.1"
  
  s.add_dependency 'crypt-isaac'
  
  s.add_development_dependency 'rspec-rails', '~> 2.6.0'
  s.add_development_dependency 'capybara', '~> 1.0'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'launchy'
  s.add_development_dependency 'devise', '~> 1.3'
end
