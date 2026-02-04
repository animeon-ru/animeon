class Fixnullviolationindbmodifications < ActiveRecord::Migration[7.1]
  def change
    change_column :db_modifications, :new_data, :string, null: true
    change_column :db_modifications, :old_data, :string, null: true
  end
end
