module Locomotive
  class ContentAssetPolicy < ApplicationPolicy

    def index?
      true
    end

    def create?
      true
    end

    def update?
      true
    end

    def destroy?
      true
    end

  end
end
