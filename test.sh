#!/bin/sh

BUNDLE_GEMFILE=Gemfile.rails-5.1 bundle install && BUNDLE_GEMFILE=Gemfile.rails-5.1 bundle exec rspec spec
BUNDLE_GEMFILE=Gemfile.rails-5.2 bundle install && BUNDLE_GEMFILE=Gemfile.rails-5.2 bundle exec rspec spec
BUNDLE_GEMFILE=Gemfile.rails-6.0 bundle install && BUNDLE_GEMFILE=Gemfile.rails-6.0 bundle exec rspec spec
BUNDLE_GEMFILE=Gemfile.rails-master bundle install && BUNDLE_GEMFILE=Gemfile.rails-master bundle exec rspec spec
