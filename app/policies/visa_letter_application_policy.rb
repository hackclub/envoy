class VisaLetterApplicationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def approve?
    user.present? && record.can_be_approved?
  end

  def reject?
    user.present? && record.can_be_rejected?
  end

  def regenerate_letter?
    user.present? && (record.approved? || record.letter_sent?)
  end

  def downgrade_rejection?
    user.present? && record.hard_rejected?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.super_admin?
        scope.all
      elsif user.present?
        scope.joins(:event).where(events: { admin_id: user.id })
      else
        scope.none
      end
    end
  end
end
