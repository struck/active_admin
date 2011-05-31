require 'inherited_resources'
require 'active_admin/resource_controller/action_builder'
require 'active_admin/resource_controller/callbacks'
require 'active_admin/resource_controller/collection'
require 'active_admin/resource_controller/filters'
require 'active_admin/resource_controller/form'
require 'active_admin/resource_controller/menu'
require 'active_admin/resource_controller/page_configurations'
require 'active_admin/resource_controller/scoping'
require 'active_admin/resource_controller/sidebars'

module ActiveAdmin
  class ResourceController < ::InheritedResources::Base

    helper ::ActiveAdmin::ViewHelpers

    layout false

    respond_to :html, :xml, :json
    respond_to :csv, :only => :index

    before_filter :only_render_implemented_actions
    before_filter :authenticate_active_admin_user
    before_filter :prepare_csv_columns, :only => :index

    include ActiveAdmin::ActionItems
    include ActionBuilder
    include Callbacks
    include Collection
    include Filters
    include Form
    include Menu
    include PageConfigurations
    include Scoping
    include Sidebars

    class << self

      # Reference to the Resource object which initialized
      # this controller
      attr_accessor :active_admin_config

      def active_admin_config=(config)
        @active_admin_config = config
        defaults  :resource_class => config.resource,
                  :route_prefix => config.route_prefix,
                  :instance_name => config.underscored_resource_name
      end

      public :belongs_to
    end

    # Default Sidebar Sections
    sidebar :filters, :only => :index do
      active_admin_filters_form_for assigns["search"], filters_config
    end

    # Default Action Item Links
    action_item :only => :show do
      if controller.action_methods.include?('edit')
        link_to("Edit #{active_admin_config.resource_name}", edit_resource_path(resource))
      end
    end

    action_item :only => :show do
      if controller.action_methods.include?("destroy")
        link_to("Delete #{active_admin_config.resource_name}",
          resource_path(resource), 
          :method => :delete, :confirm => "Are you sure you want to delete this?")
      end
    end

    action_item :except => [:new, :show] do
      if controller.action_methods.include?('new')
        link_to("New #{active_admin_config.resource_name}", new_resource_path)
      end
    end

    protected

    # Override _prefix so we force ActionController to render the
    # views from active_admin/resource instead of default path
    def _prefix
      'active_admin/resource'
    end

    # By default Rails will render un-implemented actions when the view exists. Becuase Active
    # Admin allows you to not render any of the actions by using the #actions method, we need
    # to check if they are implemented.
    def only_render_implemented_actions
      raise AbstractController::ActionNotFound unless action_methods.include?(params[:action])
    end

    # Calls the authentication method as defined in ActiveAdmin.authentication_method
    def authenticate_active_admin_user
      send(ActiveAdmin.authentication_method) if ActiveAdmin.authentication_method
    end

    def current_active_admin_user
      send(ActiveAdmin.current_user_method) if ActiveAdmin.current_user_method
    end
    helper_method :current_active_admin_user

    def current_active_admin_user?
      !current_active_admin_user.nil?
    end
    helper_method :current_active_admin_user?

    def active_admin_config
      self.class.active_admin_config
    end
    helper_method :active_admin_config

    # Returns the renderer class to use for the given action.
    def renderer_for(action)
      ActiveAdmin.view_factory["#{action}_page"]
    end
    helper_method :renderer_for

    # Before filter to prepare the columns for CSV. Note this will
    # be deprecated very soon.
    def prepare_csv_columns
      if request.format.csv?
        @csv_columns = resource_class.columns.collect{ |column| column.name.to_sym }
      end
    end
  end
end
