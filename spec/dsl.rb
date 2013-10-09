require 'awesome_print'

require_relative '../lib/aarm'

module Rack
  module AARM
    module DSL

      resources = Resources.new

      resource = Resource.new(1, 'billings.active', '/billings/api/v1')
      resource.add_suffix(Regexp.new('^\/banks$'))
      .add_verb('GET').add_active_range(ActiveRange.for_all_time).back_to_suffix
      .add_verb('POST').add_active_range(ActiveRange.for_all_time).back_to_suffix
      .add_verb('HEAD').add_active_range(ActiveRange.for_all_time).back_to_suffix
      resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
      .add_verb('GET').add_active_range(ActiveRange.for_all_time).back_to_suffix
      .add_verb('PUT').add_active_range(ActiveRange.for_all_time).back_to_suffix
      .add_verb('DELETE').add_active_range(ActiveRange.for_all_time).back_to_suffix
      resources.add(resource)

      all_past_to_20131001 = ActiveRange.new(ActiveRange.all_past, DateTime.new(2013, 10, 1))
      from_20131003_on = ActiveRange.new(DateTime.new(2013, 10, 3), ActiveRange.all_future)

      resource = Resource.new(2, 'billings.with.missing.date', '/billings/api/v2')
      resource.add_suffix(Regexp.new('^\/banks$'))
      .add_verb('GET').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
      .add_verb('POST').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
      .add_verb('HEAD').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
      resource.add_suffix(Regexp.new('^\/banks/[\d]+$'))
      .add_verb('GET').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
      .add_verb('PUT').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
      .add_verb('DELETE').add_active_range(all_past_to_20131001).add_active_range(from_20131003_on).back_to_suffix
      resources.add(resource)

      r = resources.find('/billings/api/v1')
      puts "    #{r.nil? ? 'NOT FOUND' : 'Found'} /billings/api/v1"

      r = resources.find_full('/billings/api/v1/banks')
      puts "    #{r.nil? ? 'NOT FOUND' : 'Found'} /billings/api/v1/banks"

      r = resources.find_full('/billings/api/v1/banks', 'GET')
      puts "    #{r.nil? ? 'NOT FOUND' : 'Found'} /billings/api/v1/banks [GET]"

      r = resources.find_full('/billings/api/v1/banks', 'PATCH')
      puts "    #{r.nil? ? 'NOT FOUND' : 'Found'} /billings/api/v1/banks [PATCH]"

      r = resources.find('/billings/api/v2')
      puts "    #{r.nil? ? 'NOT FOUND' : 'Found'} /billings/api/v2"

      r = resources.find('/billings/api/v3')
      puts "    #{r.nil? ? 'NOT FOUND' : 'Found'} /billings/api/v3"

      puts "Checking v1/banks 2013-10-01"
      puts resources.is_active? '/billings/api/v1/banks', DateTime.new(2013, 10, 1), 'GET'
      puts "Checking v1/banks 2013-10-01"
      puts resources.is_active? '/billings/api/v2/banks', DateTime.new(2013, 10, 1), 'GET'
      puts "Checking v2/banks 2013-10-02"
      puts resources.is_active? '/billings/api/v2/banks', DateTime.new(2013, 10, 2), 'GET'
      puts "Checking v2/banks 2013-10-03"
      puts resources.is_active? '/billings/api/v2/banks', DateTime.new(2013, 10, 3), 'GET'


      class Vendors
        attr_accessor :vendors, :resources

        def initialize
          @vendors = []
          @resources = []
        end

        def add(vendor)
          vendor.resources = @resources
          @vendors << vendor
        end

        def exist?(name)
          @vendors.any? { |vendor| vendor.name == name }
        end

        def find(id)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.id == id
          end
          result
        end

        def find_by_name(name)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.name == name
          end
          result
        end

        def find_by_key(key)
          result = nil
          @vendors.each do |vendor|
            result = vendor if vendor.keys.any? { |k| k.key == key }
          end
          result
        end
      end
      class Vendor
        attr_accessor :id, :name, :keys, :active_ranges, :use_locations, :locations, :roles
        attr_accessor :resources

        def initialize(id, name)
          @id, @name = id, name
          @keys, @active_ranges, @use_locations, @locations, @roles = [], [], false, [], []
          @resources = []
        end

        def add_key(active_range, key, secret)
          @keys << VendorKey.new(active_range, key, secret)
          self
        end

        def add_active_range(active_range)
          @active_ranges << active_range
          self
        end

        def make_restricted_by_locations
          @use_locations = true
          self
        end

        def add_location(location)
          @locations << location
          self
        end

        def add_role(name, password_plain, password_md5)
          role = Role.new(name, password_plain, password_md5)
          role.add_binding(binding().eval('self'))
          @roles << role
          role
        end

        def active_on?(date)
          d = date
          d = DateTime.parse(date) if date.is_a? String
          @active_ranges.any? { |active_range| active_range.in_range? d }
        end

        def uses_locations?
          @use_locations
        end

        def allowed_from?(ipv4, on_date)
          return true unless @use_locations
          d = on_date
          d = DateTime.parse(on_date) if on_date.is_a? String
          @locations.each do |location|
            return location.active_ranges.any? { |active_range| active_range.in_range? d } if location.ipv4 == ipv4
          end
          false
        end

        def find_role(name, password_md5)
          @roles.each do |role|
            return role if role.name == name and role.password_md5 == password_md5
          end
          nil
        end

        def can_access?(opts={})
          return false unless active_on? opts[:on]
          return false unless allowed_from? opts[:ipv4], opts[:on]
          role = find_role opts[:role], opts[:pass]
          return false if role.nil?
          return false unless role.active_on? opts[:on]
          path_allowed = false
          role.rights.each do |right|
            if right.verbs.include? opts[:via]
              path_allowed = true if resources.is_active? opts[:path], opts[:on], opts[:via]
            end
          end
          return false unless path_allowed
          true
        end
      end
      class VendorKey
        attr_accessor :active_range, :key, :secret

        def initialize(active_range, key, secret)
          @active_range, @key, @secret = active_range, key, secret
        end
      end
      class Location
        attr_accessor :ipv4, :active_ranges

        def initialize(ipv4)
          @ipv4 = ipv4
          @active_ranges = []
        end

        def add_active_range(active_range)
          @active_ranges << active_range
          self
        end
      end
      class Role
        attr_accessor :name, :password_plain, :password_md5, :active_ranges, :rights

        def initialize(name, password_plain, password_md5)
          @name, @password_plain, @password_md5 = name, password_plain, password_md5
          @active_ranges, @rights = [], []
        end

        def add_active_range(active_range)
          @active_ranges << active_range
          self
        end

        def add_rights(verbs, resources)
          @rights << RoleRights.new(verbs, resources)
          self
        end

        def active_on?(date)
          d = date
          d = DateTime.parse(date) if date.is_a? String
          @active_ranges.any? { |active_range| active_range.in_range? d }
        end


        def add_binding(caller)
          @caller = caller
        end

        def back_to_vendor
          @caller
        end
      end
      class RoleRights
        attr_accessor :verbs, :on_resources

        def initialize(verbs, resources)
          @verbs, @on_resources = verbs, resources
        end

      end

      vendors = Vendors.new
      vendors.resources = resources

      vendor = Vendor.new(1, 'vendor1')
      .add_key(ActiveRange.for_all_time, "QOYNT/+GeMBQJzX+QSBuEA==", "MpzZMi+Aug6m/vd5VYdHrA==")
      .add_active_range(ActiveRange.for_all_time)
      .make_restricted_by_locations
      .add_location(Location.new('127.0.0.1').add_active_range(ActiveRange.for_all_time))
      .add_role('default', 'vendor1_default', '1f6edad466a632cb0c91fdc9c500b437').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET), [1]).back_to_vendor
      .add_role('admin', 'vendor1_admin', 'b616111a3c791f223b89957e72859ad2').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET POST PUT DELETE), [1, 2]).back_to_vendor

      vendors.add vendor

      vendor = Vendor.new(2, 'vendor2')
      .add_key(ActiveRange.new('2013-10-01', '2013-10-31'), "wBxPg1il07wNMdkClLWsqg==", "q9cqANbXvthP6ypSMwQ3ow==")
      .add_active_range(ActiveRange.new('2013-10-01', '2013-10-31'))
      .make_restricted_by_locations
      .add_location(Location.new('127.0.0.1').add_active_range(ActiveRange.new('2013-10-01', '2013-10-14')).add_active_range(ActiveRange.new('2013-10-21', '2013-10-31')))
      .add_location(Location.new('192.168.3.129').add_active_range(ActiveRange.new('2013-10-15', '2013-10-20')))
      .add_role('reader12', 'vendor2_reader', '632357780d36658bf7f302b1c29c1620').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET), [1, 2]).back_to_vendor
      .add_role('author12', 'vendor2_author', '782c9b1f47709012c0797aadd11efdf4').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET POST PUT), [1, 2]).back_to_vendor
      .add_role('editor2', 'vendor2_editor', 'fc730593435b207f1d9bf62e53361cf4').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET POST PUT), [2]).back_to_vendor
      .add_role('owner12', 'vendor2_owner', 'd1c21ef0802ee1849e048124510295ca').add_active_range(ActiveRange.for_all_time).add_rights(%w(GET POST PUT DELETE), [1, 2]).back_to_vendor

      vendors.add vendor

      puts "vendor1 exists              : #{vendors.exist? 'vendor1'}"
      vendor = vendors.find_by_key 'QOYNT/+GeMBQJzX+QSBuEA=='
      puts "vendor                      : #{vendor}"
      puts "active on 2013-10-17        : #{vendor.active_on? '2013-10-17'}"
      puts "uses_locations              : #{vendor.uses_locations?}"
      puts "allowed from 127.0.0.1 today: #{vendor.allowed_from?('127.0.0.1', DateTime.now)}"
      role = vendor.find_role 'default', '1f6edad466a632cb0c91fdc9c500b437'
      #ap role
      puts "role active on 2013-10-01   : #{role.active_on? '2013-10-01'}"
      puts "can access path             : #{vendor.can_access? path: '/billings/api/v1/banks/123456', via: 'GET', on: '2013-10-14 12:35:56', role: 'admin', pass: 'b616111a3c791f223b89957e72859ad2', ipv4: '127.0.0.1'}"
      puts "can access path             : #{vendor.can_access? path: '/billings/api/v3/banks/123456', via: 'GET', on: '2013-10-14 12:35:56', role: 'admin', pass: 'b616111a3c791f223b89957e72859ad2', ipv4: '127.0.0.1'}"

    end
  end
end
