################################################################################
#
#      Author: Zachary Patten <zachary AT jovelabs DOT com>
#   Copyright: Copyright (c) Zachary Patten
#     License: Apache License, Version 2.0
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
################################################################################

# NETWORKS
###########
build_lab_commands(:network, TestLab::Network) do |c|

  # NETWORK STATUS
  #################
  c.desc 'Display the status of networks'
  c.long_desc <<-EOF
Displays the status of all networks or single/multiple networks if supplied via the ID parameter.
EOF
  c.command :status do |status|
    status.action do |global_options, options, args|
      networks = iterate_objects_by_name(options[:name], TestLab::Network)

      ZTK::Report.new(:ui => @testlab.ui).list(networks, TestLab::Network::STATUS_KEYS) do |network|
        OpenStruct.new(network.status)
      end
    end
  end

  # ROUTES
  #########
  c.desc 'Manage routes'
  c.command :route do |route|

    # ROUTE ADD
    ############
    route.desc 'Add routes to lab networks'
    route.command :add do |add|
      add.action do |global_options,options,args|
        iterate_objects_by_name(options[:name], TestLab::Network) do |network|
          p = TestLab::Provisioner::Route.new({}, @ui)
          p.on_network_up(network)
          @testlab.ui.stdout.puts("Added routes successfully!".green.bold)
        end
      end
    end

    # ROUTE DEL
    ############
    route.desc 'Delete routes to lab networks'
    route.command :del do |del|
      del.action do |global_options,options,args|
        iterate_objects_by_name(options[:name], TestLab::Network) do |network|
          p = TestLab::Provisioner::Route.new({}, @ui)
          p.on_network_down(network)
          @testlab.ui.stdout.puts("Deleted routes successfully!".red.bold)
        end
      end
    end

    # ROUTE SHOW
    #############

    # Route show helper method because OSX sucks
    def osx_network(net)
      net.network.split('.').delete_if{ |o| o == '0' }.join('.')
    end

    route.desc 'Show routes to lab networks'
    route.command :show do |show|
      show.action do |global_options,options,args|
        iterate_objects_by_name(options[:name], TestLab::Network) do |network|
          @testlab.ui.stdout.puts("Routes for TestLab network '#{network.id}':".green.bold)
          case RUBY_PLATFORM
          when /darwin/ then
            @testlab.ui.stdout.puts %x(netstat -nrf inet | grep '#{osx_network(network)}/#{network.cidr}').strip
          when /linux/ then
            @testlab.ui.stdout.puts %x(netstat -nr | grep '#{network.network}').strip
          end
        end
      end
    end
  end

end
