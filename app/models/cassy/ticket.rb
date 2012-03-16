module Cassy
  module Ticket
    def to_s
      ticket
    end

    def self.cleanup(max_lifetime)
      transaction do
        conditions = ["created_on < ?", Time.now - max_lifetime]
        expired_tickets_count = count(:conditions => conditions)

        $LOG.debug("Destroying #{expired_tickets_count} expired #{self.name.demodulize}"+
          "#{'s' if expired_tickets_count > 1}.") if expired_tickets_count > 0

        destroy_all(conditions)
      end
    end
    
    class Error
      attr_reader :code, :message

      def initialize(code, message)
        @code = code
        @message = message
      end

      def to_s
        message
      end
    end
    
  end
end