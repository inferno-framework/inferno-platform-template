#!/bin/sh
sleep 5
bundle exec sidekiq -r ./worker.rb
