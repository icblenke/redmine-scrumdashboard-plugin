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
