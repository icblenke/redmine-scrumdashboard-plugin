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

class DashboardTracker < ActiveRecord::Base
  belongs_to :dashboard
  belongs_to :tracker

  validates_presence_of :maintracker
  validates_presence_of :bgcolor
  validates_presence_of :textcolor

  def set_as_maintracker
    self.write_attribute(:maintracker, 1)
    self.save!
  end

  def remove_maintracker
    self.write_attribute(:maintracker, 0)
    self.save!
  end

  def bgcolor=(bgcolor)
    self.write_attribute(:bgcolor, bgcolor)
    self.save!
  end

  def textcolor=(textcolor)
    self.write_attribute(:textcolor, textcolor)
    self.save!
  end

end
