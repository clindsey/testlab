class TestLab
  class Container

    module Actions

      # Create the container
      #
      # Builds the configuration for the container and sends a request to the
      # LXC sub-system to create the container.
      #
      # @return [Boolean] True if successful.
      def create
        @ui.logger.debug { "Container Create: #{self.id}" }

        (self.node.state != :running) and return false
        (self.lxc.state != :not_created) and return false

        please_wait(:ui => @ui, :message => format_object_action(self, 'Create', :green)) do
          configure

          self.lxc.create(*create_args)
        end

        true
      end

      # Destroy the container
      #
      # Sends a request to the LXC sub-system to destroy the container.
      #
      # @return [Boolean] True if successful.
      def destroy
        @ui.logger.debug { "Container Destroy: #{self.id}" }

        (self.node.state != :running) and return false
        (self.lxc.state == :not_created) and return false

        please_wait(:ui => @ui, :message => format_object_action(self, 'Destroy', :red)) do
          self.lxc.destroy(%(-f))
          self.lxc_clone.destroy(%(-f))
        end

        true
      end

      # Start the container
      #
      # Sends a request to the LXC sub-system to bring the container online.
      #
      # @return [Boolean] True if successful.
      def up
        @ui.logger.debug { "Container Up: #{self.id}" }

        (self.node.state != :running) and return false
        (self.lxc.state == :running) and return false

        please_wait(:ui => @ui, :message => format_object_action(self, 'Up', :green)) do
          configure

          # ensure our container is in "static" mode
          self.to_static

          self.lxc.start(%(--daemon))

          (self.lxc.state != :running) and raise ContainerError, "The container failed to online!"

          self.users.each do |user|
            user.setup
          end

          self.ssh.exec(%(sudo hostname #{self.fqdn}))
        end

        true
      end

      # Stop the container
      #
      # Sends a request to the LXC sub-system to take the container offline.
      #
      # @return [Boolean] True if successful.
      def down
        @ui.logger.debug { "Container Down: #{self.id}" }

        (self.node.state != :running) and return false
        (self.lxc.state != :running) and return false

        please_wait(:ui => @ui, :message => format_object_action(self, 'Down', :red)) do
          self.lxc.stop

          (self.lxc.state == :running) and raise ContainerError, "The container failed to offline!"
        end

        true
      end

      # Clone the container
      #
      # Prepares the container, if needed, for ephemeral cloning and clones it.
      #
      # @return [Boolean] True if successful.
      def clone
        @ui.logger.debug { "Container Clone: #{self.id}" }

        please_wait(:ui => @ui, :message => format_object_action(self, 'Clone', :yellow)) do

          # ensure our container is in "ephemeral" mode
          self.to_ephemeral

          self.node.ssh.exec(%(sudo arp --verbose --delete #{self.ip}), :ignore_exit_status => true)

          ephemeral_arguments = Array.new
          ephemeral_arguments << %W(-o #{self.lxc_clone.name} -n #{self.lxc.name} -d)
          ephemeral_arguments << %W(--keep-data) if self.persist
          ephemeral_arguments.flatten!.compact!

          self.lxc_clone.start_ephemeral(ephemeral_arguments)
        end

        true
      end

      # Configure the container
      #
      # Configures the LXC subsystem for the container.
      #
      # @return [Boolean] True if successful.
      def configure
        self.domain ||= self.node.domain
        self.arch   ||= detect_arch

        build_lxc_config(self.lxc.config)

        true
      end

    end

  end
end
