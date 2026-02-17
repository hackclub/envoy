class ManualInvitationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def new?
    user.present?
  end

  def create?
    user.present?
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
