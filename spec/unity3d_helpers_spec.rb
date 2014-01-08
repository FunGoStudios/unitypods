require 'spec_helper'
require 'xcodeproj'
require 'unitypods'


describe 'Unity3dHelper' do
  describe 'find_default_unity_target' do
    it 'should find the unity default target' do
      project_original = path_of_fixture_project('Unity-iPhone')
      project = Xcodeproj::Project.open(project_original)
      target = Unity3dHelper::find_default_unity_target(project)
      target.should_not be_nil
    end
  end

  describe 'find_the_unity_assets_root_dir' do
    it 'should return the Asset Dir if the command runs into a subdir of Assets' do
      create_temp_random_dir do |tmp_dir|
        fake_foo_dir = File.join(tmp_dir, Unity3dHelper::DEFAULT_UNITY_ASSETS_PATH, "fake_bar_dir")
        ecpected_asset_dir = File.join(tmp_dir, Unity3dHelper::DEFAULT_UNITY_ASSETS_PATH)
        FileUtils.mkpath(fake_foo_dir)
        Unity3dHelper::find_the_unity_assets_root_dir(fake_foo_dir).should == ecpected_asset_dir
      end
    end

    it 'should return nil if the command does not run into a subdir of Assets' do
      create_temp_random_dir do |tmp_dir|
        expect(Unity3dHelper::find_the_unity_assets_root_dir(tmp_dir)).to be_nil
      end
    end
  end

  describe 'is_a_unity_assets_subdir?' do
    it 'should return the true if the command runs into a subdir of Assets' do
      create_temp_random_dir do |tmp_dir|
        fake_foo_dir = File.join(tmp_dir, Unity3dHelper::DEFAULT_UNITY_ASSETS_PATH, "fake_bar_dir")
        FileUtils.mkpath(fake_foo_dir)
        expect(Unity3dHelper::is_a_unity_assets_subdir?(fake_foo_dir)).to be_true
      end
    end

    it 'should false if the command does not run into a subdir of Assets' do
      create_temp_random_dir do |tmp_dir|
        expect(Unity3dHelper::find_the_unity_assets_root_dir(tmp_dir)).to be_false
      end
    end
  end

end