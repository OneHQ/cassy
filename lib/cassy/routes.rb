module ActionDispatch::Routing
  class Mapper
    def cassy(options={})
      options[:controllers] ||= HashWithIndifferentAccess.new
      options[:controllers][:sessions] ||= "cassy/sessions"
      scope(:path => "cas") do
        mount Cassy::API => '/api'
        get 'login', :to => "#{options[:controllers][:sessions]}#new"
        post 'login', :to => "#{options[:controllers][:sessions]}#create"

        get 'logout', :to => "#{options[:controllers][:sessions]}#destroy"

        get 'serviceValidate', :to => "#{options[:controllers][:sessions]}#service_validate"
        get 'proxyValidate',   :to => "#{options[:controllers][:sessions]}#proxy_validate"
      end
    end
  end
end
