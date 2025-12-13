# frozen_string_literal: true

# Send separate mention notifications for edits/adds regardless of @notify value.
module RedmineMentions
  module Patches
    module WikiContentPatch
      def self.included(base)
        base.prepend(InstanceMethods)
      end

      module InstanceMethods
        def send_notification_create
          super

          Mailer.deliver_wiki_content_added_mentions(self)
        end

        def send_notification_update
          super

          Mailer.deliver_wiki_content_updated_mentions(self) if saved_change_to_text?
        end
      end
    end
  end
end
