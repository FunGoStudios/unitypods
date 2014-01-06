require 'rspec'
require 'spec_helper'
require 'unitypods/cli'

describe 'UnitypodsCommand' do
  describe '#install' do
    context 'when the buildprojectdir does not exist' do
      let(:commnandline_args) { [] << "install" << "-p" << path_of_fixture_podfile_for_dir("basic") << "-b" << "this_dir_does_not_exist" }
      it { expect do
        Unitypods::UnitypodsCommand.start(commnandline_args)
      end.to raise_error("buildprojectdir does not exist")
      }
    end

    context 'when the podfile does not exist' do
      it {
        create_temp_random_dir do |tmp_dir|
          commnandline_args = [] << "install" << "-p" << "this_path_does_not_exist" << "-b" << tmp_dir
          expect do
            Unitypods::UnitypodsCommand.start(commnandline_args)
          end.to raise_error("podfile does not exist")
        end
      }
    end

    context 'when the podfile has errors' do
      it {
        create_temp_random_dir do |tmp_dir|
          commnandline_args = [] << "install" << "-p" << path_of_fixture_podfile_for_dir("fakepod_podfile_broken") << "-b" << tmp_dir
          expect do
            Unitypods::UnitypodsCommand.start(commnandline_args)
          end.to raise_error Unitypods::PodsError
        end
      }
    end

    context 'when the a valid podfile and buildprojectdir are provided' do
      it 'should copy the podfile into the buildprojectdir' do
        create_temp_random_dir do |tmp_dir|
          commnandline_args = [] << "install" << "-p" << path_of_fixture_podfile_for_dir("fakepod_podfile") << "-b" << tmp_dir
          Unitypods::UnitypodsCommand.start(commnandline_args)
          expect(Pathname(File.join(tmp_dir, "Podfile")).exist?).to be_true
        end
      end

      it 'should invoke the pod install command in the buildprojectdir' do
        create_temp_random_dir do |tmp_dir|
          commnandline_args = [] << "install" << "-p" << path_of_fixture_podfile_for_dir("fakepod_podfile") << "-b" << tmp_dir
          Unitypods::UnitypodsCommand.start(commnandline_args)
          expect(Pathname(File.join(tmp_dir, "Podfile.lock")).exist?).to be_true
        end
      end

      context 'when the -i option is true' do
        it 'should integrate the pods as subproject of ' do
          create_temp_random_dir do |tmp_dir|
            FileUtils.cp_r(File.join(path_of_fixtures,"Unity-iPhone","."), tmp_dir)

            commnandline_args = [] << "install" << "-i" << "-p" << path_of_fixture_podfile_for_dir("fakepod_podfile") << "-b" << tmp_dir
            Unitypods::UnitypodsCommand.start(commnandline_args)

            unity_project = Xcodeproj::Project.open( Unity3dHelper::default_unity_project_path(tmp_dir) )
            expect(Pathname(File.join(tmp_dir, "Podfile.lock")).exist?).to be_true

            #xcconfig
            xcconfig = unity_project.files.find { |f| f.path == "Pods/Pods.xcconfig"}
            expect(xcconfig).to_not be_nil
            Unity3dHelper::find_default_unity_target(unity_project).build_configurations.each do |config|
              config.base_configuration_reference.should == xcconfig
            end
          end
        end
      end

      end
  end
end