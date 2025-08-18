# frozen_string_literal: true

require 'redmine_plugin_kit'

module RedmineMentions
  include RedminePluginKit::PluginBase

  class << self

    private

    def setup
      loader.add_patch %w[Journal]

      # Apply patches and helper
      loader.apply!

      # Load view hooks
      loader.load_view_hooks!
    end
  end
end
