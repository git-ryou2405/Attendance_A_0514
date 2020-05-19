require 'test_helper'

class BasesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get bases_new_url
    assert_response :success
  end

end
