
class DtsHourliesController < ApplicationController
  before_action :set_dts_hourly, only: [:show, :edit, :update, :destroy]
  
  # GET /dts_hourlies
  # GET /dts_hourlies.json
  def index
    if current_person.try(:admin?)
      @dts_hourlies = DtsHourly.all
      @stores = @dts_hourlies.uniq{|x| x.storeId}
            
    else
      @all_hourlies = DtsHourly.all
      @dts_hourlies = Array[]
      @all_hourlies.each do |hourly|
        if hourly.storeId == current_person.store
          @dts_hourlies.push(hourly)
        end
      end
      @stores = @dts_hourlies.uniq{|x| x.storeId}
    end
  end

  # GET /dts_hourlies/1
  # GET /dts_hourlies/1.json
  def show
  end

  def daypart_do
    @daypart_arr = Array[]
    @daypart_str = Array[]
    @daypart_str[1] = "Overnight"
    @daypart_str[2] = "Open"
    @daypart_str[3] = "Dayshift"
    @daypart_str[4] = "Evening"
    if (params[:storeId] != "" && params[:storeId] != nil)
      @storeId = params[:storeId]
    else
      @storeId = "0000"
    end
    if (params[:date] != "" && params[:date] != nil)
      @date = params[:date]
    else
      @date = "1960-01-01"
    end
    if (params[:daypart] != "" && params[:daypart] != nil)
      @daypart_num = params[:daypart]
    end
    case @daypart_num.to_i
      when 1 #overnight
        @data = Dayparts.find_by(storeId: @storeId, daypart_num: 1)
        if @data == nil
          @daypart_arr[0] = 0
          @daypart_arr[1] = 5
        else
          @daypart_arr[0] = @data.start
          @daypart_arr[1] = @data.finish
        end
        
      when 2 #open
        @data = Dayparts.find_by(storeId: @storeId, daypart_num: 2)
        if @data == nil
          @daypart_arr[0] = 6
          @daypart_arr[1] = 6
        else
          @daypart_arr[0] = @data.start
          @daypart_arr[1] = @data.finish
        end
      when 3 #dayshift
        @data = Dayparts.find_by(storeId: @storeId, daypart_num: 3)
        if @data == nil
          @daypart_arr[0] = 7
          @daypart_arr[1] = 15
        else
          @daypart_arr[0] = @data.start
          @daypart_arr[1] = @data.finish
        end
      when 4 #evening
        @data = Dayparts.find_by(storeId: @storeId, daypart_num: 4)
        if @data == nil
          @daypart_arr[0] = 16
          @daypart_arr[1] = 23
        else
          @daypart_arr[0] = @data.start
          @daypart_arr[1] = @data.finish
        end
      else
        
        @daypart_arr[0] = 24
        @daypart_arr[1] = 24
    end
    array = Array[]
    @ast = 0
    @oepe = 0
    @avg_ast = 0.0
    @avg_oepe = 0.0
    @cars = 0
    log("Daypart read: (#{@storeId}) #{@date} #{@daypart_str[@daypart_num.to_i]}")
    DtsHourly.where(storeId: @storeId, datestring: @date, :hour.gte => @daypart_arr[0], :hour.lte => @daypart_arr[1]).all.each do |hour|
      array.push(hour)
      @ast += hour.AST
      @oepe += hour.OEPE 
      @cars += hour.cars
    end  
    @return = array
    if ((@daypart_arr[1]-@daypart_arr[0]+1) != 0)
      @avg_ast = @ast/(@daypart_arr[1]-@daypart_arr[0]+1)
      @avg_oepe = @oepe/(@daypart_arr[1]-@daypart_arr[0]+1)
    else
      @avg_ast = 0
      @avg_oepe = 0
    end
  end

  def daypart
    
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

  def dts_do
    if (params[:businessUnitId] != nil)
      @@businessUnitId = params[:businessUnitId]
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
  end


  def dts
    
  end
  
  def dts_hourlies_live_do
    @@businessUnitId = current_person[:store]
    if (params[:storeId] != nil && params[:storeId] != "")
      if (params[:date] != nil && params[:date] != "")
        @storeid = params[:storeId]
        @date = Time.parse(params[:date])
        @response = reportdata(@storeid, @date, "Full", "Daily")
        if @response["success"] == true
          data = JSON.parse(@response["result"])
          data = Hash[ data.collect {|k,v| [k.to_i, v] } ]
          @reportdata = data.sort
          stringstore = @storeid.to_s
          respon = JSON.parse('{"error" : false }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          @info = respon
        else
          respon = JSON.parse('{"error" : true }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          respon["message"] = @response["result"]
          @info = respon
        end
      else
        @storeid = params[:storeId]
        @date = Time.now
        @response = reportdata(@storeid, @date, "Full", "Daily")
        if @response["success"] == true
          data = JSON.parse(@response["result"])
          data = Hash[ data.collect {|k,v| [k.to_i, v] } ]
          @reportdata = data.sort
          stringstore = @storeid.to_s
          respon = JSON.parse('{"error" : false }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          @info = respon
        else
          respon = JSON.parse('{"error" : true }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          respon["message"] = @response["result"]
          @info = respon
        end
      end
    else
      if (params[:date] != nil && params[:date] != "")
        @storeid = @@businessUnitId
        @date = Time.parse(params[:date])
        @response = reportdata(@storeid, @date, "Full", "Daily")
        if @response["success"] == true
          data = JSON.parse(@response["result"])
          data = Hash[ data.collect {|k,v| [k.to_i, v] } ]
          @reportdata = data.sort
          stringstore = @@businessUnitId.to_s
          respon = JSON.parse('{"error" : false }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          @info = respon
        else
          respon = JSON.parse('{"error" : true }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          respon["message"] = @response["result"]
          @info = respon
        end
      else
        @storeid = @@businessUnitId
        @date = Time.now
        @response = reportdata(@storeid, @date, "Full", "Daily")
        if @response["success"] == true
          data = JSON.parse(@response["result"])
          data = Hash[ data.collect {|k,v| [k.to_i, v] } ]
          @reportdata = data.sort
          stringstore = @@businessUnitId.to_s
          respon = JSON.parse('{"error" : false }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          @info = respon
        else
          respon = JSON.parse('{"error" : true }')
          respon["store"] = stringstore
          respon["date"] = @date.to_date
          respon["message"] = @response["result"]
          @info = respon
        end
      end
    end
    if @reportdata != nil
      @reportdata.each_with_index do |hour,index|
        if (hour[1]["COD 2"] == nil)
          @dtshourly = DtsHourly.new(date: @date, hour: hour[0].to_i, cars: hour[1]["Cars"].to_i, COD1: hour[1]["COD 1"].to_i, HHOT: hour[1]["HHOT"].to_i, Cashier: hour[1]["Cashier"].to_i, Presenter: hour[1]["Presenter"].to_i, OEPE: hour[1]["OE-PE"].to_i, AST: hour[1]["AST"].to_i, TAR_COD1: hour[1]["TAR_COD 1"].to_i, TAR_HHOT: hour[1]["TAR_HHOT"].to_i, TAR_Cashier: hour[1]["TAR_Cashier"].to_i, TAR_Presenter: hour[1]["TAR_Presenter"].to_i, TAR_OEPE: hour[1]["TAR_OE-PE"].to_i, TAR_AST: hour[1]["TAR_AST"].to_i, datestring: @date.to_date, storeId: @storeid.to_s)
        
        end
        if (hour[1]["HHOT"] == nil)
          @dtshourly = DtsHourly.new(date: @date, hour: hour[0].to_i, cars: hour[1]["Cars"].to_i, COD1: hour[1]["COD 1"].to_i, COD2: hour[1]["COD 2"].to_i, Cashier: hour[1]["Cashier"].to_i, Presenter: hour[1]["Presenter"].to_i, OEPE: hour[1]["OE-PE"].to_i, AST: hour[1]["AST"].to_i, TAR_COD1: hour[1]["TAR_COD 1"].to_i, TAR_COD2: hour[1]["TAR_COD 2"].to_i, TAR_Cashier: hour[1]["TAR_Cashier"].to_i, TAR_Presenter: hour[1]["TAR_Presenter"].to_i, TAR_OEPE: hour[1]["TAR_OE-PE"].to_i, TAR_AST: hour[1]["TAR_AST"].to_i, datestring: @date.to_date, storeId: @storeid.to_s)

        end
        if (DtsHourly.find_by(datestring: Time.now.to_date.to_s, hour: hour[0].to_i, storeId: @storeid.to_s) == nil)
          @dtshourly.save
        end
      end
    end
    
  end
  
  def dts_hourlies_live
    
  end
  
  def reportdata(storeId, date, dayPart, reportType)
    url = url_reportdata(storeId, date, dayPart, reportType)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["cache-control"] = 'no-cache'

    response = http.request(request)
    data = JSON.parse(response.read_body)
    return data
  end

  # GET /dts_hourlies/new
  def new
    @dts_hourly = DtsHourly.new
  end

  # GET /dts_hourlies/1/edit
  def edit
  end

  # POST /dts_hourlies
  # POST /dts_hourlies.json
  def create

    respond_to do |format|
      if @dts_hourly.save
        format.html { redirect_to @dts_hourly, notice: 'Dts hourly was successfully created.' }
        format.json { render :show, status: :created, location: @dts_hourly }
      else
        format.html { render :new }
        format.json { render json: @dts_hourly.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dts_hourlies/1
  # PATCH/PUT /dts_hourlies/1.json
  def update
    dts_hourly_params[:datestring] = dts_hourly_params[:date]
    respond_to do |format|
      if @dts_hourly.update(dts_hourly_params)
        format.html { redirect_to @dts_hourly, notice: 'Dts Hourly was successfully updated.' }
        format.json { render :show, status: :ok, location: @dts_hourly }
      else
        format.html { render :edit }
        format.json { render json: @dts_hourly.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dts_hourlies/1
  # DELETE /dts_hourlies/1.json
  def destroy
    @dts_hourly.destroy
    respond_to do |format|
      format.html { redirect_to dts_hourlies_url, notice: 'Dts Hourly was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dts_hourly
      @dts_hourly = DtsHourly.find(params[:id])
    end

    def datestringify
      self.datestring = self.date
    end

    def log(event)
      ev = Activity.new(uid: current_person.id, event: event, storeId: current_person.store, timestamp: Time.now)
      ev.save
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dts_hourly_params
      params['dts_hourly']['datestring'] = params['dts_hourly']['date']
      params.require(:dts_hourly).permit(:date, :datestring, :hour, :cars, :COD1, :COD2, :Cashier, :Presenter, :OEPE, :AST, :TAR_COD1, :TAR_COD2, :TAR_Cashier, :TAR_Presenter, :TAR_OEPE, :TAR_AST, :storeId, :HHOT, :TAR_HHOT)
    end
end
