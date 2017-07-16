
class DtsHourliesController < ApplicationController
  before_action :set_dts_hourly, only: [:show, :edit, :update, :destroy]
  
  # GET /dts_hourlies
  # GET /dts_hourlies.json
  def index
    @dts_hourlies = DtsHourly.all
    
  end

  # GET /dts_hourlies/1
  # GET /dts_hourlies/1.json
  def show
  end

  def url_hourly(businessUnitId)
    return URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/hourlysummary?businessUnitId=#{businessUnitId}&withDbUpdate=2")
  end

  def dts_post
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
        @hourlysummary = Array[]
        stringling = "Store number not supplied."
        respo = JSON.parse('{"error" : true }')
        respo["message"] = stringling
        @hourlysummary.push(respo)
        @dailyranking = nil
    end
  end
  
  def dts
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
    url = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/reporting/getreportdata?storeId=0610&businessDay=2017-07-02&dayPart=Full&reportType=Daily")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["cache-control"] = 'no-cache'

    response = http.request(request)
    @reportdata = JSON.parse(response.read_body)
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def dts_hourly_params
      params['dts_hourly']['datestring'] = params['dts_hourly']['date']
      params.require(:dts_hourly).permit(:date, :datestring, :hour, :cars, :COD1, :COD2, :Cashier, :Presenter, :OEPE, :AST, :TAR_COD1, :TAR_COD2, :TAR_Cashier, :TAR_Presenter, :TAR_OEPE, :TAR_AST)
    end
end
