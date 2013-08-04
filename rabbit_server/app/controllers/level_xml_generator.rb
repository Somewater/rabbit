module LevelXmlGenerator

	@@request_caches = {}

	def self.generate(release)
		request = 'release=' << (release ? 't' : 'f')
		content = @@request_caches[request] ||= begin
			Application.logger.warn("REGENERATE TO #{request}")
			head_levels = Level.all_head
			if(release)
				head_levels.delete_if{|l| l.number > 99}
			end
			levels_xml = head_levels.map{|lvl| lvl.to_xml }
			stories_xml = Story.all_head.map{|story| story.to_xml}
			offers_xml = OfferManager.instance.all_by_id.map{|id, offer| offer.to_xml }
			"<?xml version=\"1.0\" encoding=\"UTF-8\"?><data>
<stories>
#{stories_xml.join("\n")}
</stories>
<levels version=\"0\">
#{levels_xml.join("\n")}
</levels>
<offers version=\"0\">
#{offers_xml.join("\n")}
</offers>
</data>"
			end
		[200,{"Content-Type" => "text/xml; charset=UTF-8"},content]
	end

	def self.clear_cache()
		@@request_caches = {}
	end
end