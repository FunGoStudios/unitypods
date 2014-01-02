class CocoaPodsHelper
  def self.find_target_by_name(project, target_name)
    target = project.targets.find{|t| t.name == target_name}
    if !target
      puts "(WW) add_flag: Target #{target_name} not found"
      return
    end
    target
  end

  def self.find_build_configurations_by_name(target, build_configuration_name)
    build_config = target.build_configurations.find{|bc| bc.name == build_configuration_name}
    if !build_config
      puts "(WW) add_flag: Build configuration #{build_configuration_name} not found"
      return
    end
    build_config
  end


  #Add the setting_value if not present
  def self.add_flag( project, target_name, build_configuration_name, setting_name, setting_value)
    target = find_target_by_name(project, target_name)
    bc = find_build_configurations_by_name(target, build_configuration_name)
    bc.build_settings[setting_name] = [] unless bc.build_settings.include?setting_name
    bc.build_settings[setting_name] << setting_value unless bc.build_settings[setting_name].include?(setting_value)
  end

  def self.remove_flag( project, target_name, build_configuration_name, setting_name, setting_value)
    target = find_target_by_name(project, target_name)
    bc = find_build_configurations_by_name(target, build_configuration_name)
    return unless bc.build_settings[setting_name]
    #TODO check for Array Hash or scalar values and remove them
  end
end