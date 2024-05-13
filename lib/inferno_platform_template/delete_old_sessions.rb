require 'inferno/repositories/session_data'

module InfernoPlatformTemplate
  class DeleteOldSessions
    include Sidekiq::Worker
    attr_accessor :dry_run

    TestRun = Inferno::Repositories::TestRuns::Model
    TestSession = Inferno::Repositories::TestSessions::Model
    SessionData = Inferno::Repositories::SessionData::Model
    Request = Inferno::Repositories::Requests::Model
    Result = Inferno::Repositories::Results::Model

    SESSION_BATCH_SIZE = 5

    def self.schedule
      # Times are UTC, so 5 is midnight
      ENV.fetch('SESSION_DELETION_CRON_SCHEDULE', '0 5 * * *')
    end

    def self.dry_run?
      ENV.fetch('SESSION_DELETION_DRY_RUN', 'false')&.casecmp? 'true'
    end

    def self.add_to_schedule
      deletion_job =
        Sidekiq::Cron::Job.new(
          name: 'Old Session Deletion Job',
          cron: schedule,
          class: 'InfernoPlatformTemplate::DeleteOldSessions',
          args: { dry_run: dry_run? }
        )

      if deletion_job.valid?
        deletion_job.save
      else
        puts "Error creating session deletion job"
        puts deletion_job.errors
      end
    end

    def find_old_session_ids
      query = 'SELECT id FROM test_sessions WHERE created_at < ? AND NOT EXISTS ' \
              '(SELECT id FROM test_runs WHERE test_runs.test_session_id = test_sessions.id and created_at > ?) ' \
              'ORDER BY created_at ASC'
      cutoff_date = 9.weeks.ago

      Inferno::Application['db.connection'][query, cutoff_date, cutoff_date].map(:id)
    end

    def destroy_requests_results_requests_and_headers(session_ids)
      ids = Request.where(test_session_id: session_ids).select(:index).map(:index)

      headers_query = Inferno::Repositories::Headers.db.where(request_id: ids)
      requests_query = Inferno::Repositories::Requests.db.where(index: ids)
      requests_results_query = Inferno::Application['db.connection'][:requests_results].where(requests_id: ids)

      Inferno::Application['logger'].info "Deleting #{requests_results_query.count} requests_results"
      Inferno::Application['logger'].info "Deleting #{headers_query.count} headers"
      Inferno::Application['logger'].info "Deleting #{requests_query.count} requests"
      requests_results_query.delete unless dry_run
      headers_query.delete unless dry_run
      requests_query.delete unless dry_run
      sleep 0.3 if dry_run
    end

    def destroy_messages_results(session_ids)
      ids = Result.where(test_session_id: session_ids).select(:id).map(:id)

      messages_query = Inferno::Repositories::Messages.db.where(result_id: ids)
      results_query = Inferno::Repositories::Results.db.where(id: ids)

      Inferno::Application['logger'].info "Deleting #{messages_query.count} messages"
      messages_query.delete unless dry_run
      Inferno::Application['logger'].info "Deleting #{results_query.count} results"
      results_query.delete unless dry_run
      sleep 0.3 if dry_run
    end

    def destroy_test_runs(session_ids)
      test_runs_query = TestRun.where(test_session_id: session_ids)

      Inferno::Application['logger'].info "Deleting #{test_runs_query.count} test runs"
      test_runs_query.delete unless dry_run
    end

    def destroy_session_data(session_ids)
      session_ids.each do |session_id|
        session_data_query = SessionData.where(test_session_id: session_id)

        Inferno::Application['logger'].info "Deleting #{session_data_query.count} session data"
        session_data_query.delete unless dry_run
        sleep 0.3 if dry_run
      end
    end

    # def destroy_sessions(session_ids)
    #   sessions_query = TestSession.where(id: session_ids)

    #   Inferno::Application['logger'].info "Deleting #{sessions_query.count} test sessions"
    #   sessions_query.delete unless dry_run
    #   sleep 1 if dry_run
    # end

    def perform(raw_params = {})
      params = raw_params.deep_symbolize_keys
      self.dry_run = params.fetch(:dry_run, false)

      session_ids_to_delete = find_old_session_ids
      session_count = session_ids_to_delete.length

      session_ids_to_delete.each_slice(SESSION_BATCH_SIZE) do |session_ids|
        Inferno::Application['logger'].info 'Session deletion DRY RUN' if dry_run
        Inferno::Application['logger'].info "#{session_count} sessions left to delete"
        Inferno::Application['logger'].info "Starting to delete sessions #{session_ids.join(', ')}"
        destroy_requests_results_requests_and_headers(session_ids)
        destroy_messages_results(session_ids)
        destroy_test_runs(session_ids)
        destroy_session_data(session_ids)
        # destroy_sessions(session_ids)

        session_count -= session_ids.length
        Inferno::Application['logger'].info "Finished deleting #{session_ids.length} sessions\n\n"

        sleep 5 if dry_run
      end

      Inferno::Application['db.connection'].run('VACUUM VERBOSE ANALYZE')
    end
  end
end
