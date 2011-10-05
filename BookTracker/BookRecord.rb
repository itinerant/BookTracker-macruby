#
#  BookRecord.rb
#  BookTracker
#
#  Created by Jon Doud on 10/8/08.
#  Copyright (c) 2011 Itinerant Software Solutions. All rights reserved.
#

class BookRecord

	attr_accessor :properties
    attr_accessor :reader, :title, :author, :genre, :category, :date, :pages, :audiobook
	
	def init
        properties = []
        @reader = ''
        @title = ''
        @author = ''
        @genre = ''
        @category = ''
        @date = ''
        @pages = 0
        @audiobook = false
        
		return self
	end
	
	def to_s
		abToS = (@audiobook == true) ? 'True' : 'False'
		puts "#{@title} by #{@author} read by #{@reader} (#{@genre}/#{@category}, #{@pages}, #{abToS}) [#{@date}]"
	end
end
