require 'craigslist_scraper/apartment'

describe Apartment do
  let!(:apartment) { Apartment.new }
  
  describe ".search" do
    before { apartment.stub(:open).and_return(File.read(File.dirname(__FILE__) + '/mock_craigslist_apartment_data.html')) }
    
    it "returns an array with all the items" do
      apartment.search.length.should == 28 
      apartment.search[0].keys.should == [:data_id, :datetime, :description, :url, :hood, :price, :bedrooms, :sq_ft] 
    end
	
    it "has the right keys " do
      apartment.search[0].keys.should == [:data_id, :datetime, :description, :url, :hood, :price, :bedrooms, :sq_ft] 
    end
	
    it "addes '+' to white space in queries" do
      apartment.should_receive(:open).with("https://denver.craigslist.org/search/hhh?query=studio+apartment")
      apartment.search(city: "denver" , query: { query: "studio apartment" })
    end
    
    it "adds title only filter to url" do
      apartment.should_receive(:open).with("https://denver.craigslist.org/search/hhh?query=studio+apartment&srchType=T")
      apartment.search(city: "denver" , query: { query: "studio apartment", title_only: true })
    end
	  
    it "doesn't filter when title only is false" do
      apartment.should_receive(:open).with("https://denver.craigslist.org/search/hhh?query=studio+apartment")
      apartment.search(city: "denver" , query: { query: "studio apartment" , title_only: false } )
    end
    
    it "exracts the price" do
      apartment.search[0][:price].should == "$2990"
    end
    
    it "builds the correct reference url" do
      city = "sfbay"
      apartment.search(city: city)[0][:url].should == "https://#{city}.craigslist.org/sfc/apa/6126432054.html"
    end

    it "returns [error: {}] if OpenURI::HTTPError is thrown" do
      exception_io = double('io')
      exception_io.stub_chain(:status,:[]).with(0).and_return('302')          
      apartment.stub(:open).with(anything).and_raise(OpenURI::HTTPError.new('',exception_io))

      apartment.search(city: "somewhere").should ==  [{error: "error opening city: somewhere"} ]
    end
  end

  describe "dynamic method search_{cityname}_for" do
    it "calls search for a valid city" do
      Apartment::CITIES.each do |city|
        apartment.should_receive(:search).with(city: city , query: nil)
        
        apartment.send("search_#{city}_for")
      end
    end
    
    it "doesn't call search for an invalid city" do
      expect { apartment.search_yourmamaville_for }.to raise_error(NoMethodError)
    end

    it "passes a query" do
      apartment.should_receive(:search).with(city: "dallas", query: "cowboy hats")
      
      apartment.search_dallas_for("cowboy hats")
    end
  end

  
  describe "dynamic method search_titles_in_{cityname}_for" do
    
    it "calls search for a valid city" do
      Apartment::CITIES.each do |city|
        apartment.should_receive(:search).with(city: city , query: nil , title_only: true )
        
        apartment.send("search_titles_in_#{city}_for")
      end
    end
    
    it "doesn't call search for an invalid city" do
      expect { apartment.search_titles_in_yourmamaville_for }.to raise_error(NoMethodError)
    end
  end

  describe "Array#average_price" do

    it "returns the average price for a search with multiple items" do
      apartment.stub(:search_denver_for).and_return([{price: "3"} , {price: "5"} , {price: "7"}])

      apartment.search_denver_for("uranium").average_price.should == 5
    end

    it "returns 0 for search with no results" do
      apartment.stub(:search_denver_for).and_return([])

      apartment.search_denver_for("uranium").average_price.should == 0
    end

    it "returns average for a search with two items" do
      apartment.stub(:search_denver_for).and_return([{price: "8"} , {price: "12"} ])

      apartment.search_denver_for("uranium").average_price.should == 10
    end

    it "returns the price for a search with one item" do
      apartment.stub(:search_denver_for).and_return([{price: 1}])

      apartment.search_denver_for("uranium").average_price.should == 1
    end

    it "discards nil prices" do
      apartment.stub(:search_denver_for).and_return([{price: 1} , {price: nil}])

      apartment.search_denver_for("uranium").average_price.should == 1
    end

  end
  describe "Array#median_price" do
    it "returns the median price for a search with multiple items" do
      apartment.stub(:search_denver_for).and_return([{price: "1"} , {price: "1000"} , {price: "5"}])
      apartment.search_denver_for("uranium").median_price.should == 5
    end

    it "returns 0 for search with no results" do
      apartment.stub(:search_denver_for).and_return([])
         apartment.search_denver_for("uranium").median_price.should == 0
    end
   
    it "returns median for a search with two items" do
      apartment.stub(:search_denver_for).and_return([{price: "8"} , {price: "12"} ])
   
      apartment.search_denver_for("uranium").median_price.should == 10
    end

    it "returns the price for a search with one item" do
      apartment.stub(:search_denver_for).and_return([{price: 1}])
   
      apartment.search_denver_for("uranium").median_price.should == 1
    end

    it "returns the average of the two middle numbers for an even array" do
      apartment.stub(:search_denver_for).and_return([{price: "1"} , {price: "5"} , {price: "15"} , {price: "10000"}])
      apartment.search_denver_for("uranium").median_price.should == 10
    end
    
    it "discards nil prices" do
      apartment.stub(:search_denver_for).and_return([{price: 1} , {price: nil}])
   
      apartment.search_denver_for("uranium").median_price.should == 1
    end
  end

  describe ".search_all_cities_for" do
    
    it "returns [] for cities with no search results" do
      apartment.stub(:search).with(city: "denver" , query: "something cool" ).and_return([])
      apartment.stub(:search).with(city: "boulder", query: "something cool" ).and_return([])
      stub_const("Cities::CITIES",["denver","boulder"])
      
      apartment.search_all_cities_for("something cool").should == []
    end

    it "returns concatenated items for cities with  search results" do
      apartment.stub(:search).with(city: "denver" , query: "something cool" ).and_return([{in_denver: "something in denver"}])
      apartment.stub(:search).with(city: "boulder", query: "something cool" ).and_return([{in_boulder: "something in boulder"}])
      stub_const("Cities::CITIES",["denver","boulder"])
      
      apartment.search_all_cities_for("something cool").should == [{in_denver: "something in denver"}, {in_boulder: "something in boulder"}]
    end

  end
end

