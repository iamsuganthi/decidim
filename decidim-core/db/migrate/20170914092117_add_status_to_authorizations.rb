# frozen_string_literal: true

class AddStatusToAuthorizations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_authorizations,
               :granted,
               :boolean,
               default: true,
               null: false

    change_column_default :decidim_authorizations, :granted, false

    remove_index :decidim_authorizations, column: [:decidim_user_id, :name]

    add_index :decidim_authorizations,
              [:decidim_user_id, :name, :granted],
              name: "index_decidim_authorizations_on_user_name_and_status",
              unique: true
  end
end
