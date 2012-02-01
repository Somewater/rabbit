# encoding: utf-8
ROOT = File.dirname( File.expand_path( __FILE__ + '../../..') )
ENV['RACK_ENV'] = 'test'
require ::File.expand_path('../../config/environment',  __FILE__)

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
			}.should raise_error(AuthError, /Unsecured request/)
			request.params['secure'] = controller.secure_digest()

			controller = controller_class.new(request)
			controller.call
			controller.instance_variable_get('@response')
		end

		def get_uniq_user(uid = 1)
			user = User.find_by_uid(uid.to_i,1)
			unless(@user)
				user = User.new({:uid => uid.to_s, :net => '1'})
			end
			user
		end

		before :each do
			@user = User.new({:uid => '1', :level => 2})
		end
		
		after :each do
			
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
				@user.stub!('get_roll').and_return(0.999999)
				rewards = server_logic_process()
				rewards.size.should > 0
				@user.rewards.size.should == rewards.size
				@levelInstance.rewards.size.should == rewards.size
			end
			
			it "Учитывается предыдущий уровень, результат перезаписывается лучшим" do
				@user.level_instances = {@level.number.to_s => {'c' => @conditions['carrotMin'], 't' => @conditions['time'], 'v' => 0}}
				@levelInstance.data = {'timeSpended' => @conditions['time'] - 5, 'carrotHarvested' => @conditions['carrotMin'] + 5}
				server_logic_process()
				@user.level_instances[@level.number.to_s]['c'].should == @levelInstance.carrotHarvested
				@user.level_instances[@level.number.to_s]['t'].should == @levelInstance.timeSpended
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
				@user.stub!('get_roll').and_return(0.999999)
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

				middle_success.should be_close(30, 4)
				max_success.should be_close(90, 10)
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
				sum.should be_close(iter / 2, iter / 20)
				graph.each{|k,v| v.should be_close(iter / 10, iter / 20) }
			end

			it "get_roll() выдает одинаковые числа, при синхронизации roll" do
				user = User.new({'uid' => 5})
				array = []
				100.times{array << user.get_roll()}

				user.roll = 1024 + 5

				100.times{ |i| user.get_roll() == array[i]}
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
				@user = User.all.first
				unless(@user)
					@user = User.new({:uid => '1', :net => '1'})
				end
				@user.update_attributes({:rewards => {}, :level_instances => {}, :day_counter => 0})
				@user.save
				Application.instance_variable_set('@time', Time.new)
			end

			def request(hash)
				controller = InitializeController.new(TRequest.new(hash))
				controller.call
				controller.instance_variable_get('@response')
			end

			def get_unexistable_uid
				user_max_id = (User.maximum(:id) || 0) + 1
				"1-#{user_max_id}"
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
				response['user']['id'].should_not be_nil
				response['user']['uid'].should_not be_nil
				response['user']['net'].should_not be_nil
				response['user']['score'].should_not be_nil
				response['user']['money'].should_not be_nil
				response['user']['level'].should_not be_nil
				response['user']['roll'].should_not be_nil
				response['user']['created_at'].should_not be_nil
				response['user']['updated_at'].should_not be_nil
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
				request({'net' => @user.net,'uid' => @user.uid})['user']['day_counter'].should == '0'
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
				response['user']['day_counter'].should == '0'
			end

			it "Увеличивается счетчик friends_invited у пригласителя" do
				@inviter = get_other_user()
				friends_invited = @inviter.friends_invited

				uid = get_unexistable_uid()

				request({'net' => @user.net,'uid' => uid,'json' => {'referer' => 100, 'user' => {'uid' => uid, 'net' => @user.net}}})
				@inviter.reload
				@inviter.friends_invited.should == (friends_invited + 1)
			end

			it "Корректно выдаются реварды referrer-у" do
				@inviter = get_other_user()
				@inviter.friends_invited = 0
				@inviter.rewards = {}
				@inviter.save
				friends_invited = @inviter.friends_invited

				uid = get_unexistable_uid()

				request({'net' => @user.net,'uid' => uid,'json' => {'referer' => 100, 'user' => {'uid' => uid, 'net' => @user.net}}})

				# проверка, что в первый раз пригласителю выдается ревард-referer (чтобы показать в интерфейсе)
				response = request({'net' => @inviter.net,'uid' => @inviter.uid,'json' => {'user' => {'uid' => @inviter.uid, 'net' => @inviter.net}}})
				response['rewards'].should_not be_nil
				response['rewards'].find{|r| r['id'] == 111}.should_not be_nil

				# на второй и последующий заходы в приложение ревард ен всплывает
				response = request({'net' => @inviter.net,'uid' => @inviter.uid,'json' => {'user' => {'uid' => @inviter.uid, 'net' => @inviter.net}}})
				response['rewards'].should_not be_nil
				response['rewards'].find{|r| r['id'] == 111}.should be_nil
			end

			it "Выдаются друзья юзера" do
				@friend = get_other_user()
				response = request({'net' => @user.net,'uid' => @user.uid,'json' => {'friendIds' => [@friend.uid],
																					 'user' => {'uid' => @user.uid, 'net' => @user.net}}})
				response['friends'].should_not be_nil
				response['friends'].size.should == 1
			end

			it "Если запись о друге(друзьях) удалилась из базы, запрос не ломается" do
				unexistable_uid = get_unexistable_uid()
				@friend = get_other_user()

				response = request({'net' => @user.net,'uid' => @user.uid,'json' => {'friendIds' => [@friend.uid,unexistable_uid],
																					 'user' => {'uid' => @user.uid, 'net' => @user.net}}})
				response['friends'].should_not be_nil
				response['friends'].size.should == 1
				response['friends'][0]['uid'].should == @friend.uid
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

				lambda{
					request({'net' => @user.net,'uid' => @user.uid, 'json' => {'tutorial' => 2}})
				}.should raise_error(LogicError, /Tutorial must only increment/)
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
