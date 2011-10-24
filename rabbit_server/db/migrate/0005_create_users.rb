class CreateUsers < ActiveRecord::Migration
	def self.up
		create_table :users do |t|
			t.string  :uid, :null => false
			t.string  :first_name
			t.string  :last_name
			
			# ���� � ������������ ���������� �������, ����:
			# {  "0":{"t":123, "c":23, "v":7} ,...  }
			# t - ����� ����������� � ��������
			# c - ���-�� ��������� ��������
			# v - ������ ������, �� ������ ��������
			t.text    :level_instances, default => '{}'

			t.integer :score,  :default => 0
			t.integer :money,  :default => 0
			t.integer :level_number, :default => 0
		end
	end

	def self.down
		drop_table 'users'
	end
end
