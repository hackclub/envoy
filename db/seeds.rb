puts "Seeding database..."

admin = Admin.find_or_initialize_by(email: ENV.fetch("ADMIN_EMAIL", "admin@hackclub.com"))
admin.assign_attributes(
  first_name: ENV.fetch("ADMIN_FIRST_NAME", "Admin"),
  last_name: ENV.fetch("ADMIN_LAST_NAME", "User"),
  super_admin: true
)
admin.save!
puts "Created admin: #{admin.email} (will be linked on first Hack Club login)"

default_template_body = <<~TEMPLATE
  To Whom It May Concern,

  The Hack Foundation, doing business as Hack Club, is pleased to confirm that {{participant_full_name}} has been invited to attend {{event_name}}.

  Participant Information:
  Full Name: {{participant_full_name}}
  Date of Birth: {{participant_date_of_birth}}
  Country of Citizenship: {{participant_country_of_birth}}
  Email: {{participant_email}}
  Phone: {{participant_phone_number}}
  Address: {{participant_address}}

  Event Details:
  Event Name: {{event_name}}
  Event Dates: {{event_date_range}}
  Venue: {{event_venue}}
  Address: {{event_address}}, {{event_city}}, {{event_country}}

  Hack Club is a 501(c)(3) nonprofit organization (EIN: 81-2908499) that supports a global community of high school hackers and makers. We organize events, hackathons, and educational programs to help young people learn to code and build technology.

  {{participant_full_name}} is invited to participate in this event as an attendee. The participant is responsible for their own travel, accommodation, and living expenses during the event. Hack Club will not be financially responsible for the participant during their stay.

  This letter is issued solely for the purpose of supporting a visa application. If you require any additional information or verification, please contact us at the email address below.

  Sincerely,

  {{signatory_name}}
  {{signatory_title}}
  Hack Club / The Hack Foundation
  8605 Santa Monica Blvd #86294
  West Hollywood, CA 90069
  United States

  Email: letters@hackclub.com

  Reference Number: {{reference_number}}
  Date Issued: {{current_date}}
TEMPLATE

default_template = LetterTemplate.find_or_initialize_by(is_default: true, event_id: nil)
default_template.assign_attributes(
  name: "Default Visa Invitation Letter",
  body: default_template_body,
  signatory_name: "Zach Latta",
  signatory_title: "Executive Director",
  active: true
)
default_template.save!
puts "Created default letter template"

if Rails.env.development?
  puts "Creating development seed data..."

  upcoming_event = Event.find_or_create_by!(slug: "assemble-2026") do |e|
    e.name = "Assemble 2026"
    e.description = "Join us for the biggest high school hackathon of the year! Assemble brings together hundreds of teen hackers from around the world for a weekend of building, learning, and fun."
    e.venue_name = "Pier 48"
    e.venue_address = "1 Pier 48"
    e.city = "San Francisco"
    e.country = "United States"
    e.start_date = 3.months.from_now.to_date
    e.end_date = 3.months.from_now.to_date + 2.days
    e.application_deadline = 2.months.from_now
    e.contact_email = "assemble@hackclub.com"
    e.active = true
    e.applications_open = true
    e.admin = admin
  end
  puts "Created event: #{upcoming_event.name}"

  past_event = Event.find_or_create_by!(slug: "outernet-2025") do |e|
    e.name = "Outernet 2025"
    e.description = "An outdoor hacking adventure in the wilderness."
    e.venue_name = "Camp Navarro"
    e.venue_address = "13500 Navarro Bluff Rd"
    e.city = "Mendocino"
    e.country = "United States"
    e.start_date = 2.months.ago.to_date
    e.end_date = 2.months.ago.to_date + 4.days
    e.contact_email = "outernet@hackclub.com"
    e.active = false
    e.applications_open = false
    e.admin = admin
  end
  puts "Created event: #{past_event.name}"

  closed_event = Event.find_or_create_by!(slug: "epoch-2026") do |e|
    e.name = "Epoch 2026"
    e.description = "A New Year's hackathon celebration in India."
    e.venue_name = "Delhi Convention Center"
    e.venue_address = "Sector 25"
    e.city = "New Delhi"
    e.country = "India"
    e.start_date = 1.month.from_now.to_date
    e.end_date = 1.month.from_now.to_date + 2.days
    e.application_deadline = 1.week.ago
    e.contact_email = "epoch@hackclub.com"
    e.active = true
    e.applications_open = false
    e.admin = admin
  end
  puts "Created event: #{closed_event.name}"

  participant1 = Participant.find_or_create_by!(email: "alice@example.com") do |p|
    p.full_name = "Alice Johnson"
    p.date_of_birth = Date.new(2006, 5, 15)
    p.country_of_birth = "Canada"
    p.phone_number = "+1 416 555 0123"
    p.full_street_address = "123 Maple Street, Toronto, ON M5V 1A1, Canada"
    p.email_verified_at = 1.day.ago
  end

  app1 = VisaLetterApplication.find_or_create_by!(participant: participant1, event: upcoming_event) do |a|
    a.status = "pending_approval"
    a.submitted_at = 1.day.ago
  end
  puts "Created pending application: #{app1.reference_number}"

  participant2 = Participant.find_or_create_by!(email: "bob@example.com") do |p|
    p.full_name = "Bob Smith"
    p.date_of_birth = Date.new(2005, 3, 22)
    p.country_of_birth = "United Kingdom"
    p.phone_number = "+44 20 7123 4567"
    p.full_street_address = "45 Oxford Street, London, W1D 1BS, United Kingdom"
    p.email_verified_at = 3.days.ago
  end

  app2 = VisaLetterApplication.find_or_create_by!(participant: participant2, event: upcoming_event) do |a|
    a.status = "approved"
    a.submitted_at = 3.days.ago
    a.reviewed_by = admin
    a.reviewed_at = 2.days.ago
  end
  puts "Created approved application: #{app2.reference_number}"

  participant3 = Participant.find_or_create_by!(email: "carol@example.com") do |p|
    p.full_name = "Carol Williams"
    p.date_of_birth = Date.new(2007, 8, 10)
    p.country_of_birth = "Brazil"
    p.phone_number = "+55 11 98765 4321"
    p.full_street_address = "Rua Augusta 1234, São Paulo, SP 01310-100, Brazil"
  end

  app3 = VisaLetterApplication.find_or_create_by!(participant: participant3, event: upcoming_event) do |a|
    a.status = "pending_verification"
  end
  participant3.generate_verification_code!
  puts "Created pending verification application: #{app3.reference_number}"

  puts "Development seed data created!"
end

puts "Seeding complete!"
