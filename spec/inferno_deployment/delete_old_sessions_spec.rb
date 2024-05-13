require_relative '../../lib/inferno_platform_template/delete_old_sessions'

RSpec.describe InfernoPlatformTemplate::DeleteOldSessions do
  describe '#find_old_session_ids' do
    it 'only returns ids for old sessions with no new test runs' do
      old_session_with_no_test_runs = repo_create(:test_session, created_at: 3.months.ago)
      old_session_with_old_test_run = repo_create(:test_session, created_at: 3.months.ago)
      repo_create(:test_run, test_session_id: old_session_with_old_test_run.id, created_at: 3.months.ago)
      old_session_with_new_test_run = repo_create(:test_session, created_at: 3.months.ago)
      repo_create(:test_run, test_session_id: old_session_with_new_test_run.id, created_at: 3.months.ago)
      repo_create(:test_run, test_session_id: old_session_with_new_test_run.id, created_at: 1.day.ago)
      new_session_with_new_test_run = repo_create(:test_session, created_at: 1.day.ago)
      repo_create(:test_run, test_session_id: new_session_with_new_test_run.id, created_at: 1.day.ago)
      new_session_with_no_test_runs = repo_create(:test_session, created_at: 1.day.ago)

      ids_found = described_class.new.find_old_session_ids

      expect(ids_found).to include(old_session_with_no_test_runs.id)
      expect(ids_found).to include(old_session_with_old_test_run.id)
      expect(ids_found).to_not include(old_session_with_new_test_run.id)
      expect(ids_found).to_not include(new_session_with_new_test_run.id)
      expect(ids_found).to_not include(new_session_with_no_test_runs.id)
    end
  end
end
