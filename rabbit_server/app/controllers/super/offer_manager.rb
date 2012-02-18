class OfferManager

	@@instance = nil

	def initialize
		@offers_by_id = {}
		create_model
	end

	def self.instance
		unless @@instance
			@@instance = OfferManager.new
		end
		@@instance
	end

	# level: 3, x: 12, y: 56 => 1 003 012 056
	def self.params_to_id(x, y, level)
		(1_000_000_000 + level.to_i * 1000_000 + x.to_i * 1000 + y.to_i).to_s
	end

	# id = [x, y, level]
	def self.id_to_params(id)
		id = id.to_s
		[id[4..6], id[7..9], id[1..3]]
	end

	# Массив ревардов одного типа
	def get_offer_by(x, y, level)
		@offers_by_id[self.class.params_to_id(x, y, level)]
	end

	# Ревард с заданным id
	def get_by_id(id)
		@offers_by_id[id.to_s]
	end

	def all_by_id
		@offers_by_id
	end

	private
	def create_model
		offers = YAML.load(File.read("#{CONFIG_DIR}/offers.yml"))
		(offers || []).each do |level, level_offers|
			level_offers.each do |offer_hash|
				offer = Offer.new(offer_hash['x'].to_i, offer_hash['y'].to_i, level.to_i)
				raise LogicError, "Offer without id: #{offer_hash}" unless offer.id
				raise LogicError, "Dublicate offers: #{offer_hash}" if @offers_by_id[offer.id]
				@offers_by_id[offer.id] = offer
			end
		end
		@offers_by_id
	end
end