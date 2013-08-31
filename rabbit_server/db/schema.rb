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

ActiveRecord::Schema.define(:version => 24) do

  create_table "admins", :force => true do |t|
    t.string   "login",       :limit => 510,                     :null => false
    t.string   "password",    :limit => 510,                     :null => false
    t.integer  "permissions",                :default => 0
    t.integer  "level_low",                  :default => 1
    t.integer  "level_high",                 :default => 999999
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "confs", :force => true do |t|
    t.string  "name",    :limit => 510, :null => false
    t.text    "value"
    t.boolean "visible"
  end

  add_index "confs", ["name"], :name => "confs_name_key", :unique => true

  create_table "errors", :force => true do |t|
    t.string  "title",      :limit => 510
    t.text    "content"
    t.string  "images",     :limit => 510
    t.text    "resolution"
    t.integer "resolved",                  :default => 0
  end

  create_table "lang_locales", :force => true do |t|
    t.string "key",    :limit => 510, :null => false
    t.string "locale", :limit => 510, :null => false
    t.text   "value"
    t.string "author", :limit => 510
  end

  add_index "lang_locales", ["key", "locale"], :name => "lang_locales_key_locale_key", :unique => true

  create_table "langs", :force => true do |t|
    t.string "key",     :limit => 510, :null => false
    t.string "part",    :limit => 510
    t.string "comment", :limit => 510
  end

  add_index "langs", ["key"], :name => "langs_key_key", :unique => true

  create_table "levels", :force => true do |t|
    t.string   "description", :limit => 510
    t.integer  "number",                     :default => 0
    t.integer  "version",                    :default => 0
    t.integer  "width"
    t.integer  "height"
    t.string   "author",      :limit => 510
    t.text     "conditions"
    t.text     "group"
    t.boolean  "enabled"
    t.boolean  "visible"
    t.datetime "created_at"
    t.string   "image",       :limit => 510
  end

  create_table "notifyes", :force => true do |t|
    t.string   "message",    :limit => 510,                :null => false
    t.string   "mode",       :limit => 510
    t.integer  "priority",                  :default => 0
    t.integer  "position",                  :default => 0
    t.integer  "net",                       :default => 1
    t.boolean  "enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stats", :force => true do |t|
    t.string  "name",  :limit => 510,                :null => false
    t.integer "time",                                :null => false
    t.integer "value",                :default => 0
  end

  add_index "stats", ["name", "time"], :name => "stats_name_time_key", :unique => true

  create_table "stories", :force => true do |t|
    t.integer "number",                     :null => false
    t.string  "name",        :limit => 510
    t.string  "description", :limit => 510
    t.string  "image",       :limit => 510
    t.integer "start_level",                :null => false
    t.integer "end_level",                  :null => false
    t.boolean "enabled"
  end

  add_index "stories", ["number"], :name => "stories_number_key", :unique => true

  create_table "transactions", :force => true do |t|
    t.string   "uid",                :limit => 510,                :null => false
    t.integer  "net",                                              :null => false
    t.string   "status",             :limit => 510
    t.integer  "product_type",                      :default => 0
    t.integer  "quantity"
    t.integer  "netmoney"
    t.integer  "netmoney_type",                     :default => 0
    t.integer  "net_transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_friends", :force => true do |t|
    t.string   "user_uid",                            :null => false
    t.string   "friend_uid",                          :null => false
    t.boolean  "accepted",         :default => false
    t.datetime "last_daily_bonus"
  end

  add_index "user_friends", ["user_uid", "friend_uid"], :name => "index_user_friends_on_user_uid_and_friend_uid", :unique => true

  create_table "users", :force => true do |t|
    t.integer  "net",                                                                           :null => false
    t.string   "uid",              :limit => 510,                                               :null => false
    t.string   "first_name",       :limit => 510
    t.string   "last_name",        :limit => 510
    t.text     "level_instances"
    t.text     "rewards"
    t.integer  "score",                                                          :default => 0
    t.integer  "money",                                                          :default => 0
    t.integer  "level",                                                          :default => 1
    t.decimal  "roll",                            :precision => 10, :scale => 0
    t.integer  "friends_invited",                                                :default => 0
    t.integer  "postings",                                                       :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "day_counter",                                                    :default => 0
    t.integer  "tutorial",                                                       :default => 0
    t.text     "offer_instances"
    t.integer  "offers",                                                         :default => 0
    t.text     "customize"
    t.integer  "stars",                                                          :default => 0
    t.string   "items",            :limit => 510
    t.string   "locale",           :limit => 510
    t.integer  "energy",                                                         :default => 0
    t.datetime "energy_last_gain"
  end

  add_index "users", ["uid", "net"], :name => "users_uid_net_key", :unique => true

end
