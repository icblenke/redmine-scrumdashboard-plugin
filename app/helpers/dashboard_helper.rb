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

module DashboardHelper

  def draw_columns(issuestatuses, sort = nil, reverse = nil)
    columnlength = 99 / issuestatuses.length
    columnlength = columnlength >= 16.5 ? 16.5 : columnlength
    i = 0
    html = ""
    issuestatuses.each do |status|
      html += "<div class=\'header\' style=\'width:#{columnlength}%;"
      if i != issuestatuses.length - 1 then html += "border-right: 1px solid #999;" end
      url_options = params
      url_options[:action] = 'update_selection'
      url_options[:sort] = status.id
      if sort == status.id.to_s && reverse == 0 then url_options[:reverse] = 1
      else url_options[:reverse] = 0 end
      html += "'>#{link_to_remote(status, {:update => 'dashboard', :url => url_options}, 
        {:href => 'javascript:void(0)', :title => l(:label_sort_by, status)})}"
      if sort == status.id.to_s
        if reverse == 0 then html += " #{image_tag('sort_desc.png')}"
        else html += " #{image_tag('sort_asc.png')}" end
      end
      html += "</div>\n"
      i += 1
    end
    return html
  end

  def draw_issue(issue, parent_id, maintrackers, col, dashboard, filter)
    allowed_statuses = issue.new_statuses_allowed_to(User.current) & dashboard.project_statuses - [issue.status]
    draggable = allowed_statuses.length > 0
    dbtracker = DashboardTracker.find(:first, 
      :conditions => ["dashboard_id = ? AND tracker_id = ?",dashboard.id,issue.tracker.id])
    divclass = draggable ? " draggable" : ""
    html = "<div class='db_issue#{divclass}' style='background-color:#{dbtracker.bgcolor}' 
      id='issue-#{parent_id}-#{issue.id}-#{col}-#{filter}'"
    # Display tooltip.
    html += "onmouseover='tooltip(\"" +
      "<b>#{issue}</b><br/>" +
      issue.description.gsub(/\r\n/, "<br/>")+"<br/>" +
      "<b>#{l(:field_start_date)}:</b> #{format_date(issue.start_date)}<br/>" +
      "<b>#{l(:field_due_date)}:</b> #{format_date(issue.due_date)}<br/>" +
      "<b>#{l(:field_assigned_to)}:</b> #{issue.assigned_to}<br/>" +
      "<b>#{l(:field_priority)}:</b> #{issue.priority.name}" +
      "\");' onmouseout='closetooltip();'>"
    html += link_to("##{issue.id}: #{issue.subject}", {:controller => 'issues', 
      :action => 'show', :id => issue}, {"style" => "color:#{dbtracker.textcolor}", "onmousedown" => "wasdragged = false;", 
      "onmouseup" => "if(wasdragged){this.href='javascript:void(0)';}"})
    html += "</div>"
    if draggable then html += draggable_element("issue-#{parent_id}-#{issue.id.to_s}-#{col}-#{filter}", :revert => true) end
    return html
  end

  def draw_content(column, col, length, height, maintrackers, last = nil, filter = nil)
    issue = column.swimline.main_issue
    dashboard = column.swimline.dashboard
    divclass = col == 1 ? 'content-1' : 'content-2'
    if request.user_agent.index('MSIE') then divclass += 'b' end
    html_start = "<div class='column #{divclass}' style='width:#{length}%;height:#{height}px;"
    if !last then html_start += "border-right: 1px solid #999;" end
    html_start += "' id='drop-#{issue.id.to_s}-#{column.status.id.to_s}'>"
    html_end = "</div>"
    html_end += drop_receiving_element "drop-#{issue.id.to_s}-#{column.status.id.to_s}",
      :url => { :action => "update", :where => column.status.id.to_s, :drop => issue.id.to_s,
      :version => @version }, 
      :hoverclass => "hover",
      :before => "Element.hide(element)"
    html = ""
    column.issues.each do |i|
      if filter != "mine" || i.assigned_to == User.current
        html += draw_issue(i, issue.id, maintrackers, col, dashboard, filter)
      end
    end
    html = html_start + html + html_end
    return html
  end

  def draw_frame(issue, &block)
    html_start = "<div class='frame' style='clear:both;' id='frame-#{issue.id}'>"
    html_end = "</div>"
    html = html_start + capture(&block) + html_end
    concat(html, block.binding)
  end

  def add_observer
    javascript_tag "Draggables.addObserver({
      onStart: function(eventName, draggable, event) {
        var content = draggable.element.id;
        var url = '/dashboard/visualise_workflow?do=true&issue='+encodeURIComponent(content);
        new Ajax.Request(url, { asynchronous:true, evalScripts:true, method:'get' }); 
      },
      onDrag: function(eventName, draggable, event) { closetooltip(); wasdragged = true; },
      onEnd: function(eventName, draggable, event) {
        var content = draggable.element.id;
        var url = '/dashboard/visualise_workflow?issue='+encodeURIComponent(content);
        new Ajax.Request(url, { asynchronous:true, evalScripts:true, method:'get' });      
      }
    });"
  end

  def administration_settings_tabs
    tabs = [{:name => 'Tracker', :partial => 'tracker', :label => 'label_tracker'},
            {:name => 'Status', :partial => 'status', :label => 'label_dashboard_status'},
            ]
  end

  def default_colors
    colors = [{:name => l(:dashboard_color_custom), :bgcolor => '', :textcolor => ''},
                {:name => l(:dashboard_color_yellow), :bgcolor => '#FFFF00', :textcolor => '#2A5685'},
                {:name => l(:dashboard_color_white), :bgcolor => '#FFFFFF', :textcolor => '#2A5685'},
                {:name => l(:dashboard_color_khaki), :bgcolor => '#F0E68C', :textcolor => '#000000'},
                {:name => l(:dashboard_color_lawngreen), :bgcolor => '#7CFC00', :textcolor => '#000000'},
                {:name => l(:dashboard_color_sgilightblue), :bgcolor => '#7D9EC0', :textcolor => '#000000'},
                {:name => l(:dashboard_color_black), :bgcolor => '#000000', :textcolor => '#00FF00'},
                {:name => l(:dashboard_color_lightcoral), :bgcolor => '#F08080', :textcolor => '#000000'},
                {:name => l(:dashboard_color_skyblue), :bgcolor => '#87CEEB', :textcolor => '#000000'},
                {:name => l(:dashboard_color_lightsteelblue), :bgcolor => '#B0C4DE', :textcolor => '#000000'},
                {:name => l(:dashboard_color_yellowgreen), :bgcolor => '#9ACD32', :textcolor => '#000000'}
                ]
  end

end
