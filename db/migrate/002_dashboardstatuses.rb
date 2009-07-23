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

class Dashboardstatuses < ActiveRecord::Migration
  def self.up
    create_table "dashboard_statuses", :force => true do |t|
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
