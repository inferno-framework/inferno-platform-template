require 'inferno'
require 'sidekiq-cron'

require_relative 'lib/inferno_platform_template/delete_old_sessions'

Inferno::Application.finalize!

InfernoPlatformTemplate::DeleteOldSessions.add_to_schedule