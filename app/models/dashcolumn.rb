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

class Dashcolumn
  attr_accessor :swimline, :status
  attr_accessor :main_issue

  def initialize(swimline, status, main_issue = nil)
    @swimline = swimline
    @status = status
    @main_issue = main_issue
  end

  def issues
    @issues = Array.new
    swimline.issues.each do |issue|
      if issue.status == status then @issues << issue end
    end
    return @issues
  end

  def issues_assigned_to(user)
    @assigned_issues = Array.new
    self.issues.each do |issue|
      if issue.assigned_to == user then @assigned_issues << issue end
    end
    return @assigned_issues
  end

  def height(filter = nil)
    issues = filter == "mine" ? self.issues_assigned_to(User.current) : self.issues

    (issues.length.to_f/2).round
  end

end
