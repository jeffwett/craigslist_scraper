require 'nokogiri'
require 'open-uri'
require 'cgi'
require_relative 'cities'
require_relative 'util'
require_relative 'common'
module Craigslist 
  module Scrapers 
    class SearchScraper 
      include Craigslist::Cities
      include Craigslist::Scrapers::Common 
      include ClassLevelInheritableAttributes
      inheritable_attributes :valid_fields, :data_fields, :endpoint 
      
      @valid_fields = [:query, :srchType, :s, :min_price, :max_price, 
                      :sort, :postal, :search_distance, :postedToday]
      @data_fields = [:data_id, :datetime, :description, :url, :hood, :price]
      @endpoint = 'sss'

      ERRORS = [OpenURI::HTTPError]

      def valid_fields
        self.class.methods.grep
      end

      def _data_id(link, options)
        link["data-pid"]
      end

      def preprocess(options)
        if options[:query][:posted_today]
          options[:query][:postedToday] = 'T'
        end
        if options[:query][:title_only]
          options[:query][:srchType] = 'T'
        end
      end

      def search(options={})
        options[:query] ||= { query: '' }
        preprocess(options)
        params = to_query(options[:query]) 
        base_url = "https://#{options[:city]}.craigslist.org/search"
        uri = "#{base_url}/#{self.class.endpoint}?#{params}"
        puts uri
        begin
          doc = Nokogiri::HTML(open(uri))
          doc.css('li.result-row').flat_map do |link|
            data = {}
            self.class.data_fields.map do |field|
              data[field] = self.send("_#{field}", link, options) 
            end
            data
          end
        rescue *ERRORS => e
          [{error: "error opening city: #{options[:city]}"} ]
        end
      end

      def cities
        Cities::CITIES
      end
      
      def method_missing(method,*args)
        super unless cities.include? city ||= extract_city(method)
         
        params = { query: args.first , city: city}
        params.merge!(title_only: true) if /titles/ =~ method
          
        search(params)
      end

      def search_all_cities_for(query)
        cities.flat_map do |city|
          search(city: city , query: query)
        end
      end
      
      Array.class_eval do
        def average_price
          reject! { |item| item[:price] == nil }
          return 0 if empty?

          price_array.reduce(:+) / size 
        end

        def median_price
          reject! { |item| item[:price] == nil }

          return 0 if empty?
          return first[:price].to_i if size == 1

          if size.odd?
            price_array.sort[middle]
          else
            price_array.sort[middle - 1.. middle].reduce(:+) / 2
          end
        end

      private

        def middle
          size / 2
        end

        def price_array
          flat_map { |item| [item[:price]] }.map { |price| price.to_i }
        end
      end
      
      private

      def extract_city(method_name)
        if /titles/ =~ method_name
          method_name.to_s.gsub("search_titles_in_","").gsub("_for","")
        else
          method_name.to_s.gsub("search_","").gsub("_for","")
        end
      end
      
      def to_query(hsh)
        hsh.select { |k,v| self.class.valid_fields.include? k }.map {|k, v| "#{k}=#{CGI::escape v}" }.join("&")
      end
    end
  end
end
