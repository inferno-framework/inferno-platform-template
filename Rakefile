require 'rspec/core/rake_task'
require 'jekyll'
require 'yaml'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :db do
  desc 'Apply changes to the database'
  task :migrate do
    require 'inferno/config/application'
    require 'inferno/utils/migration'
    Inferno::Utils::Migration.new.run
  end
end

namespace :web do
  desc 'Create test kit pages from test kit metadata'
  task :create_test_kit_pages do

    TEST_KIT_PAGE_DIR = File.join(__dir__, 'web', '_test_kits')
    require 'inferno'
    ENV['NO_DB'] = 'true'
    Inferno::Application.start(:suites)

    FileUtils.rm_rf(Dir.glob(File.join(TEST_KIT_PAGE_DIR, '*.md')))

    config = YAML.safe_load(File.read(File.join(__dir__,'web','_config.yml')))
    excluded_test_kits = config.fetch('excluded_test_kits', [])

    test_kits = Inferno::Repositories::TestKits.new.all

    test_kits.each do |test_kit|
      next if excluded_test_kits.include?(test_kit.id.to_s)

      formatted_id = test_kit.id.to_s.dasherize.delete_suffix('-test-kit')
      file_path = File.join(TEST_KIT_PAGE_DIR, "#{formatted_id}.md")

      front_matter = {
        'layout' => 'test-kit',
        'title' => test_kit.title,
        'test_kit_id' => test_kit.id.to_s,
        'tags' => test_kit.tags,
        'date' => Date.parse(test_kit.last_updated),
        'version' => test_kit.version,
        'maturity' => test_kit.maturity,
        'suites' => test_kit.suites.map { |suite| { 'title' => suite.title, 'id' => suite.id } }
      }

      option_groups = test_kit.suites.flat_map do |suite|
        next [] unless suite.suite_options.present?

        suite.suite_options.map do |option|
          {
            'title' => option.title,
            'id' => option.id.to_s,
            'suites' => [ suite.id ], # This could be a more compact with some processing; ok because generated
            'default' => option.default,
            'options' => option.list_options.map do |list_option|
              {
                'label' => list_option[:label],
                'value' => list_option[:value],
                'default' => list_option[:default]
              }.compact
            end
          }.compact
        end
      end.compact

      front_matter['option_groups'] = option_groups if option_groups.any?

      FileUtils.mkdir_p(File.dirname(file_path))

      File.open(file_path, 'w') do |file|
        file.puts front_matter.to_yaml
        file.puts '---'
        file.puts test_kit.description
      end

      puts "Generated #{file_path} for #{test_kit.title}"
    end
  end

  desc 'Generate the static platform web site'
  task generate: [:create_test_kit_pages] do
    require 'dotenv'
    Dotenv.load(File.join(Dir.pwd, '.env'))
    config = Jekyll.configuration({
      core_base_path: ENV['BASE_PATH'] ? "/#{ENV['BASE_PATH']}/" : '/',
      source: 'web',
    })

    site = Jekyll::Site.new(config)
    Jekyll::Commands::Build.build(site, config)

  end

  desc 'Generate and serve the static web platform pages'
  task serve: [:generate] do

    sh "jekyll serve --skip-initial-build --no-watch"

  end
end
