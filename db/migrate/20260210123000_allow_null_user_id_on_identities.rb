# frozen_string_literal: true

class AllowNullUserIdOnIdentities < ActiveRecord::Migration[8.1]
  def change
    change_column_null :identities, :user_id, true
  end
end
