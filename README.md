# Envoy

Envoy is a visa invitation letter management system built for Hack Club. It handles the end-to-end process of issuing official visa invitation letters for international attendees of Hack Club events.

## What it does

When someone from outside the United States wants to attend a Hack Club hackathon, they often need a visa invitation letter to support their B1/B2 visa application. Envoy manages this process:

1. **Event Management** - Administrators create events with details like dates, venue, and application deadlines
2. **Application Submission** - Participants select an event and submit their personal information (name, passport details, address, etc.)
3. **Email Verification** - Applicants verify their email address with a 6-digit code
4. **Admin Review** - Staff review applications and approve or reject them
5. **Letter Generation** - Approved applications automatically generate a PDF visa invitation letter
6. **Letter Verification** - Each letter includes a verification code that embassies can use to confirm authenticity

## Technical Overview

- **Framework**: Rails 8.1
- **Database**: PostgreSQL
- **Background Jobs**: Sidekiq with Redis
- **PDF Generation**: Prawn
- **Styling**: Tailwind CSS 4.x
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Authentication**: OmniAuth with Hack Club OAuth

## Running Locally

```bash
# Install dependencies
bundle install

# Set up the database
rails db:create db:migrate db:seed

# Start the development server
bin/dev
```

The app runs at `http://localhost:3000`.

## Environment Variables

The following environment variables are required in production:

- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string for Sidekiq
- `HACKCLUB_CLIENT_ID` - OAuth client ID for Hack Club authentication
- `HACKCLUB_CLIENT_SECRET` - OAuth client secret
- `POSTMARK_API_TOKEN` - API token for sending emails via Postmark
- `AWS_ACCESS_KEY_ID` - AWS credentials for S3 storage
- `AWS_SECRET_ACCESS_KEY` - AWS credentials for S3 storage
- `AWS_BUCKET` - S3 bucket name for file storage
- `AWS_REGION` - AWS region

## License

Copyright The Hack Foundation. All rights reserved.
