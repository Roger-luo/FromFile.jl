module A
	export foo, B
	
	function foo()
		"hello"
	end

	function bar()
		"goodbye"
	end
	
	module B
		baz = 5
	end
end

module C
	export quux
	
	function quux()
		"kaboom"
	end
end