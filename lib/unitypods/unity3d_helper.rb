require 'unitypods/cocoa_pods_helper'

class Unity3dHelper
  # Unity
  DEFAULT_UNITY_TARGET_NAME='Unity-iPhone'.freeze
  DEFAULT_UNITY_ASSETS_PATH='Assets'.freeze

  # PostProcessBuild
  DEFAULT_POSTPROCESS_FILE='PostProcessBuild.cs'.freeze
  DEFAULT_POSTPROCESS_PATH='Editor'.freeze

  # @param pathToBuiltProject contains the project built by unity. Is provided by unity PostProcessBuildAttribute http://docs.unity3d.com/412/Documentation/ScriptReference/PostProcessBuildAttribute.html
  # @return the full project path
  def self.default_unity_project_path(pathToBuiltProject)
    File.join(pathToBuiltProject, 'Unity-iPhone.xcodeproj')
  end

  # @return the default unity target if available, nil otherwise
  def self.find_default_unity_target(project)
    CocoaPodsHelper::find_target_by_name(project, DEFAULT_UNITY_TARGET_NAME)
  end

  # @return true or false if current is an unity project or not
  def self.is_a_unity_project?
    return File.directory?(File.join(Dir.pwd, '../', DEFAULT_UNITY_ASSETS_PATH)) || File.directory?(File.join(Dir.pwd, DEFAULT_UNITY_ASSETS_PATH)) 
  end

  # Create default PostProcessBuild file
  def self.create_default_postprocess(postprocess_template)
    postprocess_path = File.join(Dir.pwd, DEFAULT_POSTPROCESS_PATH)
    FileUtils.mkdir_p(postprocess_path) unless File.directory?(postprocess_path)

    postprocess_output = File.open(File.join(postprocess_path, DEFAULT_POSTPROCESS_FILE), 'w')
    postprocess_output << ERB.new(postprocess_template).result(binding)
    postprocess_output.close
  end

end
