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
    params.permit(:week, :year)
    if (params[:week] != "" && params[:week] != nil && params[:week] != "NaN")
      if (params[:year] != "" && params[:year] != nil)
        date = Date.commercial(params[:year].to_i, params[:week].to_i, 1)
        @wn = params[:week]
      else
        date = Date.commercial(Date.today.year.to_i, params[:week].to_i, 1)
        @wn = params[:week]
      end
    else
      date = Date.today
      @wn = date.cweek
    end
    @dayparts = ["Overnight", "Open", "Dayshift", "Evening", "No data provided", "Closed"]
    @begin = date.beginning_of_week
    @end = date.end_of_week
    week = Array[]
    movingday = @begin
    week[0] = movingday
    for i in 1..6 do
      movingday = movingday.tomorrow
      week[i] = movingday
    end
    oepe_d = [0,0,0,0]
    ast_d = [0,0,0,0]
    cars_d = [0,0,0,0]
    length = [0,0,0,0]
    array = Array[]
    @ast = 0
    @oepe= 0
    @cars = 0
    empty = Array[]
    storetimes = Hash[]
    Dayparts.where(storeId: current_person.store).all.each do |daypartdef|
      storetimes[daypartdef.daypart_num.to_s] = [daypartdef.start, daypartdef.finish, daypartdef.open]
    end
    week.each_with_index do |day,index|
      empty[index] = [true,true,true,true]
      oepe_d = [0,0,0,0]
      ast_d = [0,0,0,0]
      cars_d = [0,0,0,0]
      length = [0,0,0,0]
      DtsHourly.where(storeId: current_person.store, datestring: week[index].to_s).all.each do |hour|
        case hour.hour
          when storetimes['1'][0]..storetimes['1'][1]
            oepe_d[0] += hour.OEPE*hour.cars
            ast_d[0] += hour.AST*hour.cars
            cars_d[0] += hour.cars
            length[0] = 6
            empty[index][0] = false
          when storetimes['2'][0]..storetimes['2'][1]
            oepe_d[1] += hour.OEPE*hour.cars
            ast_d[1] += hour.AST*hour.cars
            cars_d[1] += hour.cars
            length[1] = 1
            empty[index][1] = false
          when storetimes['3'][0]..storetimes['3'][1]
            oepe_d[2] += hour.OEPE*hour.cars
            ast_d[2] += hour.AST*hour.cars
            cars_d[2] += hour.cars
            length[2] = 9
            empty[index][2] = false
          when storetimes['4'][0]..storetimes['4'][1]
            oepe_d[3] += hour.OEPE*hour.cars
            ast_d[3] += hour.AST*hour.cars
            cars_d[3] += hour.cars
            length[3] = 8
            empty[index][3] = false
          else
            empty[index] = [true,true,true,true]
        end
      end
      for j in 0..3 do
          @ast += ast_d[j]
          @oepe += oepe_d[j]
          @cars += cars_d[j]
          oepe_d[j] /= cars_d[j] if cars_d[j] != 0
          ast_d[j] /= cars_d[j] if cars_d[j] != 0
          array.push([week[index], j, "Example M", oepe_d[j], ast_d[j], cars_d[j]]) if (oepe_d[j] != 0 && ast_d[j] != 0 && storetimes[(j+1).to_s][2] == true)
          array.push([week[index], 4, "", "", "", ""]) if (j == 1 && empty[index][j] == true && storetimes[(j+1).to_s][2] == true)
          array.push([week[index], 5, "", "", "", ""]) if ((storetimes[(j+1).to_s][2] == false) && (oepe_d[j] == 0 && ast_d[j] == 0 && j == 0 && empty[index][j] == false))
        
        end
    end
    if @cars == 0
      @ast = 0
      @oepe = 0
    else
      @ast /= @cars
      @oepe /= @cars
    end
    
    @result = array
  end

  def schedule
    params.permit(:week, :year)
    if (params[:week] != "" && params[:week] != nil)
      if (params[:year] != "" && params[:year] != nil)
        date = Date.commercial(params[:year].to_i, params[:week].to_i, 1)
        @wn = params[:week]
      else
        date = Date.commercial(Date.today.year.to_i, params[:week].to_i, 1)
        @wn = params[:week]
      end
    else
      date = Date.today
      @wn = date.cweek
    end
    @dayparts = ["Overnight", "Open", "Dayshift", "Evening", "No data provided"]
    @begin = date.beginning_of_week
    @end = date.end_of_week
    @week = Array[]
    movingday = @begin
    @week[0] = movingday
    for i in 1..6 do
      movingday = movingday.tomorrow
      @week[i] = movingday
    end
    allnames = Name.all;
    @names = Array[]
    allnames.each do |name|
      @names.push(name) if name.store == current_person.store
    end
  end

  def store
    params.permit(:tab, :year, :week)
    weekly if (params[:tab] == nil || (params[:tab] == "weekly" || params[:tab] == "all"))
    schedule if (params[:tab] != nil && (params[:tab] == "schedule" || params[:tab] == "all"))
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