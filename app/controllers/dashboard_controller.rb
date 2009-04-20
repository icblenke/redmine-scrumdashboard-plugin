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

class DashboardController < ApplicationController
  unloadable

  def index
    get_globals
  end

  def settings
    @project = Project.find(params[:id])
    @dashboard = Dashboard.find(:first, :conditions => ["project_id = ?", @project.id])
    @version = params[:version] ? Version.find(params[:version]) : @project.versions.sort.reverse.first
    @all_trackers = Tracker.find(:all)
    @all_statuses = IssueStatus.find(:all).sort! { |a,b| a.position <=> b.position }
    @project_trackers = @dashboard.project_trackers
    @project_statuses = @dashboard.project_statuses

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Update status of a selected issue.
  def update
    issue = Issue.find(params[:id].split("-")[2])
    old_status = issue.status
    dashboard = Dashboard.find(:first, :conditions => ["project_id = ?", issue.project.id])
    version = Version.find(params[:version])
    drop = params[:id].split("-")[1]
    col = params[:id].split("-")[3]
    filter = params[:id].split("-")[4]
    where = params[:where]
    requested_status = IssueStatus.find_by_id(where)
    allowed_statuses = issue.new_statuses_allowed_to(User.current)

    # Check that the user is allowed to update the status of the issue.
    if (allowed_statuses.include? requested_status)
      issue.update_attribute(:status_id, where)
      # Update the journal containing all the changes to the issue.
      journal = issue.init_journal(User.current)
      journal.details << JournalDetail.new(:property => 'attr',
                                      :prop_key => 'status_id',
                                      :old_value => old_status.id,
                                      :value => where)
      journal.save

    else
      # The user is not allowed to update the status. Override the requested status with the original.
      where = issue.status_id.to_s
      requested_status = IssueStatus.find_by_id(where)
    end
    swimline = Swimline.new(Issue.find(drop), dashboard, version)
    column = swimline.column_by_status(requested_status)

    render :update do |page|
      height = swimline.height(filter) * 55
      last = column.status == dashboard.project_statuses.last
      # Remove the issue from the dashboard and draw it to the new status.
      page.replace params[:id], ""
      page.replace_html("drop-"+drop+"-"+where, 
                        draw_content(column, col, 100, height, dashboard.maintrackers, last, filter))
      # Adjust the height of the frame to fit the new placement of issues.
      dashboard.project_statuses.each do |status|
        page << "$('drop-"+drop+"-"+status.id.to_s+"').morph('height: "+height.to_s+"px;');"
      end
    end
  end

  def update_settings
    @dashboard = Dashboard.find(params[:id])
    db = params[:dashboard]
    @dashboard.update_attributes(params[:dashboard])

    new = params[:new_ids] ? params[:new_ids] : Array.new
    old = params[:old_ids] ? params[:old_ids] : Array.new
    new_ids = Array.new(new-old)
    old_ids = Array.new(old-new)

    if params[:change] == "Status" && old_ids.include?(session[:sort][:status]) 
      then session[:sort] = { :status => nil, :reverse => nil } end

    # Update trackers and statuses included on the dashboard.
    old_ids.each do |oid|
      if params[:change] == "Tracker"
        dtracker = DashboardTracker.find(:first, :conditions => ["dashboard_id = ? AND tracker_id = ?", 
          @dashboard.id, oid.to_i])
        DashboardTracker.delete(dtracker.id)
      else
        dstatus = DashboardStatus.find(:first, :conditions => ["dashboard_id = ? AND status_id = ?",
          @dashboard.id, oid.to_i])
        DashboardStatus.delete(dstatus.id)
      end
    end

    new_ids.each do |nid|
      if params[:change] == "Tracker"
        DashboardTracker.create(:dashboard_id => @dashboard.id) do |dt|
          dt.tracker_id = nid.to_i
        end
      else
        DashboardStatus.create(:dashboard_id => @dashboard.id) do |ds|
          ds.status_id = nid.to_i
        end
      end
    end

    # Update tracker colors and maintrackers
    if params[:change] == "Tracker"
      maintrackers_new = params[:tracker_ids] ? params[:tracker_ids] : Array.new
      maintrackers_old = params[:old_tracker_ids] ? params[:old_tracker_ids] : Array.new
      new_ids = Array.new(maintrackers_new-maintrackers_old)
      old_ids = Array.new(maintrackers_old-maintrackers_new)

      old_ids.each do |oid|
        dtracker = DashboardTracker.find(:first, :conditions => ["dashboard_id = ? AND tracker_id = ?", 
          @dashboard.id, oid.to_i])
        dtracker.remove_maintracker unless !dtracker
      end

      new_ids.each do |nid|
        dtracker = DashboardTracker.find(:first, :conditions => ["dashboard_id = ? AND tracker_id = ?", 
          @dashboard.id, nid.to_i])
        dtracker.set_as_maintracker
      end

      if params[:textcolor]
        params[:textcolor].each do |key, value|
          if params[:new_ids].include?(key)
            dtracker = DashboardTracker.find(:first, :conditions => ["dashboard_id = ? AND tracker_id = ?",
              @dashboard.id, key.to_i])
            dtracker.textcolor = value != "" ? value : dtracker.textcolor = "#2A5685"
          end
        end
      end

      if params[:bgcolor]
        params[:bgcolor].each do |key, value|
          if params[:new_ids].include?(key)
            dtracker = DashboardTracker.find(:first, :conditions => ["dashboard_id = ? AND tracker_id = ?",
              @dashboard.id, key.to_i])
            dtracker.bgcolor = value != "" ? value : dtracker.bgcolor = "yellow"
          end
        end
      end
    end

    flash[:notice] = l(:notice_successful_update)
    redirect_to :action => 'settings', :id => @dashboard.project, :tab => params[:change], :version => params[:version]
  end

  def update_selection
    get_globals
    render :partial => '/dashboard/dashboard'
  end

  # Visualise the user's workflow during dragging.
  def visualise_workflow
    # We decided to not use any more time trying to get this to work with IE since our customer didn't prioritize it.
    # The reason this doesnt work in IE is because of a bug with z-index.
    if !request.user_agent.index('MSIE')
      issue = Issue.find(params[:issue].split("-")[2])
      parent = Issue.find(params[:issue].split("-")[1])
      dashboard = Dashboard.find(:first, :conditions => ["project_id = ?", issue.project.id])
      # The original background color of the status.
      returncolor = params[:issue].split("-")[3] == "1" ? "#EEE" : "#FFF"
      project_statuses = dashboard.project_statuses
      allowed_statuses = issue.new_statuses_allowed_to(User.current) & project_statuses

      render :update do |page|
        project_statuses.each do |s|
          # Make sure that only the allowed statuses are visualised.
          if (s == allowed_statuses[0])
            bgcolor = params[:do] ? "#C6EAC3" : returncolor
            allowed_statuses.shift
          else
            bgcolor = returncolor
          end
          # Change the background color of the selected status to visualise the workflow.
          page << "$('drop-"+parent.id.to_s+"-"+s.id.to_s+"').morph('background-color:"+bgcolor+";', {duration: 0});"
        end
      end
    end
  end

private
  def get_globals
    if session[:sort].nil? then session[:sort] = { :status => nil, :reverse => nil } end

    if params[:sort] then session[:sort][:status] = params[:sort] end
    if params[:reverse] then session[:sort][:reverse] = params[:reverse].to_i end
    @project = Project.find(params[:id])
    @sort = session[:sort][:status]
    @reverse = session[:sort][:reverse]

    @dashboard = Dashboard.find(:first, :conditions => ["project_id = ?", @project.id])
    if !@dashboard
      @dashboard = Dashboard.create(:project_id => @project.id)
    end

    @issuestatuses = @dashboard.project_statuses
    @versions = @project.versions.sort
    @version = params[:version_id] ? Version.find(params[:version_id]) : @versions.reverse.first

    @filter = params[:filter] ? params[:filter] : "all"
    @swimlines = @sort ? @dashboard.swimlines(@version, IssueStatus.find(@sort), @filter) : @dashboard.swimlines(@version)
    if @reverse == 1 && !@swimlines.nil? then @swimlines.reverse! end

  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
