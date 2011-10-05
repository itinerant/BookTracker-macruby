#
#  AppDelegate.rb
#  BookTracker
#
#  Created by Jon Doud on 9/21/11.
#  Copyright 2011 Itinerant Software Solutions. All rights reserved.
#
require 'date'
require 'BookRecord'
require 'rubygems'
require 'sqlite3'

class AppDelegate
  attr_accessor :window
  attr_accessor :addReader, :addTitle, :addAuthor, :addGenre, :addCategory, :addMonth, :addAudiobook, :addPages
	attr_accessor :filterReader, :filterTitle, :filterAuthor, :filterGenre, :filterCategory, :filterMonth, :filterYear, :filterAudiobook
	attr_accessor :table
	attr_accessor :bookArray
	attr_accessor :totalBooks, :totalPages, :totalAudiobooks
  attr_accessor :dbh
  
  def connectDB
    # get application support folder
    paths = NSSearchPathForDirectoriesInDomains( NSApplicationSupportDirectory, NSUserDomainMask, true )
    dir = paths[0] + "/BookTracker"
    
    # create directory and database if not exist
    Dir::mkdir(dir) if !FileTest::directory?(dir)
    db = SQLite3::Database.new dir + "/booktracker.sqlite"
    
    # create tables is new database
    res = db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    found = false
    res.each do |r|
      found = true if r[0].eql?("books")
    end
    db.execute("CREATE TABLE books(id INTEGER NOT NULL, reader TEXT NOT NULL, title TEXT NOT NULL, author TEXT NOT NULL, genre TEXT NOT NULL, category TEXT, month TEXT, pages INTEGER, audiobook INTEGER, PRIMARY KEY (id) )") if !found
    
    return db
  end
  
  def awakeFromNib
    # set current and last month
		curMonth = DateTime.now
		if curMonth.month == 1
			@lastMonthNumber = 12
			@lastYearNumber = curMonth.year - 1
      else
			@lastMonthNumber = curMonth.month - 1
			@lastYearNumber = curMonth.year
		end
		lastMonth = Date.new(@lastYearNumber, @lastMonthNumber, 1)
		dateFormat = '%b %Y'		
		@months = ["#{curMonth.strftime(dateFormat)}", "#{lastMonth.strftime(dateFormat)}"]
		@addMonth.removeAllItems
		@addMonth.addItemsWithTitles(@months)
		
		# set control data
    setControlData
		setTableData(nil)		
	end
	
	def setTableData(sender)
    # build sql query
    qualifiers = []
    query = "select reader, title, author, genre, category, month, pages, audiobook from books"
    qualifiers << "reader = '#{@filterReader.titleOfSelectedItem}'" if @filterReader.titleOfSelectedItem != ""
    qualifiers << "title like '%#{@filterTitle.stringValue}%'" if @filterTitle.stringValue != ""
    qualifiers << "author like '%#{@filterAuthor.stringValue}%'" if @filterAuthor.stringValue != ""
    qualifiers << "genre like '%#{@filterGenre.stringValue}%'" if @filterGenre.stringValue != ""
    qualifiers << "category like '%#{@filterCategory.stringValue}%'" if @filterCategory.stringValue != ""
    qualifiers << "month like '%#{@filterMonth.titleOfSelectedItem}%'" if @filterMonth.titleOfSelectedItem != ""
    qualifiers << "month like '%#{@filterYear.titleOfSelectedItem}%'" if @filterYear.titleOfSelectedItem != ""
    qualifiers << "audiobook = 1" if @filterAudiobook.selectedCell.title == "Yes"
    qualifiers << "audiobook = 0" if @filterAudiobook.selectedCell.title == "No"
    
    if qualifiers.size == 1
      query += " where " + qualifiers[0]
    end
    if qualifiers.size > 1
      query += " where " + qualifiers[0]
      qualifiers.delete_at(0)
      qualifiers.each { |q| query =  query + " and " + q }
    end
    
    # clear data
    oldArray = @bookArray.arrangedObjects
    @bookArray.removeObjects(oldArray)
    
    # load table
    bookTemp = [];
    allBooks = '', curBooks = ''
    begin
      # connect to the database
      dbh = connectDB
      res = dbh.execute("select count(0) from books")
      res.each {|row| allBooks = row }
      # get books
      res = dbh.execute(query)
      res.each do |row| 	
        record = BookRecord.new                 
        record.reader = row[0]
        record.title = row[1]
        record.author = row[2]
        record.genre = row[3]
        record.category = row[4]
        record.date = row[5]
        record.pages = row[6]
        record.audiobook = row[7]
        bookTemp << record
      end
      curBooks = res.count
      # disconnect from server
      dbh.close if dbh
    end
    @bookArray.addObjects(bookTemp)
    
    # set totals fields
    @totalBooks.setStringValue("Showing #{curBooks} out of #{allBooks.to_s.sub(/\[/, '').sub(/\]/, '')} books")
    sum = 0
    count = 0
    bookTemp.each do |r| 
      sum += r.pages.to_i
      count += 1 if r.audiobook == '1'
    end
    sum = sum.to_s.gsub(/(\d)(?=\d{3}+$)/, '\1,')
    @totalPages.setStringValue("Pages: #{sum}")
    @totalAudiobooks.setStringValue("#{count} audiobooks")
    
    # select last item in list
    @table.scrollRowToVisible(@table.numberOfRows-1) if @table.numberOfRows > 0
  end
  
  def setControlData
    @authorList = []
    @genreList = []
    @categoryList = []
    
    begin
      # connect to the database
      dbh = connectDB
      # get authors
      res = dbh.execute("select distinct author from books order by author")
      res.each {|row| @authorList << row.to_s.sub(/\["/, '').sub(/"\]/, '') }
      # get genres
      res = dbh.execute("select distinct genre from books order by genre")
      res.each {|row| @genreList << row.to_s.sub(/\["/, '').sub(/"\]/, '') }
      # get categories
      res = dbh.execute("select distinct category from books order by category")
      res.each {|row| @categoryList << row.to_s.sub(/\["/, '').sub(/"\]/, '') }
      # disconnect from server
      dbh.close if dbh
    end
    
    # authors
    @addAuthor.removeAllItems
    @addAuthor.addItemsWithObjectValues(@authorList)
    
    # genres
    @addGenre.removeAllItems
    @addGenre.addItemsWithObjectValues(@genreList)
    
    # categories
    @addCategory.removeAllItems
    @addCategory.addItemsWithObjectValues(@categoryList)
  end
  
  def clickBook(sender)
    @addTitle.setStringValue(@bookArray.selectedObjects[0].title)
    @addAuthor.setStringValue(@bookArray.selectedObjects[0].author)
    @addGenre.setStringValue(@bookArray.selectedObjects[0].genre)
    @addCategory.setStringValue(@bookArray.selectedObjects[0].category)
    @addAudiobook.setState(@bookArray.selectedObjects[0].audiobook.to_i)
    @addPages.setStringValue(@bookArray.selectedObjects[0].pages.to_s)
  end
  
  def addBook(sender)
    if ((@addReader.titleOfSelectedItem == "") or (@addTitle.stringValue == "") or (@addAuthor.stringValue == "") or
        (@addGenre.stringValue == "") or ((@addAudiobook.state == 0) and (@addPages.stringValue == "")))
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle("OK")
      alert.setMessageText("Missing required fields!\n\nThe following fields are required:\nReader\nTitle\nAuthor\nGenre\n\nand one of\nPages or Audiobook")
      alert.runModal
      elsif @addPages.stringValue.match(/\D/)
      alert = NSAlert.alloc.init
      alert.addButtonWithTitle("OK")
      alert.setMessageText("The Pages field must be a valid number.")
      alert.runModal
      else
      begin
        # connect to the database
        dbh = connectDB
        
        # support quote characters
        titleTemp = @addTitle.stringValue
        titleTemp = titleTemp.gsub("'", "''")
        authorTemp = @addAuthor.stringValue
        authorTemp = authorTemp.gsub("'", "''")
        genreTemp = @addGenre.stringValue
        genreTemp = genreTemp.gsub("'", "''")
        categoryTemp = @addCategory.stringValue			
        categoryTemp = categoryTemp.gsub("'", "''")
        pagesTemp = @addPages.stringValue
        pagesTemp = 0 if pagesTemp == ''
        
        # build query
        query = "insert into books (reader, title, author, genre, category, month, pages, audiobook)"
        query += " values ('#{@addReader.titleOfSelectedItem}', '#{titleTemp}', '#{authorTemp}', '#{genreTemp}',"
        query += " '#{categoryTemp}', '#{@addMonth.titleOfSelectedItem}', #{pagesTemp}, #{@addAudiobook.state})"
        dbh.execute(query)
        # disconnect from server
        dbh.close if dbh
      end
      
      # clear add fields
      @addTitle.setStringValue("")
      @addAuthor.setStringValue("")
      @addGenre.setStringValue("")
      @addCategory.setStringValue("")
      @addAudiobook.setState(0)
      @addPages.setStringValue("")
      
      # reset data
      setControlData
      setTableData(nil)
    end
  end
  
  def clearFilter(sender)
    @filterReader.setObjectValue(0)
    @filterTitle.setStringValue("")
    @filterAuthor.setStringValue("")
    @filterGenre.setStringValue("")
    @filterCategory.setStringValue("")
    @filterMonth.setObjectValue(0)
    @filterYear.setObjectValue(0)
    @filterAudiobook.selectCellWithTag(3)
    setTableData(sender)
  end
  
  def windowWillClose(sender)
    exit
  end
end

