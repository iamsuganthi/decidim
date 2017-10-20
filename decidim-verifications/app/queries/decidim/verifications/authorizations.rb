# frozen_string_literal: true

module Decidim
  module Verifications
    # Finds authorizations by different criteria
    class Authorizations < Rectify::Query
      # Initializes the class.
      #
      # @param name [String] The name of an authorization method
      # @param user [User] A user to find authorizations for
      # @param granted [Boolean] Whether the authorization is granted or not
      def initialize(user: nil, name: nil, granted: nil)
        @user = user
        @name = name
        @granted = granted
      end

      # Finds the Authorizations for the given method
      #
      # Returns an ActiveRecord::Relation.
      def query
        scope = Decidim::Authorization.where(nil)

        scope = scope.where(name: name) unless name.nil?
        scope = scope.where(user: user) unless user.nil?
        scope = scope.where(granted: granted) unless granted.nil?

        scope
      end

      private

      attr_reader :user, :name, :granted
    end
  end
end
