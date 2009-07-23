# scrumDashboard - Add scrum functionality to any Redmine installation
# Copyright (C) 2009 BrokenTeam
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class ScrumdashboardSetup < ActiveRecord::Migration
  def self.up
    create_table "dashboards", :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "maintracker_id", :integer
    end
    
    create_table "dashboard_trackers", :force => true do |t|
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
