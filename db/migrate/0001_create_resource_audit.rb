class CreateResourceAudit < ActiveRecord::Migration
  def self.up
    create_table :resource_audits do |t|
      t.string :vendor_name
      t.string :verb
      t.string :route
      t.text :params
      t.string :response_code
      t.datetime :created_at
    end
  end
  def self.down
    drop_table :resource_audits
  end
end