# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 1) do

  create_table "casserver_lt", :force => true do |t|
    t.string   "ticket",          :null => false
    t.datetime "created_on",      :null => false
    t.datetime "consumed"
    t.string   "client_hostname", :null => false
  end

  create_table "casserver_pgt", :force => true do |t|
    t.string   "ticket",            :null => false
    t.datetime "created_on",        :null => false
    t.string   "client_hostname",   :null => false
    t.string   "iou",               :null => false
    t.integer  "service_ticket_id", :null => false
  end

  create_table "casserver_st", :force => true do |t|
    t.string   "ticket",            :null => false
    t.text     "service",           :null => false
    t.datetime "created_on",        :null => false
    t.datetime "consumed"
    t.string   "client_hostname",   :null => false
    t.string   "username",          :null => false
    t.string   "type",              :null => false
    t.integer  "granted_by_pgt_id"
    t.integer  "granted_by_tgt_id"
  end

  create_table "casserver_tgt", :force => true do |t|
    t.string   "ticket",           :null => false
    t.datetime "created_on",       :null => false
    t.string   "client_hostname",  :null => false
    t.string   "username",         :null => false
    t.text     "extra_attributes"
  end

  create_table "users", :force => true do |t|
    t.string "username"
    t.string "email"
    t.string "encrypted_password"
    t.string "full_name"
  end

end
