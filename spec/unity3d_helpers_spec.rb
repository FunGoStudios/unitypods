require 'spec_helper'
require 'xcodeproj'
require 'unitypods'


describe 'Unity3dHelper' do
  it 'should find the unity default target' do
    project_original = path_of_fixture_project('Unity-iPhone')
    project = Xcodeproj::Project.open(project_original)
    target = Unity3dHelper::find_default_unity_target(project)
    target.should_not be_nil
  end
end