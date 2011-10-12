class Execution
	require 'pty'
	require 'expect'
	
	def initialize(cmd, pattern = nil, pw = nil)
		@reader, @writer, @pid = PTY.spawn(cmd)
		result=@reader.expect("")
		@writer.puts pw if pw
		@reader.expect(pattern ? pattern : "*4*~@%&", pattern ? 60 : 1)	
	end
	
	def cmd(command, timeout = 1, pattern = nil)
		@writer.puts command
		answ = nil
		if(pattern)
			answ = @reader.expect(patter, timeout)
		else
			answ = ""
			while c = @reader.expect("", timeout)
				answ += c[0]
			end	
		end
		answ
	end
end
