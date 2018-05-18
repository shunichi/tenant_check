#!/bin/sh

BUNDLE_GEMFILE=Gemfile.rails-5.2 bundle update && BUNDLE_GEMFILE=Gemfile.rails-5.2 bundle exec rspec spec
BUNDLE_GEMFILE=Gemfile.rails-5.1 bundle update && BUNDLE_GEMFILE=Gemfile.rails-5.1 bundle exec rspec spec