require_relative 'craigslist'
class Apartment < CraigsList
  @valid_fields = [:query, :srchType, :s, :min_price, :max_price, 
                  :min_bedrooms, :max_bedrooms, :min_bathrooms, 
                  :max_bathrooms, :sort, :postal, :search_distance, 
                  :postedToday]
  @data_fields = [:data_id, :datetime, :description, :url, :hood, 
                 :price, :bedrooms, :sq_ft]
  @endpoint = 'hhh'

  def _datetime(link, options)
    link.css("time.result-date").attr("datetime").text
  end

  def _description(link, options)
    link.css("a").text
  end

  def _url(link, options)
    base_url = "https://#{options[:city]}.craigslist.org"
    "#{base_url}#{link.css("a")[0]["href"]}" 
  end

  def _hood(link, options)
    link.css("span.result-hood").text
  end

  def _price(link, options)
    price_elements = link.css("span.result-price")
    if price_elements.size > 0
      price_elements.first.text
    else
      ''
    end
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
