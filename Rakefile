require 'rspec/core/rake_task'
require 'jekyll'
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
  desc 'Generate the static platform web site'
  task :generate do
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