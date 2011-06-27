module DeviseHelper
  def define_devise_schema
    ActiveRecord::Schema.define do
      create_table "users", :force => true do |t|
        t.string   "username"
        t.string   "email"
        t.string   "encrypted_password"
      end
    end
  end
end

RSpec.configure do |config|
  config.include DeviseHelper
end