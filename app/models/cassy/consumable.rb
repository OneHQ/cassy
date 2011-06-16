module Cassy
  module Consumable
    extend ActiveSupport::Concern
    def consume!
      self.consumed = Time.now
      self.save!
    end

    module ClassMethods
      def cleanup(max_lifetime, max_unconsumed_lifetime)
        transaction do
          conditions = ["created_on < ? OR (consumed IS NULL AND created_on < ?)",
                          Time.now - max_lifetime,
                          Time.now - max_unconsumed_lifetime]
          puts all.count
          expired_tickets_count = count(:conditions => conditions)

          $LOG.debug("Destroying #{expired_tickets_count} expired #{self.name.demodulize}"+
            "#{'s' if expired_tickets_count > 1}.") if expired_tickets_count > 0

          destroy_all(conditions)
        end
      end
    end
  end
end