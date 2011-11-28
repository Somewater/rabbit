# encoding: utf-8
ROOT = File.dirname( File.expand_path( __FILE__ + '../../..') )
ENV['RACK_ENV'] = 'test'
require ::File.expand_path('../../config/environment',  __FILE__)

class AllSpec
	describe "Rabbit" do
		
		before :each do
			@user = User.new
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
												   Reward.new({'id' => 6, 'type' => Reward::TYPE_CARROT_PACK, 'degree' => 200})]
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
									'number' => 1
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
				@levelInstance.data = {'success' => false, 'timeSpended' => 1, 'carrotHarvested' => @conditions['carrotAll']}
				server_logic_process().size.should == 0
				@user.level.should == 1
			end
			
			it "Обнаруживается уровень, непройденный по времени" do
				@user.level.should == 1
				@levelInstance.data = {'timeSpended' => @conditions['time'].to_i + 1}
				server_logic_process().size.should == 0
				@user.level.should == 1
			end
			
			it "Обнаруживается уровень, непройденный по морковкам" do
				@levelInstance.data = {'carrotHarvested' => @conditions['carrotMin'].to_i - 1}
				server_logic_process().size.should == 0
				@user.level.should == 1
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
				RewardManager.instance.get_by_type(Reward::TYPE_CARROT_PACK).each{|r| @user.add_reward_instance(RewardInstance.new(r)) }
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
				# неточность не более 4%
				sum.should be_close(iter / 2, iter / 25)
				graph.each{|k,v| v.should be_close(iter / 10, iter / 25) }
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
			it "Пользователь извлекается из базы, если ранее существовал" do

			end

			it "Пользователь создается, если ранее не существовал" do

			end

			it "Пользователь версии Embed (не соц. сеть) создается, если ранее не существовал" do

			end

			it "Корректно выдаются реварды referrer-у" do

			end

			it "Ответ на запрос содержит информацию по пользователю" do

			end
		end

		describe LevelsController do

		end
	end
end