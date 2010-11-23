class RequirementsController < RedmineReController
  unloadable

  include ActionView::Helpers::PrototypeHelper
  include ActionView::Helpers::JavaScriptHelper


  def index
    @artifacts  = ReArtifactProperties.find_all_by_project_id(@project.id)
    @artifacts = [] if @artifacts == nil

    @htmltree = '<ul id="tree">'
    for artifact in @artifacts
      if (artifact.parent.nil?)
        render_to_html_tree(artifact)
      end
    end
    @htmltree += '</ul>'
  end

  ##
  # The following method is called via JavaScript Tree by an ajax request.
  # It transmits the drops done in the tree to the database in order to last
  # longer than the next refresh of the browser.
  def delegate_tree_drop
    new_parent_id = params[:new_parent_id]
    moved_artifact_id = params[:moved_artifact_id]
    child = ReArtifactProperties.find_by_id(moved_artifact_id)
    if new_parent_id == 'null'
      # Element is dropped under root node which is the project new parent-id has to become nil.
      child.parent = nil
    else
      # Element is dropped under other artifact
      child.parent = ReArtifactProperties.find(new_parent_id)
    end
    child.state = State::DROPPING    #setting state for observer
    child.save!
    render :nothing => true
  end

  ##
  # The following method is called via JavaScript Tree by an ajax update request.
  # It transmits the call to the according controller which should render the detail view
  def delegate_tree_node_click
    artifact = ReArtifactProperties.find_by_id(params[:id])
    redirect_to url_for :controller => params[:artifact_controller], :action => 'edit', :id => params[:id], :parent_id => artifact.parent_artifact_id, :project_id => artifact.project_id
  end

  #renders a re artifact and its children recursively as html tree
  def render_to_html_tree(re_artifact)
    @htmltree += '<li id="node_' + re_artifact.id.to_s #IDs must begin with a letter(!)
    @htmltree += '" class="' + re_artifact.artifact_type.to_s.underscore + '">'
    @htmltree += '<span class="handle"></span>'
    @htmltree += '<a>' + re_artifact.name.to_s + '</a>'

    if (!re_artifact.children.empty?)
      @htmltree += '<ul>'
      for child in re_artifact.children
        render_to_html_tree(child)
      end
      @htmltree += '</ul>'
    end
    @htmltree += '</li>'
  end

  # first tries to enable a contextmenu in artifact tree
  def context_menu
    @artifact =  ReArtifactProperties.find_by_id(params[:id])

    render :text => "Could not find artifact.", :status => 500 unless @artifact

    @subartifact_controller = @artifact.artifact_type.to_s.underscore
    @back = params[:back_url] || request.env['HTTP_REFERER']

    render :layout => false
  end

end