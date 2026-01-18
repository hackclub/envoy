source "https://rubygems.org"

ruby "3.2.8"

gem "rails", "~> 8.1.0"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "redis", ">= 4.0.1"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"

# Authentication & Authorization
gem "devise"
gem "omniauth"
gem "omniauth-hack_club"
gem "omniauth-rails_csrf_protection"
gem "pundit"

# Background Jobs
gem "sidekiq"

# Email
gem "postmark-rails"

# Cloud Storage (Cloudflare R2)
gem "aws-sdk-s3", require: false

# PDF Generation
gem "grover"
gem "hexapdf"

# QR Code Generation
gem "rqrcode"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end
