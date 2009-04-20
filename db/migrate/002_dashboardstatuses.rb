# Scrum dashboard plugin migration
# Use rake db:migrate_plugins to migrate installed plugins
class Dashboardstatuses < ActiveRecord::Migration
  def self.up
    create_table "dashboard_statuses" do |t|
      t.column "dashboard_id", :integer, :default => 0, :null => false
      t.column "status_id", :integer, :default => 0, :null => false
    end
    
    statuses = IssueStatus.find(:all)
    
    Dashboard.find(:all).each do |db|
      statuses.each do |s|
        DashboardStatus.create(:dashboard_id => db.id, :status_id => s.id)
      end
    end

  end

  def self.down
    drop_table :dashboard_statuses
  end
end
