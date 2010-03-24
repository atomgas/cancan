module CanCan
  class ResourceAuthorization # :nodoc:
    attr_reader :params
    
    def initialize(controller, params, options = {})
      @controller = controller
      @params = params
      @options = options
    end
    
    def load_and_authorize_resource
      load_resource
      authorize_resource
    end
    
    def load_resource
      unless collection_actions.include? params[:action].to_sym
        if new_actions.include? params[:action].to_sym
          resource.build(params[model_name.to_sym])
        elsif params[:id]
          resource.find(params[:id])
        end
      end
    end 
    
    def cancan_authorize
      if resource_exists?
        load_and_authorize_resource
      else
        authorize_authorizable_or_controller
      end
    end    
    
    def authorize_resource
      @controller.unauthorized! if @controller.cannot?(params[:action].to_sym, resource.model_instance || resource.model_class)
    end
            
    def authorize_authorizable_or_controller
      @controller.unauthorized! if @controller.cannot?(params[:action].to_sym, @options[:authorizable] || @controller.controller_name.to_sym)
    end
    
    private
    
    def resource_exists?
      !!(Object.const_defined?(model_name.to_s.camelize) || model_name.to_s.camelize.constantize rescue false)
    end
        
    def resource
      @resource ||= ControllerResource.new(@controller, model_name, parent_resource, @options)
    end
    
    def parent_resource
      parent = nil
      [@options[:nested]].flatten.compact.each do |name|
        id = @params["#{name}_id".to_sym]
        if id
          parent = ControllerResource.new(@controller, name, parent)
          parent.find(id)
        else
          parent = nil
        end
      end
      parent
    end
    
    def model_name
      params[:controller].split('/').last.singularize
    end
    
    def collection_actions
      [:index] + [@options[:collection]].flatten
    end
    
    def new_actions
      [:new, :create] + [@options[:new]].flatten
    end
  end
end
