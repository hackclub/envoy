class ApiKeyPolicy < ApplicationPolicy
  def index?
    user.present? && user.super_admin?
  end

  def create?
    user.present? && user.super_admin?
  end

  def destroy?
    user.present? && user.super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.super_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
