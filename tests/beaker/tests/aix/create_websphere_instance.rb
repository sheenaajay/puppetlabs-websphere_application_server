require 'erb'
require 'master_manipulator'
require 'websphere_helper'
require 'installer_constants'

test_name 'FM-5120 - C97842 - create websphere instance on aix'

# Teardown
teardown do
  confine_block(:except, :roles => %w{master dashboard database}) do
    agents.each do |agent|
      #comment out due to FM-5130
      #remove_websphere_instance('websphere_application_server', '/opt/log/websphere /opt/IBM')
    end
  end
end

# Get the ERB manifest:
base_dir          = Object.const_get('BASE_DIR')
instance_base     = Object.const_get('INSTANCE_BASE')
profile_base      = Object.const_get('PROFILE_BASE')
was_installer     = Object.const_get('WAS_INSTALLER')
package_name      = Object.const_get('PACKAGE_NAME')
package_version   = Object.const_get('PACKAGE_VERSION')
instance_name     = Object.const_get('INSTANCE_NAME')

local_files_root_path = ENV['FILES'] || "tests/beaker/files"
manifest_template     = File.join(local_files_root_path, 'websphere_instance_manifest.erb')
manifest_erb          = ERB.new(File.read(manifest_template)).result(binding)

step 'Inject "site.pp" on Master'
site_pp = create_site_pp(master, :manifest => manifest_erb)
inject_site_pp(master, get_site_pp_path(master), site_pp)

step 'Run Puppet Agent to create a websphere instance'
confine_block(:except, :roles => %w{master dashboard database}) do
  agents.each do |agent|
    on(agent, puppet('agent -t'), :acceptable_exit_codes => 1) do |result|
      expect_failure('Expected to fail due FM-5130') do
        assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
      end
    end
    step 'Verify websphere instance is created:'
    # Comment out the below line due to FM-5130
    #verify_websphere_created?(agent, instance_name)
  end
end
