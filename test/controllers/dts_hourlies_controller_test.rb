require 'test_helper'

class DtsHourliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dts_hourly = dts_hourlies(:one)
  end

  test "should get index" do
    get dts_hourlies_url
    assert_response :success
  end

  test "should get new" do
    get new_dts_hourly_url
    assert_response :success
  end

  test "should create dts_hourly" do
    assert_difference('DtsHourly.count') do
      post dts_hourlies_url, params: { dts_hourly: { AST: @dts_hourly.AST, COD1: @dts_hourly.COD1, COD2: @dts_hourly.COD2, Cashier: @dts_hourly.Cashier, OE-PE: @dts_hourly.OE-PE, Presenter: @dts_hourly.Presenter, TAR_AST: @dts_hourly.TAR_AST, TAR_COD1: @dts_hourly.TAR_COD1, TAR_COD2: @dts_hourly.TAR_COD2, TAR_Cashier: @dts_hourly.TAR_Cashier, TAR_OE-PE: @dts_hourly.TAR_OE-PE, TAR_Presenter: @dts_hourly.TAR_Presenter, cars: @dts_hourly.cars, hour: @dts_hourly.hour } }
    end

    assert_redirected_to dts_hourly_url(DtsHourly.last)
  end

  test "should show dts_hourly" do
    get dts_hourly_url(@dts_hourly)
    assert_response :success
  end

  test "should get edit" do
    get edit_dts_hourly_url(@dts_hourly)
    assert_response :success
  end

  test "should update dts_hourly" do
    patch dts_hourly_url(@dts_hourly), params: { dts_hourly: { AST: @dts_hourly.AST, COD1: @dts_hourly.COD1, COD2: @dts_hourly.COD2, Cashier: @dts_hourly.Cashier, OE-PE: @dts_hourly.OE-PE, Presenter: @dts_hourly.Presenter, TAR_AST: @dts_hourly.TAR_AST, TAR_COD1: @dts_hourly.TAR_COD1, TAR_COD2: @dts_hourly.TAR_COD2, TAR_Cashier: @dts_hourly.TAR_Cashier, TAR_OE-PE: @dts_hourly.TAR_OE-PE, TAR_Presenter: @dts_hourly.TAR_Presenter, cars: @dts_hourly.cars, hour: @dts_hourly.hour } }
    assert_redirected_to dts_hourly_url(@dts_hourly)
  end

  test "should destroy dts_hourly" do
    assert_difference('DtsHourly.count', -1) do
      delete dts_hourly_url(@dts_hourly)
    end

    assert_redirected_to dts_hourlies_url
  end
end
