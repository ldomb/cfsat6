#
# Description: <Method description here>
#
=begin
method: Validate_Sat6_Host.rb
 Description: Check host build status in satellite
 Author: Laurent Domb <laurent@redhat.com>
 Modified: Patrick Rutledge <prutledg@redhat.com>
 License: GPL v3 
-------------------------------------------------------------------------------
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------
=end
  
require 'rest-client'
require 'json'

# Sat6 admin user
$username = nil || $evm.object['username']

# Get Satellite password from model else set it here
$password = nil || $evm.object.decrypt('password')

url = nil || $evm.object['sat6url']

hostname = $evm.root['hostname']

def get_json(url)
  response = RestClient::Request.new(
    :method => :get,
    :url => url,
    :user => $username,
    :password => $password,
    :headers => { 
      :accept => :json,
      :content_type => :json
    }
  ).execute
  return JSON.parse(response.to_str)
end

#$evm.log("info", "Listing Root Object Attributes:")
#$evm.root.attributes.sort.each { |k, v| $evm.log("info", "\t#{k}: #{v}") }
#$evm.log("info", "===========================================")

# Get current provisioning status
task = $evm.root['service_template_provision_task']
task_status = task['status']
result = task.statemachine_task_status

sj = get_json(url+"hosts/#{hostname}/status")
status = sj['status']
$evm.log(:info, "Satellite returned #{hostname} status #{status}")
case status
when 'Pending Installation'
  result = 'retry'
when 'No Changes'
  result = 'retry'
when 'Active'
  result = 'ok'
end

$evm.log('info', "Service ProvisionCheck returned <#{result}> for state <#{task.state}> and status <#{task_status}>")

#if result == 'ok'
  #if task.miq_request_tasks.any? { |t| t.state != 'finished' }
  #  result = 'retry'
  #  $evm.log('info', "Child tasks not finished. Setting retry for task: #{task.id} ")
  #end
#end

case result
when 'error'
  $evm.root['ae_result'] = 'error'
  reason = $evm.root['service_template_provision_task'].message
  reason = reason[7..-1] if reason[0..6] == 'Error: '
  $evm.root['ae_reason'] = reason
when 'retry'
  $evm.root['ae_result']         = 'retry'
  $evm.root['ae_retry_interval'] = '1.minute'
when 'ok'
  # Bump State
  $evm.root['ae_result'] = 'ok'
end
