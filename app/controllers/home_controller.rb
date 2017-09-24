require 'uri'
require 'net/http'
require "json"
require "bson"
class HomeController < ApplicationController
  before_action :require_admin, only: [:setup]
  # You can leave the mission method blank, it will render
  # the corresponding static_pages/mission.html.erb by default
  def setup_dp_do
    
    params.permit(:store, :start => [], :finish => [], :open => {}, :daypart_num => [])
    @par = params.permit!.to_h
    @stores = ["0335","0610","0771","0858","1098","1330"]
    @store = params[:store]
    @par = params.to_h
    @daypart_str = Array[]
    @daypart_str[1] = "Overnight"
    @daypart_str[2] = "Open"
    @daypart_str[3] = "Dayshift"
    @daypart_str[4] = "Evening"
    @bm_names = Hash[] #{"0335" => "Torquay 1", "0610" => "","0771" => "","0858" => "" ,"1098" => "", "1330" => ""}
    @dp_def = Hash[]
    openparam = params[:open]
    @stores.each do |store|
      person = Person.find_by(store: store, position: "Business Manager")
      if person != nil
        @bm_names[store] = person
      else
        @bm_names[store] = nil
      end
      dp_defi = Array[]
      for i in 1..4 do
        if params[:start][i] != ""
          if openparam[(i).to_s] != nil
            dp = Dayparts.new(storeId: params[:store], daypart_num: params[:daypart_num][i-1].to_i, start: params[:start][i-1].to_i, finish: params[:finish][i-1].to_i, open: openparam[(i).to_s])
          else
            dp = Dayparts.new(storeId: params[:store], daypart_num: params[:daypart_num][i-1].to_i, start: params[:start][i-1].to_i, finish: params[:finish][i-1].to_i, open: false)
          end 
        else
          dp = nil
        end 
        if dp == nil
          dp = Dayparts.new(storeId: store, daypart_num: i, start: nil, finish: nil, open: false)
        end
        dp_defi.push(dp)
      end
      @dp_def[store] = dp_defi
    end
  end

  def weekly
  end

  def store
    params.permit(:date)
    if (params[:date] != "" && params[:date] != nil)
      date = Date.parse(params[:date])
    else
      date = Date.today
    end
    
    @begin = date.beginning_of_week
    @end = date.end_of_week
    array = Array[]
    @ast = 0
    @oepe= 0
    @cars = 0
    DtsHourly.where(storeId: current_person.store, :datestring.gte => @begin.to_s, :datestring.lte => @end.to_s).all.each do |hour|
      array.push(hour)
      @ast += (hour.AST*hour.cars)
      @oepe += (hour.OEPE*hour.cars)
      @cars += hour.cars
    end
    if @cars == 0
      @ast = 0
      @oepe = 0
    else
      @ast /= @cars
    @oepe /= @cars
    end
    
    @result = array
    @bm = Person.find_by(store: current_person.store, position: "Business Manager")
  end

  def setup
    @daypart_str = Array[]
    @daypart_str[1] = "Overnight"
    @daypart_str[2] = "Open"
    @daypart_str[3] = "Dayshift"
    @daypart_str[4] = "Evening"
    @stores = ["0335","0610","0771","0858","1098","1330"]
    @store_names = {"0335" => "Torquay 1", "0610" => "Fraddon","0771" => "Newton Abbot","0858" => "Newquay" ,"1098" => "Torquay - Hele Road", "1330" => "Paignton"}
    @bm_names = Hash[] #{"0335" => "Torquay 1", "0610" => "","0771" => "","0858" => "" ,"1098" => "", "1330" => ""}
    @dp_def = Hash[]
    @stores.each do |store|
      person = Person.find_by(store: store, position: "Business Manager")
      if person != nil
        @bm_names[store] = person
      else
        @bm_names[store] = nil
      end
      dp_defi = Array[]
      for i in 1..4 do
        dp = Dayparts.find_by(storeId: store, daypart_num: i)
        if dp == nil
          dp = Dayparts.new(storeId: store, daypart_num: i, start: nil, finish: nil, open: false)
        end
        dp_defi.push(dp)
      end
      @dp_def[store] = dp_defi
    end
  end

  def url_hourly(businessUnitId)
    return URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/hourlysummary?businessUnitId=#{businessUnitId}&withDbUpdate=2")
  end

  def url_reportdata(storeId, date, dayPart, reportType)
    if (dayPart == nil)
      dayPart = "Full"
    end
    if (reportType == nil)
      reportType = "Daily"
    end
    return URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/reporting/getreportdata?storeId=#{storeId}&businessDay=#{date}&dayPart=#{dayPart}&reportType=#{reportType}")

  end
  
  def index
    if (current_person[:store] != nil)
    @@businessUnitId = current_person[:store]
      url_hourlysummary = url_hourly(@@businessUnitId)
      url_daily = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/dailyranking?businessUnitId=#{@@businessUnitId}")
      
      http = Net::HTTP.new(url_daily.host, url_daily.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      http2 = Net::HTTP.new(url_hourlysummary.host, url_hourlysummary.port)
      http2.use_ssl = true
      http2.verify_mode = OpenSSL::SSL::VERIFY_NONE

      response_daily = http.request(Net::HTTP::Get.new(url_daily))
      
      @hourlysummary = Array[]
      stores = Array[]
      storenames = Array[]
      if response_daily.read_body != nil
        daily = JSON.parse(response_daily.read_body)
        daily["items"].each_with_index do |item,index|
          if index>2
          stores.push(item["businessUnitId"])
          storenames.push(item["storeName"])
          end
        end
        for i in 0..stores.length-1
          url = url_hourly(stores[i])
          response_hourly = http2.request(Net::HTTP::Get.new(url))
          resp = JSON.parse(response_hourly.read_body)
          resp["store"] = storenames[i]
          resp["error"] = false
          @hourlysummary.push(resp)
        end
      else
        stringling = "Store #{@@businessUnitId} is not configured."
        respo = JSON.parse('{"error" : true }')
        respo["message"] = stringling
        @hourlysummary.push(respo)
      end
      @dailyranking = daily
    else
        @hourlysummary = Array[]
        stringling = "Store number not supplied."
        respo = JSON.parse('{"error" : true }')
        respo["message"] = stringling
        @hourlysummary.push(respo)
        @dailyranking = nil
    end
  end

  private
    def require_admin
       redirect_to(:root, alert: 'Access Denied.') && return if current_person.try(:admin?) != true
    end
    def log(event)
      ev = Activity.new(uid: current_person.id, event: event, storeId: current_person.store, timestamp: Time.now)
      ev.save
    end
end