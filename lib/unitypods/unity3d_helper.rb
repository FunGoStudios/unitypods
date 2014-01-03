require 'unitypods/cocoa_pods_helper'

class Unity3dHelper
  DEFAULT_UNITY_TARGET_NAME="Unity-iPhone".freeze
  # @param pathToBuiltProject contains the project built by unity. Is provided by unity PostProcessBuildAttribute http://docs.unity3d.com/412/Documentation/ScriptReference/PostProcessBuildAttribute.html
  # @return the full project path
  def self.default_unity_project_path(pathToBuiltProject)
    File.join(pathToBuiltProject, "Unity-iPhone", "Unity-iPhone.xcodeproj")
  end

  #@return the default unity target if available, nil otherwise
  def self.find_default_unity_target(project)
    CocoaPodsHelper::find_target_by_name(project, DEFAULT_UNITY_TARGET_NAME)
  end
end