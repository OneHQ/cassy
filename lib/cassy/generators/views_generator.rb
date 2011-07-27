require 'rails/generators'
require 'tmpdir'

# "Borrowed" from Devise
module Cassy
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../app/views", __FILE__)
      desc "Copies all Cassy views to your application."

      def copy_views
        directory "cassy", "app/views/cassy"
      end
    end
  end
end
