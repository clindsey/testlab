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

# CONTAINERS
#############
desc 'Manage containers'
arg_name 'Describe arguments to container here'
command :container do |c|

  c.desc 'Single or comma separated list of container IDs'
  c.arg_name 'container[,container,...]'
  c.flag [:n, :name]

  # CONTAINER CREATE
  ###################
  c.desc 'Create a container'
  c.long_desc <<-EOF
Creates a container on the node the container belongs to.
EOF
  c.command :create do |create|
    create.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.create
        end
      end
    end
  end

  # CONTAINER DESTROY
  ####################
  c.desc 'Destroy a container'
  c.long_desc <<-EOF
Destroys the container, force stopping it if necessary.  The containers file system is purged from disk.  This is a destructive operation, there is no way to recover from it.
EOF
  c.command :destroy do |destroy|
    destroy.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.destroy
        end
      end
    end
  end

  # CONTAINER UP
  ###############
  c.desc 'Up a container'
  c.long_desc <<-EOF
The container is started and brought online.
EOF
  c.command :up do |up|
    up.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.up
        end
      end
    end
  end

  # CONTAINER DOWN
  #################
  c.desc 'Down a container'
  c.long_desc <<-EOF
The container is stopped taking it offline.
EOF
  c.command :down do |down|
    down.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.down
        end
      end
    end
  end

  # CONTAINER SETUP
  ####################
  c.desc 'Setup a container'
  c.long_desc <<-EOF
The container is provisioned.
EOF
  c.command :setup do |setup|
    setup.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.setup
        end
      end
    end
  end

  # CONTAINER TEARDOWN
  ####################
  c.desc 'Teardown a container'
  c.long_desc <<-EOF
The container is deprovisioned.
EOF
  c.command :teardown do |teardown|
    teardown.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.teardown
        end
      end
    end
  end

  # CONTAINER BUILD
  ##################
  c.desc 'Build a container'
  c.long_desc <<-EOF
Attempts to build up the container.  TestLab will attempt to create, online and provision the container.

The container is taken through the following phases:

  Create -> Up -> Setup
EOF
  c.command :build do |build|
    build.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.build
        end
      end
    end
  end

  # CONTAINER STATUS
  ###################
  c.desc 'Display the status of container(s)'
  c.long_desc <<-EOF
Displays the status of all containers or single/multiple containers if supplied via the ID parameter.
EOF
  c.command :status do |status|
    status.action do |global_options, options, args|
      containers = Array.new

      if options[:name].nil?
        # No ID supplied; show everything
        containers = TestLab::Container.all
      else
        # ID supplied; show just those items
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"
      end

      containers = containers.delete_if{ |container| container.node.dead? }

      if (containers.count == 0)
        @testlab.ui.stderr.puts("You either have no containers defined or dead nodes!".yellow)
      else
        ZTK::Report.new(:ui => @testlab.ui).list(containers, TestLab::Container::STATUS_KEYS) do |container|
          OpenStruct.new(container.status)
        end
      end

    end
  end

  # CONTAINER SSH
  ################
  c.desc 'Open an SSH console to a container'
  c.command :ssh do |ssh|

    ssh.desc 'Specify an SSH Username to use'
    ssh.arg_name 'username'
    ssh.flag [:u, :user]

    ssh.desc 'Specify an SSH Identity Key to use'
    ssh.arg_name 'filename'
    ssh.flag [:i, :identity]

    ssh.action do |global_options, options, args|
      help_now!('a name is required') if options[:name].nil?

      container = @testlab.containers.select{ |n| n.id.to_sym == options[:name].to_sym }.first
      container.nil? and raise TestLab::TestLabError, "We could not find the container you supplied!"

      ssh_options = Hash.new
      ssh_options[:user] = options[:user]
      ssh_options[:keys] = options[:identity]

      container.ssh(ssh_options).console
    end
  end

  # CONTAINER SSH-CONFIG
  #######################
  c.desc 'Display the SSH configuration for a container'
  c.long_desc <<-EOF
Displays the SSH configuration for the supplied container name.
EOF
  c.command :'ssh-config' do |ssh_config|

    ssh_config.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          puts(container.ssh_config)
        end
      end
    end
  end

  # CONTAINER RECYCLE
  ####################
  c.desc 'Recycles a container'
  c.long_desc <<-EOF
Recycles a container.  The container is taken through a series of state changes to ensure it is pristine.

The container is cycled in this order:

Teardown -> Down -> Destroy -> Create -> Up -> Setup
EOF
  c.command :recycle do |recycle|
    recycle.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.teardown
          container.down
          container.destroy

          container.create
          container.up
          container.setup
        end
      end
    end
  end

  # CONTAINER CLONE
  ##################
  c.desc 'Clone a container'
  c.long_desc <<-EOF
An ephemeral copy of the container is started.  There is a small delay incured during the first clone operation.
EOF
  c.command :clone do |clone|
    clone.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.clone
        end
      end
    end
  end

  # CONTAINER EXPORT
  ###################
  c.desc 'Export a container to a shipping container (file)'
  c.command :export do |export|

    export.desc 'Specify the level of bzip2 compression to use (1-9)'
    export.default_value 9
    export.arg_name 'level'
    export.flag [:c, :compression]

    export.desc 'Specify the shipping container file to export to.'
    # export.default_value nil
    export.arg_name 'filename'
    export.flag [:output]

    export.action do |global_options, options, args|
      if options[:name].nil?
        help_now!('a name is required') if options[:name].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.export(options[:compression], options[:output])
        end
      end
    end
  end

  # CONTAINER IMPORT
  ###################
  c.desc 'Import a shipping container (file)'
  c.command :import do |import|

    import.desc 'Specify the shipping container file to import from.'
    import.arg_name 'filename'
    import.flag [:input]

    import.action do |global_options, options, args|
      if (options[:name].nil? || options[:input].nil?)
        help_now!('a name is required') if options[:name].nil?
        help_now!('a filename is required') if options[:input].nil?
      else
        names = options[:name].split(',')
        containers = TestLab::Container.find(names)
        (containers.nil? || (containers.count == 0)) and raise TestLab::TestLabError, "We could not find any of the containers you supplied!"

        containers.each do |container|
          container.import(options[:input])
        end
      end
    end
  end

end
