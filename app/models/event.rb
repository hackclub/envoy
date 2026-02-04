class Event < ApplicationRecord
  belongs_to :admin
  has_one :letter_template, dependent: :destroy
  has_many :visa_letter_applications, dependent: :restrict_with_error
  has_many :participants, through: :visa_letter_applications

  validate :rejection_reason_templates_format
  validates :name, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/, message: "must contain only lowercase letters, numbers, and hyphens" }
  validates :venue_name, presence: true
  validates :venue_address, presence: true
  validates :city, presence: true
  validates :country, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :contact_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validate :end_date_after_start_date
  validate :application_deadline_before_start_date

  before_validation :generate_slug, on: :create

  scope :active, -> { where(active: true) }
  scope :accepting_applications, -> { active.where(applications_open: true).where("application_deadline IS NULL OR application_deadline > ?", Time.current) }
  scope :upcoming, -> { where("start_date >= ?", Date.current) }
  scope :past, -> { where("end_date < ?", Date.current) }

  def accepting_applications?
    active? && applications_open? && (application_deadline.nil? || application_deadline > Time.current)
  end

  def effective_letter_template
    template = letter_template if letter_template&.active?
    template || LetterTemplate.default_template
  end

  def full_address
    [ venue_name, venue_address, city, country ].compact.join(", ")
  end

  def date_range
    if start_date.year == end_date.year
      if start_date.month == end_date.month
        "#{start_date.strftime('%B %d')} - #{end_date.strftime('%d, %Y')}"
      else
        "#{start_date.strftime('%B %d')} - #{end_date.strftime('%B %d, %Y')}"
      end
    else
      "#{start_date.strftime('%B %d, %Y')} - #{end_date.strftime('%B %d, %Y')}"
    end
  end

  def rejection_reason_templates_list
    rejection_reason_templates.presence || []
  end

  def add_rejection_reason_template(reason)
    return false if reason.blank?
    templates = rejection_reason_templates_list
    return false if templates.include?(reason)
    update(rejection_reason_templates: templates + [ reason ])
  end

  def remove_rejection_reason_template(reason)
    templates = rejection_reason_templates_list
    update(rejection_reason_templates: templates - [ reason ])
  end

  private

  def rejection_reason_templates_format
    return if rejection_reason_templates.blank?
    unless rejection_reason_templates.is_a?(Array) && rejection_reason_templates.all? { |r| r.is_a?(String) }
      errors.add(:rejection_reason_templates, "must be an array of strings")
    end
  end

  def generate_slug
    return if slug.present?
    return if name.blank?

    base_slug = name.parameterize
    self.slug = base_slug

    counter = 1
    while Event.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def end_date_after_start_date
    return unless start_date.present? && end_date.present?

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def application_deadline_before_start_date
    return unless application_deadline.present? && start_date.present?

    if application_deadline >= start_date.beginning_of_day
      errors.add(:application_deadline, "must be before start date")
    end
  end
end
