class Execution
	require 'pty'
	require 'expect'
	
	def initialize(cmd, pattern = nil, pw = nil)
		@reader, @writer, @pid = PTY.spawn(cmd)
		result=@reader.expect("")
		@writer.puts pw if pw
		@reader.expect(pattern ? pattern : "*4*~@%&", pattern ? 60 : 1)	
	end
	
	def cmd(command, timeout = 1)
		@writer.puts command
		answ = ""
		while c = @reader.expect("", timeout)
			answ += c[0]
		end	
		answ
	end
end