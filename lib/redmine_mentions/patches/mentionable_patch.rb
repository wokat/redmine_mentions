# frozen_string_literal: true

module RedmineMentions
  module Patches
    module MentionablePatch
      def self.included(base)
        base.prepend(InstanceMethods)
      end

      module InstanceMethods
        def notify_mentions_separately?
          RedmineMentions.setting? :notify_mentions_separately
        end

        def ignore_self_mentions?
          RedmineMentions.setting? :ignore_self_mentions
        end

        # Collects all mentions in all changed mentionable attributes
        def parse_mentions
          return super unless notify_mentions_separately?

          mentionable_attrs = self.mentionable_attributes
          saved_mentionable_attrs = self.saved_changes.select{|a| mentionable_attrs.include?(a)}
          mentions = []

          saved_mentionable_attrs.each_value do |attr|
            old_value, new_value = attr

            previous_matches = scan_for_mentioned_users(old_value)
            current_matches = scan_for_mentioned_users(new_value)
            new_matches = (current_matches - previous_matches).flatten

            mentions |= new_matches
          end

          self.mentioned_users = mentions.map do |login|
            User.visible.active.find_by(login: login)
          end.compact
        end

        # Ignores notification setting for users: mentions are always notified.
        # Does not notify self-mentions if configured.
        def notified_mentions
          return super unless notify_mentions_separately?

          notified = mentioned_users.to_a
          notified.reject! {|user| user.mail.blank?}

          if respond_to?(:visible?)
            notified.select! {|user| visible?(user)}
          end

          if ignore_self_mentions?
            author_id = respond_to?(:author_id) ? self.author_id :
                        respond_to?(:user_id) ? self.user_id : nil
            notified.reject! {|user| user.id == author_id} if author_id
          end

          notified
        end
      end
    end
  end
end
