=begin
 method: List_Operatingsystems.rb
 Description: Lists all operatingsystems know to satellite6 
 Author: Laurent Domb <laurent@redhat.com>
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
katello_url = nil || $evm.object['katellourl']

def get_json(operatingsystems)
    response = RestClient::Request.new(
        :method => :get,
        :url => operatingsystems,
        :user => $username,
        :password => $password,
        :headers => { :accept => :json,
        :content_type => :json }
    ).execute
    results = JSON.parse(response.to_str)
end

operatingsystems = get_json(url+"operatingsystems")
operatingsystemslist = {}
operatingsystems['results'].each do |operatingsystem|
  puts operatingsystem['title']
  operatingsystemslist[operatingsystem['id']] = operatingsystem['title']
end

$evm.object['default_value'],v = operatingsystemslist.first
#operatingsystemslist[nil] = '< choose your os >'

$evm.object['values'] = operatingsystemslist.to_a
$evm.log(:info, "Dialog Values: #{$evm.object['values'].inspect}")
