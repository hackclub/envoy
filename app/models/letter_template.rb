class LetterTemplate < ApplicationRecord
  belongs_to :event, optional: true

  has_one_attached :signature_image
  has_one_attached :letterhead_image

  validates :name, presence: true, length: { maximum: 255 }
  validates :body, presence: true, length: { minimum: 100 }
  validates :signatory_name, presence: true
  validates :signatory_title, presence: true

  validate :only_one_default_template

  scope :active, -> { where(active: true) }
  scope :global, -> { where(event_id: nil) }

  PLACEHOLDERS = %w[
    participant_full_name
    participant_date_of_birth
    participant_country_of_birth
    participant_phone_number
    participant_address
    participant_email
    event_name
    event_venue
    event_address
    event_city
    event_country
    event_start_date
    event_end_date
    event_date_range
    reference_number
    current_date
    signatory_name
    signatory_title
  ].freeze

  def self.default_template
    find_by(is_default: true, event_id: nil, active: true)
  end

  def render(application)
    participant = application.participant
    event = application.event

    result = body.dup

    replacements = {
      "{{participant_full_name}}" => participant.full_name,
      "{{participant_date_of_birth}}" => participant.date_of_birth.strftime("%B %d, %Y"),
      "{{participant_country_of_birth}}" => participant.country_of_birth,
      "{{participant_phone_number}}" => participant.phone_number,
      "{{participant_address}}" => participant.full_street_address,
      "{{participant_email}}" => participant.email,
      "{{event_name}}" => event.name,
      "{{event_venue}}" => event.venue_name,
      "{{event_address}}" => event.venue_address,
      "{{event_city}}" => event.city,
      "{{event_country}}" => event.country,
      "{{event_start_date}}" => event.start_date.strftime("%B %d, %Y"),
      "{{event_end_date}}" => event.end_date.strftime("%B %d, %Y"),
      "{{event_date_range}}" => event.date_range,
      "{{reference_number}}" => application.reference_number,
      "{{current_date}}" => Date.current.strftime("%B %d, %Y"),
      "{{signatory_name}}" => signatory_name,
      "{{signatory_title}}" => signatory_title
    }

    replacements.each do |placeholder, value|
      result.gsub!(placeholder, ERB::Util.html_escape(value.to_s))
    end

    result
  end

  private

  def only_one_default_template
    return unless is_default? && event_id.nil?

    existing = LetterTemplate.where(is_default: true, event_id: nil).where.not(id: id)
    if existing.exists?
      errors.add(:is_default, "can only be set for one global template")
    end
  end
end
