require "thor"
require 'fileutils'
require 'open3'
require 'unitypods/error'
require 'unitypods/unity3d_helper'
require 'xcodeproj'

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
      #TODO
      #TODO check if we are in a unity3d project

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

      unity_project.save(@unity_project_path)
    end
  end
end