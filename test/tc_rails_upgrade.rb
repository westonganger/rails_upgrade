#!/usr/bin/env ruby -w
require 'yaml'
require 'minitest'
require 'rails_upgrade'

args = [File.join(File.dirname(__FILE__), 'test_app')]

`cp -rf #{File.join(File.dirname(__FILE__), 'tdr_orig')} #{args.first}`

puts RailsUpgrade::Syntax.convert_hash_to_version('2.1', args)
puts RailsUpgrade::Rails3To4.convert_finders(args)
puts RailsUpgrade::Rails3To4.convert_association_conditions(args)
puts RailsUpgrade::Rails3To4.convert_scopes(args)

puts RailsUpgrade::Rails3To4.locate_action_mailer_method(args)
puts RailsUpgrade::Rails3To4.locate_update_attributes_method(args)
puts RailsUpgrade::Rails3To4.locate_missing_habtm_join_table(args)
puts RailsUpgrade::FindUnused.partials(args)

=begin

require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestSpreadsheetArchitect < MiniTest::Test
  class Post
  end

  test "test_spreadsheet_options" do
    assert_equal([:name, :title, :content, :votes, :ranking], Post.spreadsheet_columns)
    assert_equal([:name, :title, :content, :votes, :created_at, :updated_at], OtherPost.column_names)
    assert_equal([:name, :title, :content], PlainPost.spreadsheet_columns)
  end
end
  
class TestToCsv < MiniTest::Test
  test "test_class_method" do
    p = Post.to_csv(spreadsheet_columns: [:name, :votes, :content, :ranking])
    assert_equal(true, p.is_a?(String))
  end
  test 'test_chained_method' do
    p = Post.order("name asc").to_csv(spreadsheet_columns: [:name, :votes, :content, :ranking])
    assert_equal(true, p.is_a?(String))
  end
end

class TestToOds < MiniTest::Test
  test 'test_class_method' do
    p = Post.to_ods(spreadsheet_columns: [:name, :votes, :content, :ranking])
    assert_equal(true, p.is_a?(String))
  end
  test 'test_chained_method' do
    p = Post.order("name asc").to_ods(spreadsheet_columns: [:name, :votes, :content, :ranking])
    assert_equal(true, p.is_a?(String))
  end
end
=end
