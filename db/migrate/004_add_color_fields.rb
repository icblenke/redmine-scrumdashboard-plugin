# Scrum dashboard plugin migration
# Use rake db:migrate_plugins to migrate installed plugins
class AddColorFields < ActiveRecord::Migration
  def self.up
    add_column :dashboard_trackers, :bgcolor, :string, :default => '#FFFF00'
    add_column :dashboard_trackers, :textcolor, :string, :default => '#2A5685'
  end

  def self.down
    remove_column(:dashboard_trackers, :bgcolor)
    remove_column(:dashboard_trackers, :textcolor)
  end
end
