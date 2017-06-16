require 'uri'
require 'ping'

def check_vars(name,url)

  returns = []

  begin
    uri = URI.parse(url)
    
    uri_url = "#{uri.scheme}://#{uri.host}"
    url_return = `wget -O/dev/null -q "#{uri_url}" && echo "1" || echo "0"`

    if url_return[0] != 49 # 1
      returns << :url_not_exist
    end
  rescue URI::InvalidURIError
    returns << :url_invalid
  end
  
  
  
  if name.length < 1
    returns << :no_name
  end
  
  if name =~ /.*\/.*/
    returns << :name_slash
  end
  
  if returns.empty?
    return true
  else
    return returns
  end
end

def err_check(name,url)
  vc = check_vars(name,url)
  if vc == true
    yield if block_given?
    return "",""
  end
  
  url_messages = []
  name_messages = []
  
  vc.each do |err|
    case err
      when :url_invalid
        url_messages << "invalid url."
      when :url_not_exist
        url_messages << "site doesn't exist."
      when :no_name
        name_messages << "please specify a name."
      when :name_slash
        name_messages << "names cannot contain slashes."
    end
  end
  
  return [name_messages.join(" and "), url_messages.join(" and ")]
  
  
end