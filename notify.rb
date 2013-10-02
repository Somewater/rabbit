require 'rabbit_daemon'
require 'vk_notify_worker'
require 'vkontakte_api'
@cond = <<-SQL
updated_at < now() - interval '3 hours' and ((energy < 5 and energy_last_gain is null)
or
(energy = 4 and energy_last_gain < now() - interval '35 minutes')
or
(energy = 3 and energy_last_gain < now() - interval '65 minutes')
or
(energy = 2 and energy_last_gain < now() - interval '95 minutes')
or
(energy = 1 and energy_last_gain < now() - interval '125 minutes')
or
(energy = 0 and energy_last_gain < now() - interval '155 minutes'))
SQL
@uids = User.all(:select => 'uid', :conditions => @cond).map &:uid; @uids.size
VkontakteApi.configure do |config|
	config.logger.level = Logger::WARN
end
def start_procesee(phrases)
	v = RabbitDaemon::VkNotifyWorker.new
	v2 = VkontakteApi::Client.new
	online_uids_qiantity = 0
	phrases.each_with_index do |phrase, i| 
		puts "#{i}) #{phrase}"
		data = {'msg' => phrase}
		uids = User.all(:select => 'uid', :conditions => @cond).map &:uid;
		uids.each_slice(100) do |uids_slice|
			t = Time.new.to_f
			online_uids = v2.users.get(:uids => uids_slice, :fields => 'online,uid').select{|u| u.online == 1}.map{|u| u.uid}
			online_uids.each_slice(100){|slice| 
				v.push_to_queue(data.merge({'uids' => slice}))
			}
			print "\t#{online_uids.size} "
			time_diff = 0.35 - (Time.new.to_f - t)
			sleep(time_diff) if time_diff > 0
			online_uids_qiantity += online_uids.size
		end
	end 
	online_uids_qiantity
end
@phrases = Notify.find(40, 41,42,43,29,30).map{|n|n.message}

def auto_process(times_q, phrases, step_space = 600)
	online_uids_qiantity = 0
	times_q.times do |i|
		puts "STEP #{i} at #{Time.new}"
		procesed_uids = start_procesee(phrases)
		sleep(step_space.to_i) if step_space.to_i > 0
		puts "Processed #{procesed_uids} uids at #{Time.new}"
		online_uids_qiantity += procesed_uids.to_i
	end
	puts "Process completed at #{Time.new}, processed #{online_uids_qiantity} uids"
end
