module RideRequestMutate
  module Concerns
    module HasOrganizationOptions
      extend ActiveSupport::Concern
      include Memery

      private

      memoize def organization_options
        @organizations.map {|org| [ org.name, org.id ] }.freeze
      end
    end
  end
end
