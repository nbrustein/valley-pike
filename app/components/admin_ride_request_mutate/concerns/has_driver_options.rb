module AdminRideRequestMutate
  module Concerns
    module HasDriverOptions
      extend ActiveSupport::Concern
      include Memery

      private

      memoize def driver_count_options
        [ [ "false", "1 Driver" ], [ "true", "Multiple Drivers" ] ].freeze
      end

      memoize def driver_gender_options
        [
          [ "none", "None" ],
          [ "female", "Female Driver" ],
          [ "female_accompaniment", "Female Accompaniment if Driver is Male" ],
        ].freeze
      end
    end
  end
end
