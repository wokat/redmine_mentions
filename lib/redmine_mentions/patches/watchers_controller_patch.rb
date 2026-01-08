# frozen_string_literal: true

module RedmineMentions
  module Patches
    module WatchersControllerPatch
      def self.included(base)
        base.class_eval do
          # Replace autocomplete_for_mention from the authorize before_action and replace with our own
          skip_before_action :authorize, only: [:autocomplete_for_mention]
          before_action :authorize_mention_autocomplete, only: [:autocomplete_for_mention]
        end
      end

      def notify_mentions_separately?
        RedmineMentions.setting? :notify_mentions_separately
      end

      def authorize_mention_autocomplete(ctrl = params[:controller], action = params[:action], global = false)
        return authorize(ctrl, action, global) unless notify_mentions_separately?

        if !@project
          render_404
          return false
        end

        if !User.current.admin? && !User.current.member_of?(@project)
          render_403
          return false
        end

        return true
      end
    end
  end
end