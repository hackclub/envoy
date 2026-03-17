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
        owned_event_ids = Event.where(admin_id: user.id).select(:id)
        collaborative_event_ids = EventAdmin.where(admin_id: user.id).select(:event_id)
        scope.where(event_id: owned_event_ids).or(scope.where(event_id: collaborative_event_ids))
      else
        scope.none
      end
    end
  end
end
