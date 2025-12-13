# frozen_string_literal: true

# Patch to extend Mailer with mention notification methods.
# Overrides delivery methods to send separate mention notifications
# when the setting is enabled.
# Does not send edit/add mails to mentioned users in that case.
module RedmineMentions
  module Patches
    module MailerPatch
      def self.included(base)
        base.prepend(InstanceMethods)
        base.singleton_class.prepend(ClassMethods)
      end

      module InstanceMethods
        def notify_issue_mention(recipient, issue, journal = nil)
          redmine_headers 'Project' => issue.project.identifier,
                          'Issue-Tracker' => issue.tracker.name,
                          'Issue-Id' => issue.id,
                          'Issue-Author' => issue.author.login,
                          'Issue-Assignee' => assignee_for_header(issue)
          redmine_headers 'Issue-Priority' => issue.priority.name if issue.priority

          message_id issue
          references issue

          @author = journal&.user || issue.author
          @recipient = recipient

          @created_on = journal&.created_on || issue.created_on

          @issue = issue
          @project = issue.project
          @journal = journal

          @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue.id, :project_id => issue.project)

          @subject = "[#{@project.name} - #{@issue.tracker.name} ##{@issue.id}] #{l(:subject_you_were_mentioned)} #{@issue.subject}"

          mail(to: @recipient.mail, subject: @subject)
        end

        def notify_wiki_content_mention(wiki_content, recipient)
          redmine_headers 'Project' => wiki_content.project.identifier,
                          'Wiki-Page-Id' => wiki_content.page.id

          message_id wiki_content

          @author = wiki_content.author
          @recipient = recipient

          @created_on = wiki_content.updated_on || wiki_content.created_on

          @wiki_content = wiki_content
          @project = wiki_content.project

          @wiki_content_url = url_for(:controller => 'wiki', :action => 'show', :project_id => wiki_content.project, :id => wiki_content.page.title)

          @subject = "[#{@project.name} - #{l(:subject_wiki_content_mention)} ##{@wiki_content.id}] #{l(:subject_you_were_mentioned)} #{@wiki_content.title}"

          mail(to: @recipient.mail, subject: @subject)
        end
      end

      module ClassMethods
        def notify_mentions_separately?
          RedmineMentions.setting? :notify_mentions_separately
        end

        def deliver_issue_add_mentions(issue)
          return unless notify_mentions_separately?

          mentioned_users = issue.notified_mentions.to_set

          mentioned_users.each do |user|
            notify_issue_mention(user, issue).deliver_later
          end
        end

        def deliver_issue_add(issue)
          return super(issue) unless notify_mentions_separately?

          users = issue.notified_users | issue.notified_watchers

          users.each do |user|
            issue_add(user, issue).deliver_later
          end
        end

        def deliver_issue_edit_mentions(journal)
          return unless notify_mentions_separately?

          mentioned_users = journal.notified_mentions.to_set
          issue = journal.journalized

          mentioned_users.each do |user|
            notify_issue_mention(user, issue, journal).deliver_later
          end
        end

        def deliver_issue_edit(journal)
          return super(journal) unless notify_mentions_separately?

          users  = journal.notified_users | journal.notified_watchers
          mentioned_users = journal.notified_mentions.to_set
          issue = journal.journalized

          users.select! do |user|
            journal.notes? || journal.visible_details(user).any?
          end

          users.each do |user|
            issue_edit(user, journal).deliver_later
          end
        end

        def deliver_wiki_content_added_mentions(wiki_content)
          return unless notify_mentions_separately?

          mentioned_users = wiki_content.notified_mentions.to_set

          mentioned_users.each do |user|
            notify_wiki_content_mention(user, wiki_content).deliver_later
          end
        end

        def deliver_wiki_content_added(wiki_content)
          return super(wiki_content) unless notify_mentions_separately?

          users = wiki_content.notified_users | wiki_content.page.wiki.notified_watchers

          users.each do |user|
            wiki_content_added(user, wiki_content).deliver_later
          end
        end

        def deliver_wiki_content_updated_mentions(wiki_content)
          return unless notify_mentions_separately?

          mentioned_users = wiki_content.notified_mentions.to_set

          mentioned_users.each do |user|
            notify_wiki_content_mention(user, wiki_content).deliver_later
          end
        end

        def deliver_wiki_content_updated(wiki_content)
          return super(wiki_content) unless notify_mentions_separately?

          users  = wiki_content.notified_users
          users |= wiki_content.page.notified_watchers
          users |= wiki_content.page.wiki.notified_watchers

          users.each do |user|
            wiki_content_updated(user, wiki_content).deliver_later
          end
        end
      end
    end
  end
end
