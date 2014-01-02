require 'rspec'
require 'spec_helper'
require 'unitypods/cli'

describe 'UnitypodsCommand' do
  describe '#install' do
    context 'when the buildprojectdir does not exist' do
      let(:commnandline_args) { [] << "install" << "-p" << path_of_fixture_podfile_for_dir("basic") << "-b" << "this_dir_does_not_exist" }
      it { expect do
        UnitypodsCommand.start(commnandline_args)
      end.to raise_error("buildprojectdir does not exist")
      }
    end

    context 'when the podfile does not exist' do
      it {
        create_temp_random_dir do |tmp_dir|
          commnandline_args = [] << "install" << "-p" << "this_path_does_not_exist" << "-b" << tmp_dir
          expect do
            UnitypodsCommand.start(commnandline_args)
          end.to raise_error("podfile does not exist")
        end
      }
    end

    context 'when the a valid podfile and buildprojectdir are provided' do
      it 'should copy the podfile into the buildprojectdir' do
        create_temp_random_dir do |tmp_dir|
          commnandline_args = [] << "install" << "-p" << path_of_fixture_podfile_for_dir("fakepod_podfile") << "-b" << tmp_dir
          UnitypodsCommand.start(commnandline_args)
          expect(Pathname(File.join(tmp_dir, "Podfile")).exist?).to be_true
        end
      end

      it 'should invoke the pod install command in the buildprojectdir' do
        create_temp_random_dir do |tmp_dir|
          commnandline_args = [] << "install" << "-p" << path_of_fixture_podfile_for_dir("fakepod_podfile") << "-b" << tmp_dir
          UnitypodsCommand.start(commnandline_args)
          expect(Pathname(File.join(tmp_dir, "Podfile.lock")).exist?).to be_true
        end
      end
    end
  end
end