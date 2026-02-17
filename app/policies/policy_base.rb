class PolicyBase
  class NotAuthorizedError < StandardError; end

   attr_reader :current_user

   def initialize(current_user)
    @current_user = current_user
   end
end
