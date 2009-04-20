# Scrum dashboard plugin migration
# Use rake db:migrate_plugins to migrate installed plugins
class MoreMaintrackers < ActiveRecord::Migration
  def self.up
    
    add_column :dashboard_trackers, :maintracker, :integer, :default => 0
    remove_column(:dashboards, :maintracker_id)
    
  end

  def self.down
    add_column :dashboards, :maintracker_id, :integer, :default => 0, :null => false
    remove_column(:dashboard_trackers, :maintracker)
  end
end
