require_relative 'craigslist'
module Craigslist
  module Scrapers
    class Apartment < SearchScraper 
      @valid_fields += [:min_bedrooms,:max_bedrooms,:min_bathrooms, 
                        :max_bathrooms] 
      @data_fields = [:data_id, :datetime, :description, :url, :hood, 
                     :price, :bedrooms, :sq_ft]
      @endpoint = 'hhh'

      def preprocess(options)
        super
      end
      
      def _bedrooms(link, options)
        housing = link.css('span.housing').text
        housing = housing.removeWhitespace
        if housing.scan('br').size < 0
          return ''
        else
          return housing.split('br')[0]
        end
      end

      def _sq_ft(link, options)
        sq_ft_raw = link.css('span.housing').text
        housing = sq_ft_raw.removeWhitespace
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
    end
  end
end
