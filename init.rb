# frozen_string_literal: true

require 'redmine'
require 'redmine_plugin_kit'

loader = RedminePluginKit::Loader.new plugin_id: 'redmine_mentions'

loader.require_files 'redmine_mentions/plugin_version'

Redmine::Plugin.register :redmine_mentions do
  name 'Redmine Mentions'
  author 'Arkhitech, Taine Woo'
  description 'This is a plugin for Redmine which gives suggestions on using username in comments'
  version RedmineMentions::PluginVersion::VERSION
  url 'https://github.com/tainewoo/redmine_mentions'
  author_url 'https://github.com/tainewoo'

  directory File.dirname(__FILE__)

  requires_redmine version_or_higher: '5.0'

  settings :default => {'trigger' => '@'}, :partial => 'settings/mention'
end

RedminePluginKit::Loader.persisting do
  loader.load_model_hooks!
end
