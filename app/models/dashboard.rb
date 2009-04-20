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

class Dashboard < ActiveRecord::Base
  belongs_to :project
  
  has_many :dashboard_trackers
  has_many :dashboard_statuses
  
  def swimlines(version, sort = nil, filter = nil)
    maintrackers = self.maintrackers
    if !version then return nil end
    userstories = Array.new
    version.fixed_issues.each do |fi|
      if maintrackers.include?(fi.tracker)
        userstories << fi
      elsif project_trackers.include?(fi.tracker)
        fi.relations_from.each do |ir|
          if maintrackers.include?(ir.issue_to.tracker) && !userstories.include?(ir.issue_to)
            userstories << ir.issue_to
          end
        end
        fi.relations_to.each do |ir|
          if maintrackers.include?(ir.issue_from.tracker) && !userstories.include?(ir.issue_from)
            userstories << ir.issue_from
          end
        end
      end
    end
    
    @swimlines = Array.new
    userstories.each do |us|
      sl = Swimline.new(us, self, version)
      if sl.issues.length > 0 then @swimlines << sl end
    end
        
    if sort && issues_in_version_has_status?(sort, version)
      @swimlines.sort! { |a,b| b.length_for_status(sort, filter) <=> a.length_for_status(sort, filter) }
    else
      @swimlines.sort! { |a,b| a.main_issue.id <=> b.main_issue.id }
    end
    
    return @swimlines
  end
  
  def project_trackers
    @project_trackers = Array.new
    dashboard_trackers.each do |dt|
      @project_trackers << dt.tracker
    end
    @project_trackers.uniq
  end
  
  def maintrackers
    @maintrackers = Array.new
    dashboard_trackers.each do |dt|
      if dt.maintracker == 1 then @maintrackers << dt.tracker end
    end
    @maintrackers.uniq
  end
  
  def project_statuses
    @project_statuses = Array.new
    dashboard_statuses.each do |ds|
      @project_statuses << ds.status
    end
    @project_statuses.uniq.sort! { |a,b| a.position <=> b.position }
  end
  
  def issues_in_version_has_status?(status, version)
    version.fixed_issues.each do |fi|
      if fi.status == status then return true end
    end
    return false
  end
  
  def issues_in_version_assigned_to(user, version)
    @assigned_issues = Array.new
    version.fixed_issues.each do |issue|
      if issue.assigned_to == user then @assigned_issues << issue end
    end
    return @assigned_issues
  end

end
