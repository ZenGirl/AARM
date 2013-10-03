require 'active_record'

module Rack
  module AARM
    class ResourceAudit < ActiveRecord::Base
      attr_accessor :id, :vendor_name, :verb, :route, :params, :response_code, :created_at
    end
    class Resources < ActiveRecord::Base
      attr_accessor :id, :active, :verb, :route, :group_id, :created_at, :updated_at
    end
    class ResourceGroup < ActiveRecord::Base
      attr_accessor :id, :active, :name, :crud, :created_at, :updated_at
    end
  end
end