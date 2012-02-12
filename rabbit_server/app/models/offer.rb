class Offer
	attr_reader :x, :y, :level, :id

	def initialize(x, y, level, id = nil)
		@x = x.to_i
		@y = y.to_i
		@level = level.to_i
		if(id)
			@id = id.to_s
		else
			@id = OfferManager.params_to_id(x, y, level)
		end
	end

	def to_xml
"<offer id=\"#{@id}\">
	<x>#{@x}</x>
	<y>#{@y}</y>
	<level>#{@level}</level>
</offer>"
	end
end