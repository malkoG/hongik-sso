# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# gem "rails"
gemspec

gem "sorbet-runtime"

group :development do
  gem "sorbet"
  gem "solargraph"
  gem "pry"
end

group :test do
  gem "rspec"
end