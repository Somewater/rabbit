# encoding: utf-8
ROOT = File.dirname( File.expand_path( __FILE__ + '../../..') )
ENV['RACK_ENV'] = 'test'
require ::File.expand_path('../../config/environment',  __FILE__)

PUBLIC_CONFIG['PREVENT_INVITE_REWARD'] = 0 # TODO

class AllSpec
	describe "Rabbit" do

		def execute_request(hash, controller_class)
			request = TRequest.new(hash)
			controller = controller_class.new(request)
			controller.call
			controller.instance_variable_get('@response')
		end

		def execute_secure_request(hash, controller_class)
			request = TRequest.new(hash)
			controller = nil
			lambda{
				controller = controller_class.new()
				controller.start(request)
				raise "You dont include module RequestSecurity"
			}.should raise_error(AuthError, /Unsecured request/)
			request.params['secure'] = controller.secure_digest()

			controller = controller_class.new(request)
			controller.call
			controller.instance_variable_get('@response')
		end

		def get_uniq_user(uid = 1)
			user = User.find_by_uid(uid.to_i,1)
			unless(user)
				user = User.new({:uid => uid.to_s, :net => '1'})
			end
			user
		end

		def get_unexistable_uid
			user_max_id = (User.maximum(:id) || 0) + 1
			"1-#{user_max_id}"
		end

		def check_json(data)
			data = JSON.parse(data) if data.is_a?(String)
			if(block_given?)
				yield(data)
			else
				data
			end
		end

		before :each do
			@user = User.new({:uid => '1', :level => 2})
			@start_test_time = Time.new
			Application.instance_variable_set('@time', @start_test_time.dup)
		end
		
		after :each do
			Application.time.should be_within(1).of(@start_test_time)
		end
		
		describe "Server logic" do

			before :all do
				RewardManager.instance.instance_variable_set('@rewards_by_type',
					{
						Reward::TYPE_FAST_TIME => [Reward.new({'id' => 1, 'type' => Reward::TYPE_FAST_TIME, 'degree' => 0}),
												   Reward.new({'id' => 2, 'type' => Reward::TYPE_FAST_TIME, 'degree' => 0})],

						Reward::TYPE_ALL_CARROT => [Reward.new({'id' => 3, 'type' => Reward::TYPE_ALL_CARROT, 'degree' => 0}),
												   Reward.new({'id' => 4, 'type' => Reward::TYPE_ALL_CARROT, 'degree' => 0})],

						Reward::TYPE_CARROT_PACK => [Reward.new({'id' => 5, 'type' => Reward::TYPE_CARROT_PACK, 'degree' => 100}),
												   Reward.new({'id' => 6, 'type' => Reward::TYPE_CARROT_PACK, 'degree' => 200})],
						Reward::TYPE_FAMILIAR => [Reward.new({'id' => 7, 'type' => Reward::TYPE_FAMILIAR, 'degree' => 3}),
												   Reward.new({'id' => 8, 'type' => Reward::TYPE_FAMILIAR, 'degree' => 5})]
					})
			end

			before :each do
				@level = Level.new({
									'conditions' => '<conditions>							\
									<time>100</time>										\
									<fastTime>50</fastTime>									\
									<carrotMin>10</carrotMin> 								\
									<carrotMiddle>15</carrotMiddle> 						\
									<carrotMax>20</carrotMax>								\
									<carrotAll>20</carrotAll></conditions>',
									'number' => 2
									})
				@conditions = @level.conditions_to_hash
				Level.class_variable_set('@@all_head_by_number', {@level.number => @level})
				@levelInstance = LevelInstance.new({'timeSpended' => @conditions['time'], 'carrotHarvested' => @conditions['carrotMin'], 'success' => true})
				@levelInstance.data = @level
				#Level.stub!()
			end

			def server_logic_process
				ServerLogic.addRewardsToLevelInstance(@user, @levelInstance)
			end
		
			it "Непройденный уровень не обрабатывается" do
				# очень хороший результат, но с флагом success==false
				user_init_level = @user.level
				@levelInstance.data = {'success' => false, 'timeSpended' => 1, 'carrotHarvested' => @conditions['carrotAll']}
				server_logic_process().size.should == 0
				@user.level.should == user_init_level
			end
			
			#it "Обнаруживается уровень, непройденный по времени" do
			#	@user.level.should == 1
			#	@levelInstance.data = {'timeSpended' => @conditions['time'].to_i + 1}
			#	server_logic_process().size.should == 0
			#	@user.level.should == 1
			#end
			
			it "Обнаруживается уровень, непройденный по морковкам" do
				user_init_level = @user.level
				@levelInstance.data = {'carrotHarvested' => @conditions['carrotMin'].to_i - 1}
				server_logic_process().size.should == 0
				@user.level.should == user_init_level
			end

			it "Нельзя пройти недоступный по левелу для пользователя уровень" do
				@user.level = 3
				@level.number = 4
				lambda{
					server_logic_process()
				}.should raise_error(LogicError, /Inaccessible level .+/)
			end
			
			it "Выданные реварды пишутся в юзера, level_instance и возвращаются функцией" do
				@levelInstance.data = {'timeSpended' => 1, 'carrotHarvested' => @conditions['carrotAll']}
				@user.stub('get_roll').and_return(0.999999)
				rewards = server_logic_process()
				rewards.size.should > 0
				@user.rewards.size.should == rewards.size
				@levelInstance.rewards.size.should == rewards.size
			end
			
			it "Учитывается предыдущий уровень, результат перезаписывается лучшим" do
				@user.level_instances = {@level.number.to_s => {'c' => @conditions['carrotMin'], 't' => @conditions['time'], 'v' => 0, 's' => 1}}
				@levelInstance.data = {'timeSpended' => @conditions['time'] - 5, 'carrotHarvested' => @conditions['carrotMin'] + 5}
				server_logic_process()
				@user.level_instances[@level.number.to_s]['c'].should == @levelInstance.carrotHarvested
				@user.level_instances[@level.number.to_s]['t'].should == @levelInstance.timeSpended
				@user.level_instances[@level.number.to_s]['s'].should > 1
			end

			it "Начисляются звезды за новый уровень, инкрементируются за лучшее прохождение" do
				@levelInstance.data = {'timeSpended' => @conditions['time'] - 5, 'carrotHarvested' => @conditions['carrotMin']}
				server_logic_process()
				@user.level_instances[@level.number.to_s]['s'].should == 1

				@levelInstance.data = {'carrotHarvested' => @conditions['carrotMiddle']}
				server_logic_process()
				@user.level_instances[@level.number.to_s]['s'].should == 2

				@levelInstance.data = {'carrotHarvested' => @conditions['carrotMax']}
				server_logic_process()
				@user.level_instances[@level.number.to_s]['s'].should == 3
			end

			it "Звезды не инкрементируются, если уровень пройден не лучше прошлого раза" do
				@user.level_instances = {@level.number.to_s => {'c' => @conditions['carrotMin'], 't' => @conditions['time'], 'v' => 0, 's' => 2}}
				@levelInstance.data = {'timeSpended' => @conditions['time'] - 5, 'carrotHarvested' => @conditions['carrotMiddle']}
				server_logic_process()
				@user.level_instances[@level.number.to_s]['s'].should == 2
			end
			
			it "Выдается ревард за скорость" do
				@levelInstance.data = {'timeSpended' => @conditions['fastTime']}
				server_logic_process()
				server_logic_process().size >= 1
				(@levelInstance.rewards.select{|r| r.type == Reward::TYPE_FAST_TIME }).size.should == 1
			end
			
			it "Не выдается ревард за скорость повторно" do
				@user.rewards = {123 => {"id" => 123, "x" => 2, "y" => 5}}
				fast_time_reward = Reward.new({'id' => 123, 'type' => Reward::TYPE_FAST_TIME, 'degree' => 0});
				@levelInstance.data = {'timeSpended' => @conditions['fastTime']}
				server_logic_process().size == 0
			end
			
			it "Выдать CARROT_ALL (если повезет с рандомом), если их достаточно собрано и ранее уровень не проходили" do
				@levelInstance.data = {'carrotHarvested' => @conditions['carrotAll']}
				@user.stub('get_roll').and_return(0.999999)
				rewards = server_logic_process()
				rewards.size.should >= 0
				(rewards.select{|r| r.type == Reward::TYPE_ALL_CARROT}).size.should == 1
			end
			
			it "За один уровень невозможно собрать морковок более, чем 'carrotAll'" do
				@levelInstance.data = {'carrotHarvested' => @conditions['carrotAll'] + 1}
				lambda{
					server_logic_process()
				}.should raise_error(LogicError, /Unbelievable .+/)
			end

			it "CARROT_ALL выдается чаще для 3-х звезд, чем для 2-х звезд" do
				@levelInstance.data = {'carrotHarvested' => @conditions['carrotMiddle']}
				middle_success = 0
				100.times{|i|
					@user.rewards = {};
					@user.score = 0;
					@user.level_instances = {};
					@levelInstance.rewards.clear;
					middle_success += server_logic_process().length
				}

				@levelInstance.data = {'carrotHarvested' => @conditions['carrotMax']}
				max_success = 0
				100.times{
					@user.rewards = {};
					@user.score = 0;
					@user.level_instances = {};
					@levelInstance.rewards.clear;
					max_success += server_logic_process().length
				}

				middle_success.should  be_within(4).of(30)
				max_success.should be_within(10).of(90)
			end
			
			it "Выдается CARROT_PACK, если достигнут" do
				@user.score = RewardManager.instance.get_by_type(Reward::TYPE_CARROT_PACK).first.degree - 1
				(server_logic_process().select{|r| r.type == Reward::TYPE_CARROT_PACK }).size.should == 1
			end
			
			it "Один и тот же CARROT_PACK не выдается дважды" do
				RewardManager.instance.get_by_type(Reward::TYPE_CARROT_PACK).each{|r| @user.add_reward_instance(RewardInstance.new(r, @level)) }
				@user.score = RewardManager.instance.get_by_type(Reward::TYPE_CARROT_PACK).first.degree - 1
				(server_logic_process().select{|r| r.type == Reward::TYPE_CARROT_PACK }).size.should == 0
			end

			it "В поле user.number пишется значение следующего доступного уровня, если оно выше текущего" do
				@user.level = 3
				@level.number = 3
				server_logic_process()
				@user.level.should == @level.number + 1
			end
			
			it "Выдается только ревард соответствующего degree" do
				degree = RewardManager.instance.get_by_type(Reward::TYPE_CARROT_PACK).first.degree
				reward = ServerLogic.checkAddReward(@user, @levelInstance, nil, Reward::TYPE_CARROT_PACK, degree)
				reward.should_not be_nil
				reward.degree.should == degree
			end

			it "Уровню правильно присваивается число звезд" do
				@levelInstance.data = {'stars' => 3, 'carrotHarvested' => @conditions['carrotMiddle']} # от клиента пришло завышенное число звезд
				server_logic_process()
				li = @user.get_level_instance_by_number(@level.number)
				li.stars.should == 2
			end

			it "Умеет выдавать нелевельные реварды" do
				reward = ServerLogic.checkAddReward(@user, nil, nil, Reward::TYPE_FAMILIAR, 3)
				reward.should be_a_kind_of(RewardInstance)
			end

			it "Если игрок впервые проходит 1й (туториальный) левел, он всегда получает награду" do
				# формируем в конфиге 1-й левел, а не второй
				@level.number = 1
				Level.class_variable_set('@@all_head_by_number', {@level.number => @level})
				@levelInstance.data = @level
				@levelInstance.data = {'carrotHarvested' => @conditions['carrotMiddle']} # не самое лучшее прохождение

				30.times do |i|
					rewards = server_logic_process()
					(rewards.select{|r| r.type == Reward::TYPE_ALL_CARROT}).size.should == 1
					@user.level_instances = {}
					@user.rewards = {}
					@levelInstance.rewards.clear
				end
			end

			it "После прохождения следующего доступного уровня, энергия на максимум" do
				@user.energy = 0
				@user.level = 2
				@level.number = 2
				server_logic_process()
				@user.energy.should == PUBLIC_CONFIG['ENERGY_MAX']
			end

			it "После прохождегния одного из предыдущих (но не последнего) уровней, энергия не меняется" do
				@user.energy = 0
				@user.level = 3
				@level.number = 2
				server_logic_process()
				@user.energy.should == 0
			end

			it "Нельзя закомплитить уровень, команда старта которого не была отправлена" do
				pending()
			end

		end
		
		describe "Security" do

			before :all do
				class TestRequest; attr_accessor :params end
				@request = TestRequest.new
				class TestController < BaseController
					def initialize(request, user); @user = user; super(request); end
					include RequestSecurity
				end
			end



			it "Проверка проходит успешно при правильной авторизаци" do
				@user.uid = '123'
				roll = 1
				secure = Digest::MD5.hexdigest("lorem }\"rab\":\"oof\"{ ipsum 1 local:test #{roll}")
				@request.params = {'net' => 'local:test', 'uid' => 1, 'json' => '{"foo":"bar"}', 'secure' => secure}

				TestController.new(@request, @user).call
			end
			
			it "Проверка выдает ошибки при некорректной авторизации" do
				@request.params = {'net' => 'undefined', 'json' => '{}', 'uid' => 1}
				lambda{
					TestController.new(@request, @user).call
				}.should raise_error(AuthError, /Undefined net identificator/)

				@request.params['net'] = 'local:test'
				lambda{
					TestController.new(@request, @user).call
				}.should raise_error(AuthError, /Unsecured request/)

				@request.params['secure'] = 'wrong_value'
				lambda{
					TestController.new(@request, @user).call
				}.should raise_error(AuthError, /Unsecured json string/)
			end
		end

		describe User do
			it "get_roll() выдает рандомные числа с нормальным распределением" do
				old = {}
				sum = 0.0
				graph = {}
				10.times{|i| graph[i] = 0 }
				iter = 300
				iter.to_i.times{
					roll = @user.get_roll
					raise "Dobling with roll = #{roll}" if old[roll.to_s]
					old[roll.to_s] = true
					sum += roll
					graph[(roll * 10).to_i] += 1
				}
				# неточность не более 5%
				sum.should be_within(iter / 20).of(iter / 2)
				graph.each{|k,v| v.should be_within(iter / 20).of(iter / 10) }
			end

			it "get_roll() выдает одинаковые числа, при синхронизации roll" do
				user = User.new({'uid' => 5})
				array = []
				100.times{array << user.get_roll()}

				user.roll = 1024 + 5

				100.times{ |i| user.get_roll() == array[i]}
			end

			it "Метод начисления item работает правильно" do
				quntity = @user.items[123].to_i
				@user.add_item(123, 5)
				@user.items[123].should == (5 + quntity)
				@user.add_item(123)
				@user.items[123].should == (5 + quntity + 1)
			end

			it "Нельзя отнять больше item, чем есть у юзера" do
				@user.items[123] = 5
				lambda{
					@user.delete_item(123, 6)
				}.should raise_error(LogicError, /Cant allocate \d+ items id=\d+/)
			end
		end

		describe InitializeController do

			before :all do
				RewardManager.instance.instance_variable_set('@rewards_by_type',
					{
						Reward::TYPE_REFERER => [Reward.new({'id' => 111, 'type' => Reward::TYPE_REFERER, 'degree' => 1}),
												   Reward.new({'id' => 222, 'type' => Reward::TYPE_REFERER, 'degree' => 3})],
						Reward::TYPE_FAMILIAR => [Reward.new({'id' => 333, 'type' => Reward::TYPE_FAMILIAR, 'degree' => 3}),
												   Reward.new({'id' => 444, 'type' => Reward::TYPE_FAMILIAR, 'degree' => 5})]
					})
			end

			before :each do
				UserFriend.delete_all
				User.where(:uid => '1').delete_all
				@user = User.new({:uid => '1', :net => '1'})
				@user.update_attributes({:rewards => {}, :level_instances => {}, :day_counter => 0})
				@user.save
				@original_app_time = Application.time
				Application.instance_variable_set('@time', Time.new)
			end

			after :each do
				Application.instance_variable_set('@time', @original_app_time)
			end

			def request(hash)
				#controller = InitializeController.new(TRequest.new(hash))
				#controller.call
				#controller.instance_variable_get('@response')
				execute_request(hash, InitializeController)
			end

			def get_other_user
				user = User.find_by_uid(100, 1)
				unless(user)
					user = User.new({:uid => '100', :net => '1'})
					user.save
				end
				user
			end

			it "Пользователь извлекается из базы, если ранее существовал" do
				response = request({'net' => @user.net,'uid' => @user.uid})
				response['user']['new'].should be_nil
			end

			it "Пользователь создается, если ранее не существовал" do
				uid = get_unexistable_uid()
				response = request({'net' => @user.net,'uid' => uid,'json' => {'user' => {'uid' => uid, 'net' => @user.net}}})
				response['user']['new'].should_not be_nil
			end

			it "Пользователь версии Embed (не соц. сеть) создается, если ранее не существовал" do
				response = request({'net' => @user.net,'uid' => nil,'json' => {'user' => {'uid' => nil, 'net' => @user.net}}})
				response['user']['new'].should_not be_nil
			end

			it "Ответ на запрос содержит информацию по пользователю" do
				response = request({'net' => @user.net,'uid' => @user.uid})
				#response['user']['id'].should_not be_nil
				response['user']['uid'].should_not be_nil
				#response['user']['net'].should_not be_nil
				response['user']['score'].should_not be_nil
				response['user']['stars'].should_not be_nil
				response['user']['money'].should_not be_nil
				response['user']['level'].should_not be_nil
				#response['user']['roll'].should_not be_nil
				#response['user']['created_at'].should_not be_nil
				#response['user']['updated_at'].should_not be_nil
				response['user']['friends_invited'].should_not be_nil
				response['user']['postings'].should_not be_nil
				response['user']['day_counter'].should_not be_nil
			end

			it "Увеличивается счетчик day_counter" do
				day_counter = request({'net' => @user.net,'uid' => @user.uid})['user']['day_counter']
				Application.instance_variable_set('@time', Application.time + 1.day)
				request({'net' => @user.net,'uid' => @user.uid})['user']['day_counter'].should > day_counter
			end

			it "Обнуляется счетчик day_counter, если пользователь просрочил заход" do
				day_counter = request({'net' => @user.net,'uid' => @user.uid})['user']['day_counter']
				Application.instance_variable_set('@time', Time.new + 2.day)
				request({'net' => @user.net,'uid' => @user.uid})['user']['day_counter'].to_i.should == 0
			end

			it "Не обнуляет счетчик, если пользователь зашел еще раз в течение того же дня" do
				day_counter = request({'net' => @user.net,'uid' => @user.uid})['user']['day_counter']
				request({'net' => @user.net,'uid' => @user.uid})['user']['day_counter'].should == day_counter
			end

			it "Выдается ревард по day_counter" do
				@user.day_counter = 2
				@user.rewards = {}
				@user.save
				Application.instance_variable_set('@time', @user.updated_at + 1.day)
				response = request({'net' => @user.net,'uid' => @user.uid})
				response['user']['rewards'].to_a.index{|k,v| k .to_s == '333'}.should_not be_nil
				response['user']['day_counter'].should == 0
			end

			it "Увеличивается счетчик friends_invited у пригласителя" do
				@inviter = get_other_user()
				friends_invited = @inviter.friends_invited

				uid = get_unexistable_uid()

				request({'net' => @user.net,'uid' => uid,'json' => {'referer' => 100, 'user' => {'uid' => uid, 'net' => @user.net}}})
				@inviter.reload
				@inviter.friends_invited.should == (friends_invited + 1)
			end

			it "Выдаются money пригласителю" do
				@inviter = get_other_user()
				money = @inviter.money

				uid = get_unexistable_uid()

				request({'net' => @user.net,'uid' => uid,'json' => {'referer' => 100, 'user' => {'uid' => uid, 'net' => @user.net}}})
				@inviter.reload
				@inviter.money.should == (money + PUBLIC_CONFIG['INVITE_REWARD_MONEY'].to_i)
			end

			it "Корректно выдаются реварды referrer-у" do
				@inviter = get_other_user()
				@inviter.friends_invited = 0
				@inviter.rewards = {}
				@inviter.save
				friends_invited = @inviter.friends_invited

				uid = get_unexistable_uid()

				request({'net' => @user.net,'uid' => uid,'json' => {'referer' => @inviter.uid, 'user' => {'uid' => uid, 'net' => @user.net}}})

				# проверка, что в первый раз пригласителю выдается ревард-referer (чтобы показать в интерфейсе)
				response = request({'net' => @inviter.net,'uid' => @inviter.uid,'json' => {'user' => {'uid' => @inviter.uid, 'net' => @inviter.net}}})
				response['rewards'].should_not be_nil
				response['rewards'].find{|r| r['id'] == 111}.should_not be_nil

				# на второй и последующий заходы в приложение ревард ен всплывает
				response = request({'net' => @inviter.net,'uid' => @inviter.uid,'json' => {'user' => {'uid' => @inviter.uid, 'net' => @inviter.net}}})
				response['rewards'].should_not be_nil
				response['rewards'].find{|r| r['id'] == 111}.should be_nil
			end

			context "Новый игрок по ссылка" do

				before :each do
					@user_net = @user.net
					@user_uid = @user.uid.to_s
					@user.delete
				end

				it "Если referer друг уже запросил вновь добавляемого игрока как соседа, создаются соседи" do
					@inviter = get_other_user()
					UserFriend.create(:user_uid => @user_uid, :friend_uid => @inviter.uid)

					response = request({'net' => @user_net,'uid' => 1,'json' => {'referer' => @inviter.uid,
																																			 'add_neighbour' => true,
																																			 'friendIds' => [@inviter.uid],
																																			 'user' => {'uid' => 1, 'net' => @user_net}}})

					@inviter.neighbours.size.should == 1
					@inviter.neighbours.first.friend_uid.should == @user_uid
					@user = User.where(:uid => @user_uid).limit(1).first
					@user.neighbours.size.should == 1
					@user.neighbours.first.friend_uid.should == @inviter.uid

					response['neighbours'].should_not be_empty
					response['neighbours'].size.should == 1
					response['neighbours'].first['uid'].to_s.should == @inviter.uid.to_s
				end

				it "Если referer друг еще не запросил нового игрока как соседа, создается запрос в соседи от нового игрока" do
					@inviter = get_other_user()

					request({'net' => @user_net,'uid' => '1','json' => {'referer' => @inviter.uid,
																															'add_neighbour' => true,
																															'friendIds' => [@inviter.uid],
																															'user' => {'uid' => '1', 'net' => @user_net}}})

					@inviter.neighbours.should be_empty
					@inviter.user_friends.size.should == 1
					@inviter.user_friends.first.friend_uid.should == @user_uid
					@user = User.where(:uid => @user_uid).limit(1).first
					@user.neighbours.should be_empty
					@user.user_friends.should be_empty
				end

				it "Если referer и новый игрок не друзья в соц сети (add_neighbour=false), соседство не создается" do
					@inviter = get_other_user()

					request({'net' => @user_net,'uid' => '1','json' => {'referer' => @inviter.uid, 'add_neighbour' => nil, 'user' => {'uid' => '1', 'net' => @user_net}}})

					@inviter.neighbours.should be_empty
					@inviter.user_friends.should be_empty
					@user = User.where(:uid => @user_uid).limit(1).first
					@user.neighbours.should be_empty
					@user.user_friends.should be_empty
				end
			end

			context "Сушествующий игрок по ссылка" do
				it "Если referer друг уже запросил игрока как соседа, создаются соседи" do
					@inviter = get_other_user()
					@user.user_friends.build({:friend_uid => @inviter.uid})
					@user.save

					response = request({'net' => @user.net,'uid' => 1,'json' => {'referer' => @inviter.uid,
																																			 'add_neighbour' => true,
																																			 'friendIds' => [@inviter.uid],
																																			 'user' => {'uid' => 1, 'net' => @user.net}}})

					@inviter.neighbours.size.should == 1
					@inviter.neighbours.first.friend_uid.should == @user.uid
					@user.neighbours.size.should == 1
					@user.neighbours.first.friend_uid.should == @inviter.uid

					response['neighbours'].should_not be_empty
					response['neighbours'].size.should == 1
					response['neighbours'].first['uid'].to_s.should == @inviter.uid.to_s
				end

				it "Если referer друг еще не запросил игрока как соседа, создается запрос в соседи от игрока" do
					@inviter = get_other_user()

					request({'net' => @user.net,'uid' => '1','json' => {'referer' => @inviter.uid,
																															'add_neighbour' => true,
																															'friendIds' => [@inviter.uid],
																															'user' => {'uid' => '1', 'net' => @user.net}}})

					@inviter.neighbours.should be_empty
					@inviter.user_friends.size.should == 1
					@inviter.user_friends.first.friend_uid.should == @user.uid
					@user.neighbours.should be_empty
					@user.user_friends.should be_empty
				end

				it "Если referer и игрок не друзья в соц сети (add_neighbour=false), соседство не создается" do
					@inviter = get_other_user()

					request({'net' => @user.net,'uid' => '1','json' => {'referer' => @inviter.uid, 'add_neighbour' => nil, 'user' => {'uid' => '1', 'net' => @user.net}}})

					@inviter.neighbours.should be_empty
					@inviter.user_friends.should be_empty
					@user.neighbours.should be_empty
					@user.user_friends.should be_empty
				end
			end

			it "Выдаются друзья юзера" do
				@friend = get_other_user()

				@friend.user_friends.create(:friend_uid => @user.uid, :accepted => true)
				@user.user_friends.create(:friend_uid => @friend.uid, :accepted => true)

				response = request({'net' => @user.net,'uid' => @user.uid,'json' => {'friendIds' => [@friend.uid],
																					 'user' => {'uid' => @user.uid, 'net' => @user.net}}})
				response['neighbours'].should_not be_nil
				response['neighbours'].size.should == 1
			end

			it "Если запись о друге(друзьях) удалилась из базы, запрос не ломается" do
				unexistable_uid = get_unexistable_uid()
				@friend = get_other_user()
				@friend.user_friends.create(:friend_uid => @user.uid, :accepted => true)
				@user.user_friends.create(:friend_uid => @friend.uid, :accepted => true)

				response = request({'net' => @user.net,'uid' => @user.uid,'json' => {'friendIds' => [@friend.uid,unexistable_uid],
																					 'user' => {'uid' => @user.uid, 'net' => @user.net}}})
				response['neighbours'].should_not be_nil
				response['neighbours'].size.should == 1
				response['neighbours'][0]['uid'].should == @friend.uid
			end

			it "Инфа о друге не выдается, пока он не сосед (нет запросов)" do
				@friend = get_other_user()

				response = request({'net' => @user.net,'uid' => @user.uid,'json' => {'friendIds' => [@friend.uid],
																																						 'user' => {'uid' => @user.uid, 'net' => @user.net}}})
				response['neighbours'].should_not be_nil
				response['neighbours'].size.should == 0
			end

			it "Инфа о друге не выдается, пока он не сосед (oн послал запрос)" do
				@friend = get_other_user()

				@user.user_friends.create(:friend_uid => @friend.uid)

				response = request({'net' => @user.net,'uid' => @user.uid,'json' => {'friendIds' => [@friend.uid],
																																						 'user' => {'uid' => @user.uid, 'net' => @user.net}}})
				response['neighbours'].should_not be_nil
				response['neighbours'].size.should == 0
			end

			it "Инфа о друге не выдается, пока он не сосед (игрок послал запрос)" do
				@friend = get_other_user()

				@friend.user_friends.create(:friend_uid => @user.uid)

				response = request({'net' => @user.net,'uid' => @user.uid,'json' => {'friendIds' => [@friend.uid],
																																						 'user' => {'uid' => @user.uid, 'net' => @user.net}}})
				response['neighbours'].should_not be_nil
				response['neighbours'].size.should == 0
			end

			it "Выдается энергия, если пришло время выдачи" do
				@user.energy = 2
				@user.energy_last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'] - 5
				@user.save
				request({'net' => @user.net,'uid' => @user.uid})
				@user.reload
				@user.energy.should == 3
			end

			it "Не выдается энергии более максимального значения" do
				@user.energy = PUBLIC_CONFIG['ENERGY_MAX']
				@user.energy_last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'] - 5
				@user.save
				request({'net' => @user.net,'uid' => @user.uid})
				@user.reload
				@user.energy.should == PUBLIC_CONFIG['ENERGY_MAX']
			end

			it "Энергия на максимум, если дата последней выдачи не задана" do
				@user.energy = 2
				@user.energy_last_gain = nil
				@user.save
				request({'net' => @user.net,'uid' => @user.uid})
				@user.reload
				@user.energy.should == PUBLIC_CONFIG['ENERGY_MAX']
				@user.energy_last_gain.should_not be_nil
			end
		end

		describe LevelsController do

			before :all do
				RewardManager.instance.instance_variable_set('@rewards_by_type',
					{
						Reward::TYPE_CARROT_PACK => [Reward.new({'id' => 5, 'type' => Reward::TYPE_CARROT_PACK, 'degree' => 10}),
												   Reward.new({'id' => 6, 'type' => Reward::TYPE_CARROT_PACK, 'degree' => 25})]
					})
				@level = Level.new({
									'conditions' => '<conditions>							\
									<time>100</time>										\
									<fastTime>50</fastTime>									\
									<carrotMin>10</carrotMin> 								\
									<carrotMiddle>15</carrotMiddle> 						\
									<carrotMax>20</carrotMax>								\
									<carrotAll>20</carrotAll></conditions>',
									'number' => 1
									})
				Level.class_variable_set('@@all_head_by_number', {@level.number => @level})
			end

			before :each do
				@user = get_uniq_user
				@user.update_attributes({:rewards => {}, :level_instances => {}, :score => 0})
				@user.save
			end

			def secure_request(hash, roll_invokes = 0)
				execute_secure_request(hash, LevelsController)
			end

			it "Сервер применяет координаты реварда согласно запросу клиента, отвечая такими же" do
				response = secure_request({'net' => @user.net,'uid' => @user.uid,'json' => {
						            	'levelInstance' => {'carrotHarvested' => 20,
															'timeSpended' => 2,
															'version' => 1,
															'number' => 1,
															'success' => true,
															'rewards' => [{'id' => 5, 'x' => 7, 'y' => 13}]}
											}})

				response['levelInstance']['rewards'].should_not be_nil
				response['levelInstance']['rewards'].size.should == 1
				response['levelInstance']['rewards'][0]['x'].should == 7
				response['levelInstance']['rewards'][0]['y'].should == 13

				response['user']['rewards'].should_not be_nil
				response['user']['rewards']['5'].should_not be_nil
				response['user']['rewards']['5']['x'].should == 7
				response['user']['rewards']['5']['y'].should == 13
			end
		end

		describe PostingController do

			before :all do
				RewardManager.instance.instance_variable_set('@rewards_by_type',
					{
						Reward::TYPE_POSTING => [Reward.new({'id' => 5, 'type' => Reward::TYPE_POSTING, 'degree' => 3}),
												   Reward.new({'id' => 6, 'type' => Reward::TYPE_POSTING, 'degree' => 5})]
					})
			end

			before :each do
				@user = get_uniq_user
				@user.update_attributes({:postings => 0, :rewards => {}})
				@user.save
			end

			def secure_request(hash, hack_roll_error = 1)
				if(hack_roll_error)
					roll = @user.roll
					get_roll = nil
					hack_roll_error.times{
						get_roll = @user.get_roll()
					}
					@user.roll = roll
					@user.save
					hash['json'] = {} unless hash['json']
					hash['json']['roll'] = (get_roll * 1000000).to_i
				end
				execute_secure_request(hash, PostingController)
			end

			it "выдает ошибку при неверном roll в запросе, не меняя roll пользователя" do
				roll = @user.roll
				lambda{
					secure_request({'net' => @user.net,'uid' => @user.uid,'json' => {'roll' => 1}}, false)
				}.should raise_error(AuthError, /Roll not correct/)
				@user.reload
				@user.roll.should == roll
			end

			it "выдает ревард, если пользователь заслуживает" do
				@user.postings = 2
				@user.save
				response = secure_request({'net' => @user.net,'uid' => @user.uid}, 2)
				response['reward'].should_not be_nil
				response['reward']['id'].should == 5
			end

			it "не выдает ревард, если пользователь еще не накопил по счетчику" do
				response = secure_request({'net' => @user.net,'uid' => @user.uid}, 1)
				response['reward'].should === nil
				@user.reload
				@user.rewards.to_a.should be_empty
			end

			it "увеличивает счетчик постингов пользователя" do
				secure_request({'net' => @user.net,'uid' => @user.uid}, 1)
				@user.reload
				@user.postings.should == 1
			end
		end

		describe RewardsMoveController do
			before :each do
				@user = get_uniq_user
				@user.rewards = {'12345' => {'id' => 12345, 'x' => 2, 'y' => 3}}
				@user.save
			end

			def request(hash)
				execute_request(hash, RewardsMoveController)
			end

		    it "Выдает логическую ошибку, если такого реварда у пользователя нет" do
				lambda{
					request({'net' => @user.net,'uid' => @user.uid, 'json' => {'rewards' => [{'id' => '54321', 'x' => 11, 'y' => 12}]}})
				}.should raise_error(LogicError, /Unknown reward id \d+/)
			end

			it "Переставляет ревард и выдает его новые координаты" do
				@user.rewards['12345']['x'].should == 2
				@user.rewards['12345']['y'].should == 3
				response = request({'net' => @user.net,'uid' => @user.uid, 'json' => {'rewards' => [{'id' => '12345', 'x' => 11, 'y' => 12}]}})
				response['rewards'].size.should == 1
				response['rewards'][0]['x'].should == 11
				response['rewards'][0]['y'].should == 12
				@user.reload
				@user.rewards['12345']['x'].should == 11
				@user.rewards['12345']['y'].should == 12
			end
		end

		describe UserInfoController do
			it "Выдает ошибку, если формат запроса не верен" do

			end

			it "Выдает ошибку, если запрошенного пользователя не существует" do

			end

			it "Выдает инфу о пользователе корректно" do

			end
		end
		
		describe Stat do
			before :each do
				Stat.delete_all
				@existed_key = 'existed_key'
				@undefined_key = 'undefined_key'
				
				@stat_time = Application.time.to_i
				@stat_time = @stat_time - (@stat_time % 7200)
				
				Stat.create({:name => @existed_key, :value => 1, :time => @stat_time})
			end
			
			it "Значение возвращается (def get)" do
				Stat[@existed_key].should == 1
				Stat[@undefined_key].should == 0
			end
		
			it "Инкремент инициализирует несуществовавший ранее ключ" do
				Stat.inc(@existed_key)
				Stat[@existed_key].should == 2
				
				Stat.inc(@existed_key, 5)
				Stat[@existed_key].should == 7
			end

			it "Инкремент инкрементит существующий ключ правильно" do

			end

			it "Значение записывается (def set)" do

			end
			
			it "Если время изменилось, начинается работа с новой записью БД" do

			end
		end

		describe TutorialController do
			before :each do
				@user = get_uniq_user
				@user.save
			end

			def request(hash)
				execute_request(hash, TutorialController)
			end

		    it "Инкрементить тьюториал" do
				@user.tutorial = 0
				@user.save

				request({'net' => @user.net,'uid' => @user.uid, 'json' => {'tutorial' => 2}})
				@user.reload
				@user.tutorial.should == 2

				request({'net' => @user.net,'uid' => @user.uid, 'json' => {'tutorial' => 5}})
				@user.reload
				@user.tutorial.should == 5
			end

			it "Не позволяет декрементить тьюториал" do
				@user.tutorial = 5
				@user.save

				#lambda{
					response = request({'net' => @user.net,'uid' => @user.uid, 'json' => {'tutorial' => 2}})
					response['status'].should =~ /Tutorial must only increment/
				#}.should raise_error(LogicError, /Tutorial must only increment/)
			end
		end

		describe OfferController do
			before :each do
				@user = get_uniq_user
				@user.offers = 0
				@user['offer_instances'] = nil
				@user.save

				# есть только офферы на втором уровне, с координатами 1,1 и 2,2
				@off1 = Offer.new(1,1,2)
				@off2 = Offer.new(2,2,2)
				OfferManager.instance.instance_variable_set('@offers_by_id', {@off1.id => @off1, @off2.id => @off2})
			end

			def request(hash)
				execute_secure_request(hash, OfferController)
			end

		    it "Если хотя бы 1 оффер зачислен, ошибка не генерируется" do
				response = request({'net' => @user.net,'uid' => @user.uid, 'json' => {
						'offers' => [OfferManager.params_to_id(1, 1, 2), OfferManager.params_to_id(1, 1, 20), OfferManager.params_to_id(100, 100, 2)]}})
				@user.reload
				@user.offers.should == 1
				response['offers_added'].size.should == 1
			end

			it "Выдается список зачисленных офферах" do
				response = request({'net' => @user.net,'uid' => @user.uid, 'json' => {
						'offers' => [OfferManager.params_to_id(1, 1, 2), OfferManager.params_to_id(2, 2, 2)]}})
				@user.reload
				@user.offers.should == 2
				response['offers_added'].size.should == 2
				response['offers_added'].each{|off|
					off.class.should == String
					(off =~ /^1\d{9}$/).should == 0
				}
			end

			it "Если ни один оффер не применен, генерируется ошибка" do
				lambda{
					request({'net' => @user.net,'uid' => @user.uid, 'json' => {
						'offers' => [OfferManager.params_to_id(10, 10, 2), OfferManager.params_to_id(2, 2, 20)]}})
				}.should raise_error(LogicError, /All offers not approved/)
			end

			it "функция user@add_offer_instance работает правильно" do
				@user.add_offer_instance(@off1)
				lambda{
					@user.add_offer_instance(@off1) # 2 раза добавляем один и тот же оффер
				}.should raise_error(LogicError, /Offer id \d+ already created/)
				@user.offer_instances.keys.size.should == 1 # проверяем корректность работы функции add_offer_instance
				@user.offers.should == 1
				@user.save

				@user.add_offer_instance(@off2)
				@user.offer_instances.keys.size.should == 2
				@user.offers.should == 2
			end

			it "Нельзя получить один оффер дважды" do
				@user.add_offer_instance(@off1)
				@user.save

				response = request({'net' => @user.net,'uid' => @user.uid, 'json' => {
					'offers' => [OfferManager.params_to_id(1, 1, 2), OfferManager.params_to_id(2, 2, 2)]}})

				@user.reload
				@user.offers.should == 2
				@user.offer_instances.keys.size.should == 2
				response['offers_added'].size.should == 1
			end

			it "Нельзя получить несуществующий оффер" do
				response = request({'net' => @user.net,'uid' => @user.uid, 'json' => {
					'offers' => [OfferManager.params_to_id(1, 1, 2), OfferManager.params_to_id(2, 30, 2)]}})
				@user.reload
				@user.offers.should == 1
				@user.offer_instances.keys.size.should == 1
				response['offers_added'].size.should == 1
			end
		end

		describe ItemManager do
			before :each do
				@user = get_uniq_user
				@user.customize = nil
				@user.save
			end

			it "Пользовательский метод set_customize/get_customize работает верно" do
				@user.get_customize('roof').should == 0
				@user.set_customize('roof', 15)

				@user.save
				@user.reload

				@user.get_customize('roof').should == 15
			end

			it "Запрос информации о пользователе верно выдает его кастомы" do
				@user.set_customize('roof', 15)
				@user.save

				response = execute_request({'net' => @user.net,'uid' => @user.uid}, InitializeController)
				check_json(response['user']['customize'])['roof'].should == 15

				@user.set_customize('roof', 32)
				@user.save

				response = execute_request({'net' => @user.net,'uid' => @user.uid, 'json' => {'user' => {'uid' =>  @user.uid}}}, UserInfoController)
				check_json(response['info']['customize'])['roof'].should == 32

				@user.reload
				check_json(@user.to_json['customize'])['roof'].should == 32
			end
		end

		describe FriendVisitRewardController do
			before :each do
				UserFriend.delete_all

				@user = get_uniq_user(1)
				@user.save

				@friend = get_uniq_user(2)
				@friend.save

				@original_app_time = Application.time
				Application.instance_variable_set('@time', Time.new)
			end

			after :each do
				Application.instance_variable_set('@time', @original_app_time)
			end

			def request(friend_id)
				execute_secure_request({'net' => @user.net,'uid' => @user.uid, 'json' => {'friend_id' => friend_id}}, FriendVisitRewardController)
			end

			def create_friendship()
				@user.user_friends.create(:friend_uid => @friend.uid, :accepted => true)
				@friend.user_friends.create(:friend_uid => @user.uid, :accepted => true)
			end

			it "Заслуженный ревард выдается (первый раз)" do
				create_friendship()

				inited_money = @user.money
				response = request(@friend.uid)
				response['success'].should be_true

				@user.reload
				@user.money.should == (inited_money + PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i)
			end

			it "Заслуженный ревард выдается (не первый раз)" do
				create_friendship()
				@user.user_friends.where(:friend_uid => @friend.uid.to_s).first.update_attribute('last_daily_bonus', Time.at(10))

				inited_money = @user.money
				response = request(@friend.uid)
				response['success'].should be_true

				@user.reload
				@user.money.should == (inited_money + PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i)
			end

			it "Ревард выдается не чаще заданной величины" do
				create_friendship()
				@user.user_friends.where(:friend_uid => @friend.uid.to_s).first.update_attribute('last_daily_bonus',
								Time.new - PUBLIC_CONFIG['FRIEND_DAILY_BONUS_INTERVAL'] + CONFIG['friend_daily_bonus']['time_buffer'] + 10) # до реварда 10 сек

				inited_money = @user.money
				response = request(@friend.uid)
				response['success'].should be_false

				@user.user_friends.where(:friend_uid => @friend.uid.to_s).first.update_attribute('last_daily_bonus',
								Time.new - PUBLIC_CONFIG['FRIEND_DAILY_BONUS_INTERVAL'] + CONFIG['friend_daily_bonus']['time_buffer'] - 10) # ревард 10 сек как доступен

				response = request(@friend.uid)
				response['success'].should be_true

				@user.reload
				@user.money.should == (inited_money + PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i)
			end

			it "Ревард выдается каждый день, единожды" do
				create_friendship()

				inited_money = @user.money
				request(@friend.uid)

				@user.reload
				@user.money.should == (inited_money + PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i)

				time = Application.time.dup
				Application.instance_variable_set('@time', time + 1.day)
				request(@friend.uid)

				@user.reload
				@user.money.should == (inited_money + PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i * 2)

				Application.instance_variable_set('@time', time + 2.day)
				request(@friend.uid)

				@user.reload
				@user.money.should == (inited_money + PUBLIC_CONFIG['VISIT_REWARD_MONEY'].to_i * 3)
			end

			it "Нельзя получить ревард с несуществующего пользвателя" do
				lambda{
					request(get_unexistable_uid)
				}.should raise_error(LogicError, /User #.+ not friend for #.+/)
			end

			it "Нельзя получить ревард не с друга" do
				lambda{
					request(@friend.uid)
				}.should raise_error(LogicError, /User #.+ not friend for #.+/)
			end

			it "Нельзя получить ревард не с друга (дружба не подтверждена)" do
				create_friendship()
				@user.user_friends.where(:friend_uid => @friend.uid.to_s).first.update_attribute('accepted', false)
				lambda{
					request(@friend.uid)
				}.should raise_error(LogicError, /User #.+ not friend for #.+/)
			end

			it "Нельзя получить ревард более одного раза за день" do
				create_friendship()

				response = request(@friend.uid)
				response['success'].should be_true

				response = request(@friend.uid)
				response['success'].should be_false
			end
		end

		describe "Energy" do
			before(:each) do
				@user.energy = 0
				@user.energy_last_gain = nil
			end

			it "Энергия не выдается, если не проставлен флаг" do
				@user.energy_last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL']
				@user.energy_with_gain().should > 0
				@user.energy.should == 0
				@user.energy_with_gain(true).should > 0
				@user.energy.should > 0
				@user.energy_with_gain().should == @user.energy
			end

			it "Энергия выдается в размере прошедших этапов выдачи" do
				times = 3
				@user.energy_last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'] * times
				@user.energy_with_gain().should == times
			end

			it "Энергия выдается не более, чем макс. значение" do
				@user.energy_last_gain = Time.now - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'] * PUBLIC_CONFIG['ENERGY_MAX'] * 2
				@user.energy_with_gain().should == PUBLIC_CONFIG['ENERGY_MAX']
			end

			it "Энергия не выдается, если время еще не наступило" do
				@user.energy_last_gain = Time.now - 1
				@user.energy_with_gain().should == 0
			end

			it "После выдачи энергии, следующее время выдачи соотносится с предыдущим" do
				@user.energy_last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'] - 10.minutes
				@user.energy_with_gain(true).should > 0
				@user.energy_last_gain.should be_within(1).of(Time.new - 10.minutes)
			end

			it "После использования энергии (если был максимум) с этого момента начинается таймер выдачи" do
				@user.energy = PUBLIC_CONFIG['ENERGY_MAX']
				@user.energy_last_gain = Time.new - 10
				@user.debit_energy().should be_true
				@user.energy_last_gain.should be_within(1).of(Time.new)
			end

			it "Нельзя использовать энергию, если ее не хватает" do
				@user.energy_last_gain = Time.new
				@user.debit_energy().should be_false
			end

			it "Можно использовать энергию, если ее не хватает, но с учетом выдачи ее достаточно" do
				@user.energy_last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL']
				@user.debit_energy().should be_true
			end

			context "Прохождение уровней" do

				before :each do
					@user = get_uniq_user()
				end

				def level_start(levelNumber)
					@user.save
					data = {'net' => @user.net,'uid' => @user.uid, 'json' => {'levelNumber' => levelNumber}}
					execute_request(data, LevelsStartController)
					@user.reload
				end

				it "Старт туториального уровня не снимает энергию" do
					@user.energy = 1
					level_start(1)
					@user.energy.should == 1
				end

				it "Старт ранее пройденного уровня списывает энергию" do
					@user.energy = 1
					@user.level = 3
					level_start(2)
					@user.energy.should == 0
				end

				it "Старт впервые пройденного уровня списывает энергию" do
					@user.energy = 1
					@user.level = 2
					level_start(2)
					@user.energy.should == 0
				end

				it "Нельзя стартовать уровень, если нет энергии" do
					@user.energy = 0
					@user.level = 2
					lambda{
						level_start(2)
					}.should raise_error(/Energy already ended/)
				end

				it "Можно стартовать уровень, если энергия на нуле, но подошло время выдачи новой" do
					@user.energy = 0
					@user.energy_last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL']
					@user.level = 2
					level_start(2)
					@user.energy.should == 0
				end

				it "Нельзя стартовать уровень, недоступный по уровню игрока" do
					@user.energy = 1
					@user.level = 1
					lambda{
						level_start(2)
					}.should raise_error(/Need 2 user level/)
				end

				it "Стартует таймер выдачи энергии, если списали с максимальной" do
					@user.level = 2
					@user.energy = PUBLIC_CONFIG['ENERGY_MAX']
					@user.energy_last_gain = Time.new + 1000
					level_start(2)
					@user.energy_last_gain.should be_within(1).of(Time.new)
				end

				it "Не меняется таймер последенй выдачи, если списали не с максимума" do
					@user.level = 2
					@user.energy = 3
					gain_in_10_min = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'] + 10.minutes
					@user.energy_last_gain = gain_in_10_min.dup
					level_start(2)
					@user.energy_last_gain.should be_within(1).of(gain_in_10_min)
				end

				it "Буфер выдачи в несколько секунд" do
					@user.level = 2
					@user.energy = 0
					last_gain = Time.new - PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'] + 5.seconds
					@user.energy_last_gain = last_gain.dup
					level_start(2)
					@user.energy.should == 0
					@user.energy_last_gain.should be_within(1).of(last_gain + PUBLIC_CONFIG['ENERGY_GAIN_INTERVAL'])
				end
			end
		end

		describe "Neighbours" do
			before :each do
				UserFriend.delete_all

				@user = get_uniq_user(1)
				@user.save

				@friend = get_uniq_user(2)
				@friend.save

				@friend2 = get_uniq_user(3)
				@friend2.save
			end

			def create_relation(from, to, accepted = false)
				from = from.uid if from.is_a?(User)
				to = to.uid if to.is_a?(User)
				User.where(:uid => from).first.user_friends.create(:friend_uid => to, :accepted => accepted)
			end

			def add_neighbours_request(uids, user_id = nil)
				data = {'net' => @user.net,'uid' => (user_id || @user.uid), 'json' => {'friend_uids' => any_to_uids(Array(uids)).to_a.join(',')}}
				execute_request(data, AddNeighboursController)
			end

			def any_to_uids(array)
				result = []
				array.each{|any|
					if any.is_a?(User)
						result << any.uid
					elsif any.is_a?(UserFriend)
						result << any.friend_uid
					end
				}
				result.to_set
			end

			it "user.neighbours возвращает действительных соседей" do
				@user.neighbours.should be_empty
				@user.user_friends.should be_empty

				create_relation(@user, @friend, true)
				create_relation(@user, @friend2, false)

				any_to_uids(@user.neighbours(true)).should == any_to_uids([@friend])
				any_to_uids(@user.user_friends(true)).should == any_to_uids([@friend, @friend2])
			end

			it "Можно добавить более 2-х соседей за раз" do
				create_relation(@user, @friend) # @friend послал запрос @user

				response = add_neighbours_request([@friend, @friend2])
				response['new_friends'].size.should == 1
				response['new_friends'].first['uid'].should == @friend.uid

				any_to_uids(@user.neighbours(true)).should == any_to_uids([@friend])
				any_to_uids(@friend2.user_friends(true)).should == any_to_uids([@user]) # @friend2 видит запрос в соседи
			end

			it "Соседство только взаимное" do
				add_neighbours_request([@friend])

				@user.neighbours(true).should be_empty
				@user.user_friends(true).should be_empty
				@friend.neighbours(true).should be_empty
				any_to_uids(@friend.user_friends(true)).should == any_to_uids([@user]) # запрос
			end

			it "Добавляются в соседи, если запрос взаимен" do
				add_neighbours_request([@friend])
				add_neighbours_request([@user], @friend.uid)

				any_to_uids(@user.neighbours(true)).should == any_to_uids([@friend])
				any_to_uids(@user.user_friends(true)).should == any_to_uids([@friend])
			end

			it "Предупреждение, если послать запрос дважды" do
				response = add_neighbours_request([@friend])
				response['ignored_friend_ids'].should be_nil

				response = add_neighbours_request([@friend])
				response['ignored_friend_ids'].should_not be_nil
				response['ignored_friend_ids'].should == [@friend.uid]
			end

			it "Предупреждение, если послать запрос действительному соседу" do
				create_relation(@user, @friend, true)
				create_relation(@friend, @user, true)

				response = add_neighbours_request([@friend])
				response['ignored_friend_ids'].should_not be_nil
				response['ignored_friend_ids'].should == [@friend.uid]
			end
		end
	end
end

class TRequest
	def initialize(params)
		@params = params
		@params['json'] = JSON.generate(@params['json'] || {}) if @params['json'] == nil || @params['json'].is_a?(Hash)
	end

	def params
		@params
	end
end
