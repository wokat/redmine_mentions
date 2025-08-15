# frozen_string_literal: true

module RedmineMentions
  module Hooks
    class ModelHook < Redmine::Hook::Listener
      def after_plugins_loaded(_context = {})
        RedmineMentions.setup!
      end
    end
  end
end
