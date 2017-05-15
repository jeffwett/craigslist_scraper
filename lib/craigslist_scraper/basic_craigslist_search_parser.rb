module BasicCraigslistSearchParser
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
end

