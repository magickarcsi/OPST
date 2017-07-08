
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
    businessUnitId = params[:businessUnitId]
    url_hourlysummary = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/hourlysummary?businessUnitId=#{businessUnitId}&withDbUpdate=2")
    url_daily = URI("https://dtld-poc.appspot.com/_ah/api/dtldapi/v1/drivethrudashboard/dailyranking?businessUnitId=#{businessUnitId}")
    
    http = Net::HTTP.new(url_daily.host, url_daily.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    http2 = Net::HTTP.new(url_hourlysummary.host, url_hourlysummary.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE

    #response_hourlysummary = http.request(Net::HTTP::Get.new(url_hourlysummary))
    response_daily = http.request(Net::HTTP::Get.new(url_daily))
    
    @hourlysummary = Array[]
    stores = Array[]
    storenames = Array[]
    
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
      @hourlysummary.push(resp)
    end
    
    @dailyranking = daily

    end
  def dts
    businessUnitId = current_person[:store]
    url = url_hourly(businessUnitId)
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
