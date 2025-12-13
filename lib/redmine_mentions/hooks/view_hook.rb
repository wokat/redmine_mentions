# frozen_string_literal: true

module RedmineMentions
  module Hooks
    class ViewHook < Redmine::Hook::ViewListener
      # Additional context fields
      #   :issue  => the issue this is edited
      #   :f      => the form object to create additional fields
      render_on :view_issues_edit_notes_bottom,
                :partial => 'hooks/redmine_mentions/edit_mentionable'
      render_on :view_issues_form_details_bottom,
                :partial => 'hooks/redmine_mentions/edit_mentionable'
    end
  end
end
