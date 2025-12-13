# frozen_string_literal: true

# Send separate mention notifications for edits/adds regardless of @notify value.
module RedmineMentions
  module Patches
    module IssuePatch
      def self.included(base)
        base.prepend(InstanceMethods)
        base.after_create_commit :send_create_mention_notifications
      end

      module InstanceMethods
        def send_create_mention_notifications
          Mailer.deliver_issue_add_mentions(self)
        end
      end
    end
  end
end
