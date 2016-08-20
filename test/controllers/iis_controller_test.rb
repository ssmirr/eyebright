require 'test_helper'

class IisControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get iis_show_url
    assert_response :success
  end

end
