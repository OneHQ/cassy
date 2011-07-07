module Cassy
  module ApplicationHelper
    def serialize_extra_attribute(builder, key, value)
      if value.kind_of?(String)
        builder.tag! key, value
      elsif value.kind_of?(Numeric)
        builder.tag! key, value.to_s
      else
        builder.tag! key do
          builder.cdata! value.to_yaml
        end
      end
    end
  end
end
