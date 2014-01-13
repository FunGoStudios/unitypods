require 'unitypods/cocoa_pods_helper'
require 'find'

class Unity3dHelper
  # Unity
  DEFAULT_UNITY_TARGET_NAME='Unity-iPhone'.freeze
  DEFAULT_UNITY_ASSETS_PATH='Assets'.freeze

  # PostProcessBuild
  DEFAULT_POSTPROCESS_FILE='UnitypodsPostProcessBuild.cs'.freeze
  DEFAULT_UNITYWRAPPER_FILE='unitypod_wrapper'.freeze
  DEFAULT_POSTPROCESS_PATH='Editor'.freeze
  DEFAULT_LOG_FILE='/tmp/unitypod.log'

  # @param pathToBuiltProject contains the project built by unity. Is provided by unity PostProcessBuildAttribute http://docs.unity3d.com/412/Documentation/ScriptReference/PostProcessBuildAttribute.html
  # @return the full project path
  def self.default_unity_project_path(pathToBuiltProject)
    File.join(pathToBuiltProject, 'Unity-iPhone.xcodeproj')
  end

  # @return the default unity target if available, nil otherwise
  def self.find_default_unity_target(project)
    CocoaPodsHelper::find_target_by_name(project, DEFAULT_UNITY_TARGET_NAME)
  end

  # @return the Unity Asset dir if the pdw dir is a sub dir of Unity3D Assets, nil otherwise
  def self.find_the_unity_assets_root_dir(dir)
    result = nil
    Pathname(dir).descend do |d|
      result = d.to_s if d.split.last.to_s == DEFAULT_UNITY_ASSETS_PATH
    end
    result
  end

  #@return an array with all the occurences of DEFAULT_POSTPROCESS_FILE
  def self.find_all_default_postprocess_files(dir)
    file_paths = []
    escaped_dir = dir[-1] == File::SEPARATOR ? dir : File.join(dir, File::SEPARATOR)
    Find.find(escaped_dir) do |path|
      file_paths << path if File.basename(path) == DEFAULT_POSTPROCESS_FILE
    end
    file_paths
  end

    # @return true or false if current is an unity project or not
  def self.is_a_unity_assets_subdir?(dir)
    return !find_the_unity_assets_root_dir(dir).nil?
  end

  # Create default PostProcessBuild file
  def self.create_default_postprocess
    postprocess_template = <<-EOF
using UnityEngine;
using System.Collections;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.Callbacks;
using System.Diagnostics;

public class PostprocessBuildPlayer : MonoBehaviour {
  [PostProcessBuild(1257)]
  public static void OnPostprocessBuild(BuildTarget target, string pathToBuild)
  {
#if UNITY_IPHONE
    // sets up our process, the first argument is the command
    // and the second holds the arguments passed to the command
    string podfilePath = "<%= File.join(Dir.pwd, 'Podfile') %>";
    string cmd = "<%= File.join(path, DEFAULT_UNITYWRAPPER_FILE) %>";
    string args = "install " + "-i" + " -b " + pathToBuild + " -p " + podfilePath;

    UnityEngine.Debug.Log("Run: " + cmd + " " + args);
    ProcessStartInfo ps = new ProcessStartInfo (cmd, args);
    ps.UseShellExecute = false;

    // we need to redirect the standard output so we read it
    // internally in out program
    ps.RedirectStandardOutput = true;
    ps.RedirectStandardError = true;

    // starts the process
    using (Process p = Process.Start (ps)) {

      // we read the output to a string
      string output = p.StandardOutput.ReadToEnd();
      string outputError = p.StandardError.ReadToEnd();

      // waits for the process to exit
      // Must come *after* StandardOutput is "empty"
      // so that we don't deadlock because the intermediate
      // kernel pipe is full.
      p.WaitForExit();
      UnityEngine.Debug.Log("unitypod log: " + "<%= DEFAULT_LOG_FILE %>");

      // finally output the string
      UnityEngine.Debug.Log (output);
      UnityEngine.Debug.Log (p.ExitCode);
      if (p.ExitCode != 0) {
          throw new System.InvalidOperationException("ERROR: " + "unitypod log: " + "<%= DEFAULT_LOG_FILE %>" );
      }
    }

#endif
  }
}
    EOF

    path = File.join(Dir.pwd, DEFAULT_POSTPROCESS_PATH)
    FileUtils.mkdir_p(path) unless File.directory?(path)

    postprocess_output = File.open(File.join(path, DEFAULT_POSTPROCESS_FILE), 'w')
    postprocess_output << ERB.new(postprocess_template).result(binding)
    postprocess_output.close
  end

  def self.create_default_unitypod_wrapper
    log_file = "/tmp/unitypod_wrapper_log"

    wrapper_template = <<-EOF
#!/bin/bash
echo "Start" > <%= log_file %>
source ~/.rvm/scripts/rvm
unitypod $@ 2>&1 1>><%= log_file %>
    EOF

    path = File.join(Dir.pwd, DEFAULT_POSTPROCESS_PATH)
    FileUtils.mkdir_p(path) unless File.directory?(path)

    postprocess_output = File.open(File.join(path, DEFAULT_UNITYWRAPPER_FILE), 'w')
    postprocess_output << ERB.new(wrapper_template).result(binding)
    postprocess_output.close
    FileUtils.chmod "u+x", File.join(path, DEFAULT_UNITYWRAPPER_FILE)
  end

end
