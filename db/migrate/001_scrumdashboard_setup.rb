# Scrum dashboard plugin migration
# Use rake db:migrate_plugins to migrate installed plugins
class ScrumdashboardSetup < ActiveRecord::Migration
  def self.up
    create_table "dashboards" do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "maintracker_id", :integer
    end
    
    create_table "dashboard_trackers" do |t|
      t.column "dashboard_id", :integer, :default => 0, :null => false
      t.column "tracker_id", :integer, :default => 0, :null => false
    end
    
    Project.find(:all).each do |p|
      Dashboard.create(:project_id => p.id)
    end
    
    trackers = Tracker.find(:all)
    
    Dashboard.find(:all).each do |db|
      trackers.each do |t|
        DashboardTracker.create(:dashboard_id => db.id, :tracker_id => t.id)
      end
    end
        
  end

  def self.down
    drop_table :dashboards
    drop_table :dashboard_trackers
  end
end
