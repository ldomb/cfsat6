#
# Description: <Method description here>
#
#$evm.log(:info, "DEBUG")
#$evm.root.attributes.sort.each { |k, v| $evm.log(:info, "\t#{k}: #{v}") }
prov = $evm.root['service_template_provision_task']

if $evm.root['ae_result'] == 'ok'
  prov.message = 'Creating VM'
elsif $evm.root['ae_result'] == 'error'
  prov.message = 'Error Creating VM'
end
