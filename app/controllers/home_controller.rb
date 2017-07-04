require 'uri'
require 'net/http'
require "json"
class HomeController < ApplicationController

  # You can leave the mission method blank, it will render
  # the corresponding static_pages/mission.html.erb by default

  def mission
  end
  
  def index
    businessUnitId = current_person[:store]
    url = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/hourlysummary?businessUnitId=#{businessUnitId}&withDbUpdate=2")
    url2 = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/dailyranking?businessUnitId=#{businessUnitId}")
    url4 = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/hourlysummary?businessUnitId=0858&withDbUpdate=2")
    url3 = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/hourlysummary?businessUnitId=0771&withDbUpdate=2")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http2 = Net::HTTP.new(url2.host, url2.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["cache-control"] = 'no-cache'
    
    request2 = Net::HTTP::Get.new(url2)
    request2["cache-control"] = 'no-cache'

    response = http.request(request)
    response2 = http.request(request2)
    response3 = http.request(Net::HTTP::Get.new(url3))
    response4 = http.request(Net::HTTP::Get.new(url4))
    @hourlysummary = Array[]
    fraddon = JSON.parse(response.read_body)
    fraddon["store"] = "Fraddon (610)"
    newquay = JSON.parse(response4.read_body)
    newquay["store"] = "Newquay (858)"
    newtonabbot = JSON.parse(response3.read_body)
    newtonabbot["store"] = "Newton Abbot (771)"
    @hourlysummary.push(fraddon)
    @hourlysummary.push(newtonabbot)
    @hourlysummary.push(newquay)
    
    @dailyranking = JSON.parse(response2.read_body)

  end

end