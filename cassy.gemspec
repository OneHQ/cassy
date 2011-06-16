# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "cassy"
  s.summary = "Insert Cassy summary."
  s.authors = ["ryan@rubyx.com"]
  s.description = "An engine that provides a CAS server to the application it's included within."
  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.markdown"]
  s.version = "1.0.1"
  
  s.add_dependency 'crypt-isaac'
  s.add_dependency 'rails', '3.0.7'
  
  s.add_development_dependency 'rspec-rails', '~> 2.6.0'
  s.add_development_dependency 'capybara', '~> 1.0'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'launchy'
  s.add_development_dependency 'devise', '~> 1.3'
end
