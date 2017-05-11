require 'nokogiri'
require 'open-uri'
require 'cgi'
require_relative 'cities'

class CraigsList
  include Cities
  
  VALID_FIELDS = [:query, :srchType, :s, :min_price, :max_price, :min_bedrooms, :max_bedrooms, :min_bathrooms, :max_bathrooms, :sort, :postal, :search_distance, :postedToday]
  
  ERRORS = [OpenURI::HTTPError]
  
  def search(options ={})
    options[:query] ||= { query: '' }
		if options[:query][:title_only]
      options[:query][:srchType] = "T"
    end
		uri = "https://#{options[:city]}.craigslist.org/search/hhh?#{to_query(options[:query])}"
    begin
      doc = Nokogiri::HTML(open(uri))
      doc.css('li.result-row').flat_map do |link|
        [
         data_id: link["data-pid"] ,
         datetime:  link.css("time.result-date").attr('datetime').text,
         description:  link.css("a").text,
         url: "https://#{options[:city]}.craigslist.org#{link.css("a")[0]["href"]}",
         hood: link.css("span.result-hood").text,
         price: extract_price(link.css("span.result-price")),
         bedrooms: extract_bedrooms(link.css('span.housing').text),
         sq_ft: extract_sq_ft(link.css('span.housing').text)
        ]
      end
    rescue *ERRORS => e
      [{error: "error opening city: #{options[:city]}"} ]
    end
  end

  def cities
    Cities::CITIES
  end
  
  def method_missing(method,*args)
    super unless Cities::CITIES.include? city ||= extract_city(method)
     
    params = { query: args.first , city: city}
    params.merge!(title_only: true) if /titles/ =~ method
      
    search(params)
  end

  def search_all_cities_for(query)
    Cities::CITIES.flat_map do |city|
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
  
  def extract_price(price_elements)
    if price_elements.size > 0
      price_elements.first.text
    else
      ''
    end
  end

  def remove_whitespace(str)
    str.gsub(/[\s+]*[-]*[\s+]/, "")
  end

  def extract_sq_ft(housing)
    housing = remove_whitespace(housing)
    if housing.scan('ft').size < 0
      return ''
    else
      if housing.scan('br').size < 0
        return housing
      else
        return housing.split('br')[1]
      end
    end
  end

  def extract_bedrooms(housing)
    housing = remove_whitespace(housing)
    if housing.scan('br').size < 0
      return ''
    else
      return housing.split('br')[0]
    end
  end

  def to_query(hsh)
		hsh.select { |k,v| CraigsList::VALID_FIELDS.include? k }.map {|k, v| "#{k}=#{CGI::escape v}" }.join("&")
  end

end
