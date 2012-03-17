class CreateLang < ActiveRecord::Migration
	def self.up
		create_table :langs do |t|
			t.string :key, :null => false
			t.string :part # к какому типу принадлежит фраза (по месту использования в игре)
			t.string :comment # комментарий по конкретномму языковому ключу (пояснение, где применяется)
		end

		create_table :lang_locales do |t|
			t.string :key, :null => false
			t.string :locale, :null => false
			t.text :value
			t.string :author # пометка, кто перевел
		end

		add_index :langs, [:key], :unique => true
		add_index :lang_locales, [:key, :locale], :unique => true
		add_column :users, :locale, :string
	end

	def self.down
		drop_table :langs
		drop_table :lang_locales

		remove_column :users, :locale
	end
end
