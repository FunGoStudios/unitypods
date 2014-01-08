require "thor"
require 'fileutils'
require 'open3'
require 'unitypods/error'
require 'unitypods/unity3d_helper'
require 'xcodeproj'
require 'erb'

module Unitypods
  class UnitypodsCommand < Thor
    option :podfile, :aliases => "-p", :required => true
    option :buildprojectdir, :required => true, :aliases => "-b", :desc => ""
    option :integrate, :type => :boolean, :default => false, :aliases => "-i",
           :desc => "integrate with the Unity-iPhone.xcodeproj"
    option :overridelock, :type => :boolean, :default => true, :aliases => "-o",
           :desc => "if true copy the Podfile.lock from the build dir into the dir containing the Podfile"

    desc "install", "run pod install into the projdir dir with the podfile"

    def install
      output = []
      output << "podfile: #{options[:podfile]}" if options[:podfile]
      output << "buildprojectdir: #{options[:buildprojectdir]}" if options[:buildprojectdir]
      output << "overridelock: #{options[:overridelock]}" if options[:overridelock]
      output << "integrate: #{options[:integrate]}" if options[:integrate]

      output = output.join("\n")
      puts output


      validate_input
      copy_podfiles
      run_pod_install
      integrate_subproject if options[:integrate]
      #TODO copy the Podfile.lock
    end


    desc "init", "init a unity3d project with a default postprocess build script"

    def init
      puts '[+] Check if it\'s an Unity3d project...'

      unity_project = Unity3dHelper.is_a_unity_assets_subdir?(Dir.pwd)
      raise Unitypods::PodsInitNoAssetDirError.new('[-] No one unity project present here, check again and retry.') unless unity_project

      postprocess_files = Unity3dHelper.find_all_default_postprocess_files(Unity3dHelper.find_the_unity_assets_root_dir(Dir.pwd))
      raise PodsInitAlreadyInitialized.new("Unitypod is already added to this project here: #{postprocess_files.join(", ")}") if !postprocess_files.empty?

      puts '[+] Creating a new Unity3d project using a default PostProcess build script'

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
    string podfilePath = "<%= File.join(Dir.pwd, 'Podfile') %>"
    string cmd = "unitypod";
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
      p.WaitForExit ();

      // finally output the string
      UnityEngine.Debug.Log (output);
      UnityEngine.Debug.Log (p.ExitCode);
      if (p.ExitCode != 0) {
          throw new System.InvalidOperationException("unitypod failed");
      }
    }

#endif
  }
}
      EOF

      Unity3dHelper.create_default_postprocess(postprocess_template)

      puts "[+] Creating a default Podfile: #{File.join(Dir.pwd, 'Podfile')}"
      CocoaPodsHelper.create_podfile!
    end

    private
    def validate_input
      raise "buildprojectdir does not exist" unless Pathname.new(options[:buildprojectdir]).exist?
      raise "podfile does not exist" unless Pathname.new(options[:podfile]).exist?
      if options[:integrate]
        @unity_project_path = Unity3dHelper::default_unity_project_path(options[:buildprojectdir])
        raise "@unity_project_path does not exist" unless Pathname.new(@unity_project_path).exist?
      end
    end

    def copy_podfiles
      FileUtils.cp options[:podfile], options[:buildprojectdir]
    end

    def run_pod_install
      FileUtils.cd(options[:buildprojectdir]) do # chdir
        cmd = "pod install --no-integrate"
        output = `#{cmd} 2>&1`
        puts output
        raise Unitypods::PodsError.new("Failed #{cmd}: \n #{output}") unless $?.success?
      end # return to original directory
    end

    def integrate_subproject
      unity_project = Xcodeproj::Project.open(@unity_project_path)

      #Create the subproject Pod file reference
      pod_proj_file_ref = Xcodeproj::Project::Object::FileReferencesFactory::new_reference(unity_project.main_group, "Pods/Pods.xcodeproj", :group)
      pod_proj_file_ref.name="Pods.xcodeproj"
      pod_proj_file_ref.last_known_file_type="wrapper.pb-project"

      #add Pods as dependency of the main target
      pods_project = Xcodeproj::Project.open(File.join(options[:buildprojectdir],  "Pods/Pods.xcodeproj"))
      unity_project_target = Unity3dHelper::find_default_unity_target(unity_project)
      pods_target_on_remote_proj = CocoaPodsHelper::find_target_by_name(pods_project, "Pods")
      unity_project_target.add_dependency(pods_target_on_remote_proj)

      #Set the library search path
      %w(Debug Release).each do |build_configuration_name|
        CocoaPodsHelper::add_flag( unity_project_target, build_configuration_name, "LIBRARY_SEARCH_PATHS", "$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)")
        CocoaPodsHelper::add_flag( unity_project_target, build_configuration_name, "LIBRARY_SEARCH_PATHS", "$(inherited)")
      end

      %w(Debug Release).each do |build_configuration_name|
        CocoaPodsHelper::add_flag( unity_project_target, build_configuration_name, "OTHER_LDFLAGS", "-lPods")
        CocoaPodsHelper::add_flag( unity_project_target, build_configuration_name, "OTHER_LDFLAGS", "$(inherited)")
      end

      %w(Debug Release).each do |build_configuration_name|
        #add the recursive pods headers path
        CocoaPodsHelper::add_flag( unity_project_target, build_configuration_name, "HEADER_SEARCH_PATHS", "$(SRCROOT)/Pods/Headers/**")
      end

      set_xcconfig(unity_project)

      unity_project.save(@unity_project_path)
    end

    def set_xcconfig(unity_project)
      xcconfig_relative_path = "Pods/Pods.xcconfig"
      xcconfig = unity_project.files.select { |f| f.path == xcconfig_relative_path }.first ||
          unity_project.new_file(xcconfig_relative_path)
      unity_project_target = Unity3dHelper::find_default_unity_target(unity_project)

      Unity3dHelper::find_default_unity_target(unity_project).build_configurations.each do |config|
        config.base_configuration_reference = xcconfig
      end
    end
  end
end
