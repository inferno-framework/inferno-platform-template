module InfernoPlatformTemplate
  class CheckSuiteConfiguration
    include Sidekiq::Worker

    def self.add_to_schedule
      job_to_schedule =
        Sidekiq::Cron::Job.new(
          name: 'Suite Configuration Check Job',
          cron: '*/5 * * * *',
          class: 'InfernoPlatformTemplate::CheckSuiteConfiguration'
        )

      if job_to_schedule.valid?
        job_to_schedule.save
      else
        puts "Error creating suite configuration check job"
        puts job_to_schedule.errors
      end
    end

    def perform
      url = URI.join(Inferno::Application['base_url'], 'suites/api/test_suites/g10_certification/check_configuration')

      Faraday.put(url)
    end
  end
end
