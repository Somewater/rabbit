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

ActiveRecord::Schema.define(:version => 18) do

  create_table "admins", :force => true do |t|
    t.string   "login",                           :null => false
    t.string   "password",                        :null => false
    t.integer  "permissions", :default => 0
    t.integer  "level_low",   :default => 1
    t.integer  "level_high",  :default => 999999
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "confs", :force => true do |t|
    t.string  "name",                      :null => false
    t.text    "value"
    t.boolean "visible", :default => true
  end

  add_index "confs", ["name"], :name => "index_confs_on_name", :unique => true

  create_table "levels", :force => true do |t|
    t.string   "description"
    t.integer  "number",      :default => 0
    t.integer  "version",     :default => 0
    t.integer  "width"
    t.integer  "height"
    t.string   "author"
    t.text     "conditions"
    t.text     "group"
    t.boolean  "enabled",     :default => true
    t.boolean  "visible",     :default => true
    t.datetime "created_at"
    t.string   "image"
  end

  create_table "notifyes", :force => true do |t|
    t.string   "message",                      :null => false
    t.string   "mode"
    t.integer  "priority",   :default => 0
    t.integer  "position",   :default => 0
    t.integer  "net",        :default => 1
    t.boolean  "enabled",    :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stories", :force => true do |t|
    t.integer "number",                         :null => false
    t.string  "name"
    t.string  "description"
    t.string  "image"
    t.integer "start_level",                    :null => false
    t.integer "end_level",                      :null => false
    t.boolean "enabled",     :default => false
  end

  add_index "stories", ["number"], :name => "index_stories_on_number", :unique => true

  create_table "users", :force => true do |t|
    t.integer  "net",                                                           :null => false
    t.string   "uid",                                                           :null => false
    t.string   "first_name"
    t.string   "last_name"
    t.text     "level_instances"
    t.text     "rewards"
    t.integer  "score",                                          :default => 0
    t.integer  "money",                                          :default => 0
    t.integer  "level",                                          :default => 1
    t.decimal  "roll",            :precision => 10, :scale => 0, :default => 0
    t.integer  "friends_invited",                                :default => 0
    t.integer  "postings",                                       :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "day_counter",                                    :default => 0
    t.integer  "tutorial",                                       :default => 0
    t.text     "offer_instances"
    t.integer  "offers",                                         :default => 0
    t.text     "customize"
    t.integer  "stars",                                          :default => 0
    t.string   "items"
  end

  add_index "users", ["uid", "net"], :name => "index_users_on_uid_and_net", :unique => true

end
