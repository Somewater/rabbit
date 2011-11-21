# encoding: utf-8
ROOT = File.dirname( File.expand_path( __FILE__ + '../../..') )
ENV['RACK_ENV'] = 'test'
require ::File.expand_path('../../config/environment',  __FILE__)

class AllSpec
	describe "Rabbit" do
		
		before(:each) do
			@user = User.new
		end
		
		after(:each) do
			
		end
		
		describe "Server logic" do
			before(:each) do
				@level = createLevel12345()
				Level.class_variable_set('@@all_head_by_number', {@level.number => @level})
				@levelInstance = LevelInstance.new({'timeSpended' => 10, 'carrotHarvested' => 3, 'success' => true})
				@levelInstance.data = @level
				#Level.stub!()				
				#@user.rewards = [{'c' => 3, 't' => 5, 'v' => 0}]
			end
		
			it "Непройденный уровень не обрабатывается" do
				# очень хороший результат, но с флагом success==false
				@levelInstance.data = {'success' => false, 'timeSpended' => 1, 'carrotHarvested' => 99999}
				ServerLogic.addRewardsToLevelInstance(@user, @levelInstance).size.should == 0
			end
			
			it "Обнаруживается уровень, непройденный по времени" do
			end
			
			it "Обнаруживается уровень, непройденный по морковкам" do
			end
			
			it "Выданные реварды пишутся в юзера, level_instance и возвращаются функцией" do
			end
			
			it "Учитывается предыдущий уровень, результат перезаписывается лучшим" do
				@user.level_instances = [{'c' => 10, 't' => 80, 'v' => 0}]
				@levelInstance.data = {'timeSpended' => 70, 'carrotHarvested' => 12}
				ServerLogic.addRewardsToLevelInstance(@user, @levelInstance)
				@user.level_instances[0]['c'].should == 12
				@user.level_instances[0]['t'].should == 70
			end
			
			it "Выдается ревард за скорость" do
			end
			
			it "Не выдается ревард за скорость повторно" do
			end
			
			it "Попытка выдать CARROT_ALL, если их достаточно собрано и ранее не уровень не проходили" do
			end
			
			it "CARROT_ALL выдается чаще для 3-х звезд, чем для 2-х звезд" do
			end
			
			it "Выдается CARROT_PACK, если достигнут" do
			end
			
			it "Один и тот же CARROT_PACK не выдается дважды" do
			end
			
			it "В поле user.number пишется значение вновь пройденного уровня, если оно выше текущего" do
			end
			
			it "Выдается только ревард соответствующего degree" do
			end
			
			it "Ревард с одним и тем же id не может быть выдан дважды" do
			end
		end
		
		describe "Security" do
			it "Проверка выдает true когда все правильно" do
				
			end
			
			it "Проверка выдает false при ошибке" do
				
			end
		end
	end
end


def createLevel12345
	lvl = Level.new({
		'conditions' => '<conditions>							\
		<time>100</time>										\
		<fastTime>50</fastTime>									\
		<carrotMin>10</carrotMin> 								\
		<carrotMiddle>15</carrotMiddle> 						\
		<carrotMax>20</carrotMax></conditions>',
		'number' => 12345
		})
	lvl
end
