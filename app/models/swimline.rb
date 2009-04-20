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

class Swimline
  attr_accessor :main_issue, :dashboard, :version

  def initialize(main_issue, dashboard, version)
    @main_issue = main_issue
    @dashboard = dashboard
    @version = version
  end

  def column_by_status(status)
    if dashboard.project_statuses.include?(status)
      main_issue = @main_issue.status == status ? @main_issue : nil
      return Dashcolumn.new(self, status, main_issue)
    else return nil end
  end

  def columns
    @columns = Array.new
    @dashboard.project_statuses.each do |ps|
      @columns << column_by_status(ps)
    end
    return @columns
  end

  def issues
    @issues = @dashboard.project_statuses.include?(main_issue.status) ? [main_issue] : Array.new
    main_issue.relations_from.each do |ir|
      if version.fixed_issues.include?(ir.issue_to) && !dashboard.maintrackers.include?(ir.issue_to.tracker) && @dashboard.project_statuses.include?(ir.issue_to.status) && @dashboard.project_trackers.include?(ir.issue_to.tracker)
        @issues << ir.issue_to
      end
    end
    main_issue.relations_to.each do |ir|
      if version.fixed_issues.include?(ir.issue_from) && !dashboard.maintrackers.include?(ir.issue_from.tracker) && @dashboard.project_statuses.include?(ir.issue_from.status) && @dashboard.project_trackers.include?(ir.issue_from.tracker)
        @issues << ir.issue_from
      end
    end
    @issues.uniq
  end

  def height(filter = nil)
    height = 0
    self.columns.each do |c|
      if @dashboard.project_statuses.include?(c.status) && c.height(filter) > height then height = c.height(filter) end
    end
    return height
  end

  def length_for_status(status, filter = nil)
    self.columns.each do |c|
      if c.status == status then return filter == "mine" ? c.issues_assigned_to(User.current).length : c.issues.length end
    end
    return nil
  end

  def issues_assigned_to(user)
    @assigned_issues = Array.new
    self.issues.each do |i|
      if i.assigned_to == user then @assigned_issues << i end
    end
    return @assigned_issues
  end

end
