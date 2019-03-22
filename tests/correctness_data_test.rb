require 'minitest/autorun'

class TestMe < Minitest::Test
  def setup
    File.write('result.json', '')
  end

  def test_result
    work('./fixtures/data.txt')
    assert_equal File.read('./fixtures/result.json'), File.read('result.json')
  end
end
