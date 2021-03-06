require 'test_helper'
require 'generators/ember/model_generator'

class ModelGeneratorTest < Rails::Generators::TestCase
  tests Ember::Generators::ModelGenerator

  destination File.join(Rails.root, "tmp", "generator_test_output")

  setup :prepare_destination

  def copy_directory(dir)
    source = Rails.root.join(dir)
    dest = Rails.root.join("tmp", "generator_test_output", File.dirname(dir))

    FileUtils.mkdir_p dest
    FileUtils.cp_r source, dest
  end

  def prepare_destination
    super

    copy_directory "app/assets/javascripts"
    copy_directory "config"
  end

  %w(js coffee em).each do |engine|
    test "create model with #{engine} engine" do
      run_generator ["post", "title:string", "--javascript-engine=#{engine}"]
      assert_file "app/assets/javascripts/models/post.js.#{engine}".sub('.js.js','.js')
    end

    test "create namespaced model with #{engine} engine" do
      run_generator ["post/doineedthis", "title:string", "--javascript-engine=#{engine}"]
      assert_file "app/assets/javascripts/models/post/doineedthis.js.#{engine}".sub('.js.js','.js'), /PostDoineedthis/
    end

    test "create attribute with #{engine} engine" do
      run_generator ["comment", "post:references", "body:string", "--javascript-engine=#{engine}"]
      assert_file "app/assets/javascripts/models/comment.js.#{engine}".sub('.js.js','.js'), /body: DS.attr/
      assert_file "app/assets/javascripts/models/comment.js.#{engine}".sub('.js.js','.js'), /post: DS.belongsTo.+post/
    end
  end

  test "leave parentheses when create model w/o attributes (with coffee engine)" do
    run_generator ["post", "--javascript-engine=coffee"]
    assert_file "app/assets/javascripts/models/post.js.coffee", /DS.Model.extend\(\)/
  end

  test "Assert files are properly created" do
    run_generator %w(ember)

    assert_file "#{ember_path}/models/ember.js"
  end

  test "Assert files are properly created with custom path" do
    custom_path = ember_path("custom")
    run_generator [ "ember", "-d", custom_path ]

    assert_file "#{custom_path}/models/ember.js"
  end

  test "Assert files are properly created with custom app name" do
    run_generator [ "ember", "-n", "MyApp" ]
    assert_file "app/assets/javascripts/models/ember.js", /MyApp\.Ember/
  end

  test "Uses config.ember.app_name as the app name" do
    begin
      old, ::Rails.configuration.ember.app_name = ::Rails.configuration.ember.app_name, 'MyApp'

      run_generator %w(ember)
      assert_file "app/assets/javascripts/models/ember.js", /MyApp\.Ember/
    ensure
      ::Rails.configuration.ember.app_name = old
    end
  end

  test "Uses config.ember.ember_path" do
    begin
      custom_path = ember_path("custom")
      old, ::Rails.configuration.ember.ember_path = ::Rails.configuration.ember.ember_path, custom_path

      run_generator ["ember"]
      assert_file "#{custom_path}/models/ember.js"
    ensure
      ::Rails.configuration.ember.ember_path = old
    end
  end
  private

  def ember_path(custom_path = nil)
   "app/assets/javascripts/#{custom_path}".chomp('/')
  end

end
