# Hack Club Visa Letter Generator

## Technical Specification Document

---

## 1. Project Overview

### Purpose
A web application for Hack Club to generate and manage visa invitation letters for international participants attending Hack Club events. The system streamlines the process of collecting participant information, verifying identities via email, obtaining admin approval, and delivering professionally formatted visa letters as PDF documents.

### Core Workflow Summary

**Participant Journey:**
1. Selects an event from the list of active events
2. Fills out a simple form with personal details
3. Receives a 6-digit verification code via email
4. Enters the code to verify email ownership
5. Application enters "pending approval" status
6. Receives approved visa letter as a PDF via email once an admin approves

**Admin Journey:**
1. Logs into the admin dashboard
2. Creates and manages events
3. Optionally creates custom letter templates for specific events
4. Reviews pending visa letter applications
5. Approves or rejects applications
6. System automatically generates PDF and emails it to approved participants

---

## 2. Technology Stack

### Core Framework
- Ruby version 3.2 or higher
- Rails version 7.1 or higher
- PostgreSQL 15 or higher as the database

### Key Gems Required
- **devise** for admin authentication
- **pundit** for authorization policies
- **prawn** and **prawn-table** for PDF generation
- **sidekiq** for background job processing
- **redis** for Sidekiq backend
- **tailwindcss-rails** for styling
- **turbo-rails** and **stimulus-rails** for Hotwire functionality
- **rspec-rails**, **factory_bot_rails**, and **faker** for testing
- **letter_opener** for development email preview

### File Storage
- Active Storage for storing generated PDF letters and any uploaded letterhead/signature images

---

## 3. Database Design

### Tables Required

#### admins
This table stores admin user accounts who can manage events and approve applications.

Fields:
- id: UUID primary key
- email: string, required, unique, used for login
- encrypted_password: string, required, managed by Devise
- first_name: string, required, maximum 100 characters
- last_name: string, required, maximum 100 characters
- super_admin: boolean, defaults to false, grants elevated permissions
- Standard Devise fields for password recovery, session tracking, and account lockout
- created_at and updated_at timestamps

Indexes needed on email (unique), reset_password_token (unique), and unlock_token (unique).

#### events
This table stores information about Hack Club events that participants can apply for.

Fields:
- id: UUID primary key
- name: string, required, the display name of the event
- slug: string, required, unique, URL-friendly identifier generated from name
- description: text, optional, longer description of the event
- venue_name: string, required, name of the venue
- venue_address: string, required, full street address of venue
- city: string, required
- country: string, required
- start_date: date, required
- end_date: date, required
- application_deadline: datetime, optional, when applications close
- contact_email: string, required, email for event inquiries
- active: boolean, defaults to true, whether event is visible
- applications_open: boolean, defaults to true, whether new applications are accepted
- admin_id: UUID foreign key, references the admin who created the event
- created_at and updated_at timestamps

Indexes needed on slug (unique), start_date, active, and applications_open.

#### letter_templates
This table stores visa letter templates. One template can be marked as the system default, and individual events can have their own custom templates.

Fields:
- id: UUID primary key
- name: string, required, descriptive name for the template
- body: text, required, the letter content with placeholder variables
- signatory_name: string, required, name of person signing the letter
- signatory_title: string, required, title of the signatory
- event_id: UUID foreign key, optional, null means this is a global template
- is_default: boolean, defaults to false, only one template should have this true with null event_id
- active: boolean, defaults to true
- created_at and updated_at timestamps

This table should also have Active Storage attachments for signature_image and letterhead_image.

Indexes needed on is_default and on the combination of event_id and active.

#### participants
This table stores the personal information submitted by visa letter applicants.

Fields:
- id: UUID primary key
- email: string, required, contact email for the participant
- full_name: string, required, complete legal name as it appears on passport
- date_of_birth: date, required
- country_of_birth: string, required
- phone_number: string, required
- full_street_address: text, required, complete mailing address
- verification_code: string, nullable, the 6-digit code sent for email verification
- verification_code_sent_at: datetime, nullable, when the code was sent
- email_verified_at: datetime, nullable, when email was successfully verified
- verification_attempts: integer, defaults to 0, tracks failed verification attempts
- created_at and updated_at timestamps

Indexes needed on email and verification_code.

#### visa_letter_applications
This table tracks the status of each participant's application for a specific event and links participants to events.

Fields:
- id: UUID primary key
- participant_id: UUID foreign key, required, references participants table
- event_id: UUID foreign key, required, references events table
- reviewed_by_id: UUID foreign key, optional, references admins table
- status: string, required, defaults to "pending_verification"
- admin_notes: text, optional, internal notes from admin
- rejection_reason: text, optional, required if status is rejected
- submitted_at: datetime, nullable, when email was verified and application submitted
- reviewed_at: datetime, nullable, when admin approved or rejected
- letter_generated_at: datetime, nullable, when PDF was created
- letter_sent_at: datetime, nullable, when email with PDF was sent
- reference_number: string, required, unique, human-readable identifier like "HC-ABC12345"
- created_at and updated_at timestamps

The combination of participant_id and event_id should be unique to prevent duplicate applications.

Indexes needed on status, reference_number (unique), the participant_id/event_id combination (unique), and submitted_at.

#### activity_logs
This table provides an audit trail of all significant actions in the system.

Fields:
- id: UUID primary key
- trackable_type: string, required, polymorphic type
- trackable_id: UUID, required, polymorphic ID
- admin_id: UUID foreign key, optional, references admins table
- action: string, required, describes what happened
- metadata: jsonb, defaults to empty object, stores additional context
- ip_address: string, optional
- user_agent: string, optional
- created_at timestamp

Indexes needed on the polymorphic trackable fields, action, and created_at.

---

## 4. Model Specifications

### Admin Model
Belongs to Devise for authentication with database_authenticatable, recoverable, rememberable, validatable, trackable, and lockable modules enabled.

Has many events (restrict deletion if events exist).
Has many reviewed_applications through the VisaLetterApplication model.
Has many activity_logs.

Should have a full_name method that combines first_name and last_name.

### Event Model
Belongs to admin (the creator).
Has one letter_template (optional custom template).
Has many visa_letter_applications.
Has many participants through visa_letter_applications.
Has Active Storage attachments for letterhead_image and signature_image.

Validations: name, slug, venue_name, venue_address, city, country, start_date, end_date, and contact_email are all required. Slug must be unique and contain only lowercase letters, numbers, and hyphens. End date must be after start date. Application deadline must be before start date if provided.

Should auto-generate slug from name on creation.

Key methods needed:
- accepting_applications? returns true if active, applications_open, and deadline hasn't passed
- effective_letter_template returns the event's custom template if it exists and is active, otherwise returns the system default template
- full_address combines venue details into a single string
- date_range formats the start and end dates nicely

Scopes needed: active, accepting_applications, upcoming (start_date >= today), past (end_date < today).

### LetterTemplate Model
Belongs to event (optional - null means it's a global template).
Has Active Storage attachments for signature_image and letterhead_image.

Validations: name, body, signatory_name, and signatory_title are required. Only one template can be marked as default when event_id is null.

The body field should support these placeholder variables that get replaced when generating letters:
- participant_full_name
- participant_date_of_birth
- participant_country_of_birth
- participant_phone_number
- participant_address
- participant_email
- event_name
- event_venue
- event_address
- event_city
- event_country
- event_start_date
- event_end_date
- event_date_range
- reference_number
- current_date
- signatory_name
- signatory_title

Class method needed: default_template returns the template where is_default is true and event_id is null.

Instance method needed: render(application) takes a VisaLetterApplication and returns the body with all placeholders replaced with actual values.

### Participant Model
Has many visa_letter_applications.
Has many events through visa_letter_applications.

Validations: email (required, valid format), full_name (required), date_of_birth (required), country_of_birth (required), phone_number (required), full_street_address (required).

Key methods needed:
- email_verified? returns true if email_verified_at is present
- generate_verification_code! creates a random 6-digit code, saves it with current timestamp, resets attempt counter
- verify_code!(code) checks if code matches, isn't expired, and attempts haven't exceeded limit; if valid, sets email_verified_at and clears code; returns boolean
- verification_code_expired? returns true if code was sent more than 30 minutes ago
- can_resend_verification_code? returns true if no code sent yet or last code was sent more than 2 minutes ago

Email should be normalized to lowercase and stripped of whitespace before saving.

### VisaLetterApplication Model
Belongs to participant.
Belongs to event.
Belongs to reviewed_by (optional, Admin model).
Has one attached generated_letter (the PDF).
Has many activity_logs (polymorphic).

Valid statuses: pending_verification, pending_review, approved, rejected, letter_sent.

Validations: status required and must be one of valid statuses. Reference number required and unique. Participant can only have one application per event. Rejection reason required if status is rejected.

Status transitions:
- pending_verification can transition to pending_review (when email verified)
- pending_review can transition to approved or rejected (admin action)
- approved can transition to letter_sent (after PDF emailed)
- rejected can transition to pending_review (if resubmission allowed)

When transitioning to pending_review, set submitted_at to current time.
When transitioning to approved, set reviewed_at and trigger the PDF generation job.
When transitioning to rejected, set reviewed_at and send rejection notification email.
When transitioning to letter_sent, set letter_sent_at.

Reference number should be auto-generated on creation in format "HC-" followed by 8 random alphanumeric uppercase characters.

Key methods:
- can_be_reviewed? returns true if status is pending_review
- can_resend_letter? returns true if status is approved or letter_sent

Scopes needed for each status, plus awaiting_action (pending_verification or pending_review) and recent (ordered by created_at descending).

### ActivityLog Model
Belongs to trackable (polymorphic).
Belongs to admin (optional).

Valid actions: created, updated, submitted, verified, approved, rejected, letter_generated, letter_sent, letter_resent, viewed, exported.

Class method: log(trackable:, action:, admin:, metadata:, request:) creates a new log entry with the provided details, extracting IP and user agent from the request if provided.

---

## 5. Authentication and Authorization

### Admin Authentication
Use Devise with the following configuration:
- Session-based authentication
- Password minimum length of 12 characters
- Account lockout after 5 failed attempts, unlock after 1 hour or via email
- Password reset tokens expire after 6 hours
- Remember me functionality enabled

### Participant Verification
Participants do not have password-based accounts. Instead, they verify email ownership through a one-time 6-digit code. The application flow stores the application ID in the session after form submission, allowing the participant to complete verification and check status.

The verification code:
- Is exactly 6 digits (random number between 100000 and 999999)
- Expires after 30 minutes
- Can only be attempted 5 times before requiring a new code
- New code can only be requested after 2 minutes cooldown

### Authorization Rules
Use Pundit for authorization with these policies:

**Events:** Any admin can view and create. Only the creating admin or super_admins can update. Only super_admins can delete, and only if no applications exist.

**Applications:** Any admin can view and approve/reject. Only applications in pending_review status can be approved or rejected.

**Letter Templates:** Any admin can view. Only super_admins can modify the default template. Event-specific templates can be modified by the event creator or super_admins.

**Admins:** Only super_admins can create, modify, or delete admin accounts.

---

## 6. Routes Structure

### Public Routes (No Authentication)

Root path displays list of active events accepting applications.

Events index and show pages (show uses slug parameter).

Application routes nested under events:
- new and create for the application form
- verify (GET) shows the verification code entry form
- verify (POST) submits the verification code
- resend_code (POST) sends a new verification code

Application status page accessible via reference number without authentication.

Health check endpoint for monitoring.

### Admin Routes (Require Admin Authentication)

All admin routes should be namespaced under /admin.

Admin dashboard as the admin root.

Full CRUD for events, with nested routes for:
- Letter template management (new, create, edit, update, destroy)
- Application listing filtered by event

Applications management:
- Index with filtering and search
- Show with full details
- Approve action (POST)
- Reject action (POST)
- Resend letter action (POST)
- Export action (GET) for CSV/Excel download

Letter templates:
- Index of all templates
- Show and edit for templates
- Preview action to see rendered sample

Default letter template:
- Show, edit, update for the system default

Admin user management (super_admin only):
- Full CRUD for admin accounts
- Toggle super_admin status

Activity logs:
- Index with filtering
- Show for details

Settings page for system configuration.

---

## 7. Controller Specifications

### Public Controllers

**HomeController**
Index action: Fetch active events that are accepting applications, ordered by start date. Render the homepage with event listing.

**EventsController**
Index action: Fetch all active upcoming events. Show action: Find event by slug, ensure it's active, display event details.

**ApplicationsController**
Before actions: Set event from slug, check if applications are open.

New action: Initialize empty participant and application objects for the form.

Create action: 
1. Find existing participant by email or initialize new one
2. Update participant with submitted attributes
3. Build new visa_letter_application for this event
4. In a transaction, save participant and application
5. Generate verification code
6. Store application ID in session
7. Send verification email
8. Redirect to verify page
9. Handle duplicate application errors gracefully

Verify action (GET): Ensure current application exists in session, load participant, render verification form.

Submit_verification action (POST):
1. Ensure current application exists
2. Check if code is expired
3. Attempt to verify code
4. If successful, transition application to pending_review, log activity, redirect to status page
5. If failed, show error with remaining attempts

Resend_code action: Check cooldown period, generate new code, send email, redirect back with message.

**ApplicationStatusController**
Show action: Find application by reference number, display current status and details.

### Admin Controllers

**Admin::BaseController**
Set up as parent for all admin controllers. Include Pundit authorization. Use admin layout. Require admin authentication. Handle authorization errors with redirect.

**Admin::DashboardController**
Index action: Gather statistics (pending count, approved today, active events, total applications). Fetch recent pending applications. Fetch recent activity logs.

**Admin::EventsController**
Standard CRUD actions with Pundit authorization. Index uses policy_scope. Create assigns current_admin as the event creator. Destroy checks for existing applications.

**Admin::ApplicationsController**
Index action: Fetch applications with filtering by status, event, date range. Support search by reference number or participant name. Paginate results.

Show action: Load application with participant and event. Log view activity.

Approve action:
1. Authorize the action
2. Transition status to approved
3. Add admin notes if provided
4. Set reviewed_by to current admin
5. Log activity
6. Background job will handle PDF generation and email
7. Redirect with success message

Reject action:
1. Authorize the action
2. Require rejection reason
3. Transition status to rejected
4. Set reviewed_by to current admin
5. Log activity
6. Send rejection email
7. Redirect with confirmation

Resend_letter action:
1. Authorize
2. Queue PDF generation job
3. Log activity
4. Redirect with confirmation

Export action: Generate CSV of applications based on current filters.

**Admin::LetterTemplatesController**
Index: List all templates grouped by default and event-specific.
Show/Edit/Update: Standard actions with authorization.
Preview: Render template with sample data to show how it will look.

**Admin::DefaultLetterTemplateController**
Singular resource controller for managing the system default template. Restrict to super_admins.

**Admin::AdminsController**
Full CRUD for admin accounts. Restrict all actions to super_admins. Prevent admins from deleting themselves.

---

## 8. View Specifications

### Layouts

**Application Layout (Public)**
Clean, minimal design with Hack Club branding. Header with logo and navigation. Footer with contact information. Flash message display area. Main content area.

**Admin Layout**
Sidebar navigation with links to: Dashboard, Events, Applications, Letter Templates, Admins (if super_admin), Activity Logs. Top bar with current admin name and logout. Flash message display. Main content area.

### Public Views

**Home/Index**
Hero section with app title and brief description. List of active events as cards showing: event name, dates, location, deadline. Each card links to event detail page. Message if no events are currently accepting applications.

**Events/Show**
Event header with name and dates. Full description. Venue details with address. Application deadline if set. "Apply for Visa Letter" button if accepting applications, otherwise message about applications being closed.

**Applications/New**
Event name displayed prominently. Form with all required fields:
- Full Name (text field with note about matching passport)
- Date of Birth (date picker)
- Country of Birth (dropdown with country list)
- Phone Number (text field with format hint)
- Full Street Address (textarea)
- Email Address (email field)

Submit button. Clear validation error display. Privacy notice about data usage.

**Applications/Verify**
Display email address that code was sent to (partially masked). 6-digit code input field (consider individual boxes for each digit). Submit button. "Resend Code" link with cooldown indication. Message about code expiration time.

**Application Status/Show**
Reference number displayed prominently. Current status with visual indicator (icon and color). Status-specific messaging:
- Pending Verification: prompt to check email
- Pending Review: application is being reviewed
- Approved: letter has been/will be sent
- Rejected: reason displayed, contact information
- Letter Sent: confirmation with date

Summary of submitted information. Link to event page.

### Admin Views

**Dashboard/Index**
Statistics cards: pending applications count, approved today, active events, total applications. Quick actions panel. Recent pending applications table with approve/reject buttons. Recent activity feed.

**Events/Index**
Table with: name, dates, location, application count, status toggles. Create new event button. Filter by active/inactive, upcoming/past.

**Events/Show**
Full event details. Application statistics by status. Link to manage letter template. Link to view all applications for this event.

**Events/Form (New/Edit)**
All event fields organized in logical sections: Basic Info (name, description), Dates (start, end, deadline), Location (venue, address, city, country), Settings (active, applications open, contact email). File uploads for letterhead and signature images.

**Applications/Index**
Filters: status dropdown, event dropdown, date range picker, search box. Table with: reference number, participant name, event, submitted date, status, actions. Bulk action support for approve/reject. Export button. Pagination.

**Applications/Show**
Two-column layout. Left column: participant details (all submitted fields). Right column: application metadata (reference number, status, dates, reviewed by). Admin notes text area. Action buttons based on status (Approve, Reject, Resend Letter). Activity timeline showing all logged actions.

**Letter Templates/Index**
Section for default template with edit link. List of event-specific templates with event name and edit links.

**Letter Templates/Form**
Template name field. Rich text editor for body with placeholder variable insertion buttons. Signatory name and title fields. File uploads for signature and letterhead. Preview button that opens modal with rendered sample.

---

## 9. Service Objects

### VerificationCodeService
Responsibilities: Generate secure random 6-digit codes. Send verification emails. Track send attempts.

Methods:
- generate_and_send(participant): creates code, saves to participant, queues email
- verify(participant, code): validates code, handles expiration and attempt limits

### LetterTemplateRenderer
Responsibilities: Replace placeholder variables in template body with actual values from application data.

Initialize with template and application.
Method render returns the processed text with all variables replaced.

Handle missing or nil values gracefully with appropriate defaults or blank strings.

### PdfGeneratorService
Responsibilities: Create professional PDF visa letters using Prawn.

Initialize with a visa_letter_application.

Method generate returns the PDF as binary data.

PDF specifications:
- A4 page size
- Professional margins (at least 1 inch)
- Letterhead image at top if available
- Current date right-aligned
- "To Whom It May Concern" or appropriate salutation
- Letter body from rendered template
- Signatory name and title
- Signature image if available
- Reference number in footer
- Page numbers if multiple pages

### ApplicationApprovalService
Responsibilities: Orchestrate the approval process.

Method call(application, admin, notes):
1. Validate application can be approved
2. Update application status to approved
3. Set reviewed_by and reviewed_at
4. Save admin notes
5. Log the activity
6. Queue PDF generation job
7. Return success/failure result

### ApplicationRejectionService
Similar to approval service but:
1. Require rejection reason
2. Update status to rejected
3. Queue rejection notification email

### ApplicationExportService
Responsibilities: Generate CSV exports of applications.

Accept filter parameters.
Return CSV with columns: reference number, participant name, email, event name, status, submitted date, reviewed date, reviewed by.

---

## 10. Background Jobs

### SendVerificationEmailJob
Queue: default
Arguments: participant_id

Fetches participant, sends ApplicationMailer.verification_code email.
Handle participant not found gracefully.

### GenerateAndSendLetterJob
Queue: default
Arguments: application_id

Steps:
1. Fetch application with participant and event
2. Get effective letter template
3. Render template with application data
4. Generate PDF using PdfGeneratorService
5. Attach PDF to application record using Active Storage
6. Update letter_generated_at timestamp
7. Send ApplicationMailer.visa_letter_approved email with PDF attachment
8. Update status to letter_sent
9. Log activity

Implement retry logic for transient failures.

### SendRejectionNotificationJob
Queue: default
Arguments: application_id

Fetches application, sends ApplicationMailer.application_rejected email.

### CleanupExpiredVerificationCodesJob
Queue: low
Schedule: Run daily

Find all participants with verification codes older than 24 hours that haven't been verified. Clear their verification codes.

---

## 11. Email Specifications

### ApplicationMailer

**verification_code**
To: participant email
Subject: "Your Hack Club Visa Letter Verification Code"
Body: Greeting with participant name. The 6-digit code prominently displayed. Note that code expires in 30 minutes. Instructions not to share the code. Link to verification page.

**visa_letter_approved**
To: participant email
Subject: "Your Hack Club Visa Letter is Ready - [Event Name]"
Body: Greeting with participant name. Confirmation that visa letter has been approved. Event details summary. PDF letter attached. Instructions for using the letter. Contact information for questions.
Attachment: The generated PDF letter

**application_rejected**
To: participant email
Subject: "Update on Your Hack Club Visa Letter Application"
Body: Greeting with participant name. Notification that application was not approved. Rejection reason provided by admin. Information about next steps or who to contact. Supportive closing.

**application_submitted**
To: participant email
Subject: "Visa Letter Application Received - [Event Name]"
Body: Confirmation of submission. Reference number for tracking. Expected timeline for review. Link to status page.

### AdminMailer

**new_application_notification**
To: event contact email and/or all admins
Subject: "New Visa Letter Application - [Event Name]"
Body: Notification of new pending application. Participant name and event. Link to review in admin dashboard.

**daily_summary** (optional)
To: all admins
Subject: "Daily Visa Letter Application Summary"
Body: Count of new applications. Count of pending applications. Count of approved/rejected today. Link to dashboard.

---

## 12. Letter Template Default Content

The system should be seeded with a default letter template. The content should be a formal invitation letter suitable for visa applications, including:

Opening with organization letterhead.

Current date.

Formal salutation.

Body paragraphs that include:
- Statement that Hack Club is inviting the participant
- Participant's full name, date of birth, and country of birth
- Event name, dates, and location
- Purpose of the event (technology education, hackathon, etc.)
- Confirmation that participant will be attending
- Statement that Hack Club will not be financially responsible for the participant (standard visa letter requirement)
- Contact information for verification

Closing with signatory name, title, and signature.

Reference number in footer for verification purposes.

---

## 13. Validation Rules Summary

### Participant Form Validations
- Full Name: Required, minimum 2 characters, maximum 200 characters
- Date of Birth: Required, must be a valid date, participant must be at least 13 years old
- Country of Birth: Required, must be from valid country list
- Phone Number: Required, reasonable format validation allowing international formats
- Full Street Address: Required, minimum 10 characters
- Email: Required, valid email format

### Event Validations
- Name: Required, maximum 255 characters
- Slug: Required, unique, lowercase alphanumeric and hyphens only
- Venue Name: Required
- Venue Address: Required
- City: Required
- Country: Required
- Start Date: Required, must be a valid date
- End Date: Required, must be after start date
- Application Deadline: If provided, must be before start date
- Contact Email: Required, valid email format

### Letter Template Validations
- Name: Required, maximum 255 characters
- Body: Required, minimum 100 characters
- Signatory Name: Required
- Signatory Title: Required
- Only one default template allowed (when event_id is null)

---

## 14. Testing Requirements

### Model Tests
Test all validations for each model.
Test all associations.
Test all instance methods.
Test all class methods and scopes.
Test state transitions for VisaLetterApplication.
Test reference number generation uniqueness.
Test verification code logic (generation, verification, expiration, attempt limits).

### Controller Tests
Test all public routes are accessible.
Test admin routes require authentication.
Test authorization rules are enforced.
Test successful form submission flow.
Test validation error handling.
Test status transitions through controller actions.

### Service Tests
Test VerificationCodeService generates valid codes.
Test LetterTemplateRenderer replaces all variables correctly.
Test PdfGeneratorService produces valid PDFs.
Test approval and rejection services perform all required steps.

### System/Integration Tests
Complete participant flow from event selection to receiving approved letter.
Complete admin flow for reviewing and approving an application.
Email verification flow including error cases.
Admin event creation and template management.

### Job Tests
Test jobs perform their intended actions.
Test jobs handle missing records gracefully.
Test retry logic for transient failures.

---

## 15. Environment Variables Required

### Database
DATABASE_URL: PostgreSQL connection string

### Redis
REDIS_URL: Redis connection string for Sidekiq

### Email (SMTP)
SMTP_ADDRESS: Mail server address
SMTP_PORT: Mail server port
SMTP_USERNAME: Authentication username
SMTP_PASSWORD: Authentication password
SMTP_DOMAIN: Domain for HELO
MAIL_FROM_ADDRESS: Default sender email

### Application
SECRET_KEY_BASE: Rails secret key
RAILS_ENV: Environment name
HOST_URL: Application URL for email links
RAILS_SERVE_STATIC_FILES: Set to true if not using CDN

### Storage (if using cloud storage)
AWS_ACCESS_KEY_ID or equivalent
AWS_SECRET_ACCESS_KEY or equivalent
AWS_BUCKET or equivalent
AWS_REGION or equivalent

---

## 16. Seed Data Requirements

### Default Admin
Create one super_admin account with configurable email and password for initial setup.

### Default Letter Template
Create the system default letter template with professional visa invitation letter content. Include all standard placeholder variables.

### Sample Countries List
Include a comprehensive list of countries for the country of birth dropdown.

### Development Seeds
In development environment, also create:
- Several sample events (upcoming, past, closed for applications)
- Sample participants and applications in various statuses
- Sample activity logs

---

## 17. Security Considerations

### Data Protection
- Store all personal information encrypted at rest (database encryption)
- Use HTTPS for all traffic
- Sanitize all user inputs
- Use parameterized queries (Rails default)
- Set secure headers (Content-Security-Policy, X-Frame-Options, etc.)

### Authentication Security
- Strong password requirements for admins
- Account lockout after failed attempts
- Secure session management
- CSRF protection enabled

### Verification Code Security
- Codes expire after 30 minutes
- Limited attempts before code is invalidated
- Rate limiting on code requests
- Codes are single-use

### File Security
- Validate file types for uploads
- Limit file sizes
- Store uploaded files securely
- Generate signed URLs for PDF access

### Audit Trail
- Log all sensitive operations
- Track admin actions with IP addresses
- Maintain activity history for applications

---

## 18. Deployment Notes

### Prerequisites
- Ruby 3.2+ installed
- PostgreSQL 15+ running
- Redis running
- SMTP server access

### Deployment Steps
1. Clone repository
2. Install dependencies with bundle install
3. Set all environment variables
4. Run database migrations
5. Run database seeds
6. Precompile assets
7. Start Sidekiq workers
8. Start Rails server

### Process Management
Run both the Rails web server and Sidekiq worker processes. In production, use a process manager like systemd or a platform-provided process management system.

### Monitoring Recommendations
- Set up health check endpoint monitoring
- Monitor Sidekiq queue depths
- Set up error tracking (Sentry, Honeybadger, etc.)
- Monitor email delivery rates
- Database performance monitoring

---

## 19. Future Enhancement Considerations

These features are not part of the initial implementation but should be kept in mind for architecture decisions:

- Multiple letter templates per event (different languages)
- Bulk import of participants from CSV
- Webhook notifications for status changes
- API endpoints for external integrations
- Multi-language support for the interface
- SMS verification as alternative to email
- Digital signature integration
- Embassy-specific letter format variations

---

## 20. File Structure Summary

The application should follow standard Rails conventions:

- app/controllers/ - All controllers organized by namespace
- app/models/ - All ActiveRecord models
- app/views/ - View templates organized by controller
- app/services/ - Service objects for business logic
- app/jobs/ - Background job classes
- app/mailers/ - Email templates and logic
- app/policies/ - Pundit authorization policies
- app/helpers/ - View helpers
- app/assets/ - Stylesheets and JavaScript
- config/ - Application configuration
- db/migrate/ - Database migrations
- db/seeds.rb - Seed data
- spec/ - All test files mirroring app structure
