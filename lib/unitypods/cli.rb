require "thor"
require 'fileutils'
require 'open3'

class UnitypodsCommand < Thor
  option :podfile, :aliases => "-p", :required => true
  option :buildprojectdir, :required => true, :aliases => "-b", :desc => ""
  option :overridelock, :type => :boolean, :default => true, :aliases => "-o",
         :desc => "if true copy the Podfile.lock from the build dir into the dir containing the Podfile"

  desc "install", "run pod install into the projdir dir with the podfile"
  def install
    output = []
    output << "podfile: #{options[:podfile]}" if options[:podfile]
    output << "buildprojectdir: #{options[:buildprojectdir]}" if options[:buildprojectdir]
    output << "overridelock: #{options[:overridelock]}" if options[:overridelock]
    output = output.join("\n")
    puts output


    validate_input
    copy_podfiles
    run_pod_install
    #TODO copy the Podfile.lock
  end


  desc "init", "init a unity3d project with a default postprocess build script"
  def init
    #TODO
  end

  private
  def validate_input
    raise "buildprojectdir does not exist" unless Pathname.new(options[:buildprojectdir]).exist?
    raise "podfile does not exist" unless Pathname.new(options[:podfile]).exist?
  end

  def copy_podfiles
    FileUtils.cp options[:podfile], options[:buildprojectdir]
  end

  def run_pod_install
    FileUtils.cd(options[:buildprojectdir]) do  # chdir
      cmd = "pod install --no-integrate"
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        while line = stdout.gets
          puts line
        end
        exit_status = wait_thr.value
        raise "FAILED #{cmd}" unless exit_status.success?
      end
    end                   # return to original directory
  end
end