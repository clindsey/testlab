class TestLab

  class Provider

    # Vagrant Provider Error Class
    class VagrantError < ProviderError; end

    # Vagrant Provider Class
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    class Vagrant

      # States which indicate the VM is running
      RUNNING_STATES  = %w(running).map(&:to_sym)

      # States which indicate the VM is shut down
      SHUTDOWN_STATES = %w(aborted paused saved poweroff).map(&:to_sym)

      # The state we report if we can not determine the VM state
      UNKNOWN_STATE   = :unknown

      # A collection of all valid states the VM can be in
      VALID_STATES    = (RUNNING_STATES + SHUTDOWN_STATES).flatten

      # A collection of all invalid states the VM can be in
      INVALID_STATES  = (%w(not_created).map(&:to_sym) + [UNKNOWN_STATE]).flatten

      # A collection of all states the VM can be in
      ALL_STATES      = (VALID_STATES + INVALID_STATES).flatten

################################################################################

      def initialize(config={}, ui=nil)
        @config   = (config || Hash.new)
        @ui       = (ui || TestLab.ui)

        # ensure our vagrant key is there
        @config[:vagrant] ||= Hash.new
      end

################################################################################

      # Create the Vagrant instance
      def create
        true
      end

      # Destroy Vagrant-controlled VM
      def destroy
        self.alive? and self.down
        self.exists? and self.vagrant_cli("destroy", "--force", self.instance_id)

        true
      end

################################################################################

      # Online Vagrant-controlled VM
      def up
        self.vagrant_cli("up", self.instance_id)

        ZTK::TCPSocketCheck.new(:host => self.ip, :port => self.port, :wait => 120, :ui => @ui).wait

        true
      end

      # Halt Vagrant-controlled VM
      def down(*args)
        arguments = (%W(halt #{self.instance_id}) + args).flatten.compact

        self.vagrant_cli(*arguments)

        true
      end

################################################################################

      # Reload Vagrant-controlled VM
      def reload
        self.down
        self.up

        true
      end

################################################################################

      # Inquire the state of the Vagrant-controlled VM
      def state
        output = self.vagrant_cli("status").output.split("\n").select{ |line| (line =~ /#{self.instance_id}/) }.first
        result = UNKNOWN_STATE
        ALL_STATES.map{ |s| s.to_s.gsub('_', ' ') }.each do |state|
          if output =~ /#{state}/
            result = state.to_s.gsub(' ', '_')
            break
          end
        end
        result.to_sym
      end

################################################################################

      # Does the Vagrant-controlled VM exist?
      def exists?
        (self.state != :not_created)
      end

      # Is the Vagrant-controlled VM alive?
      def alive?
        (self.exists? && (RUNNING_STATES.include?(self.state) rescue false))
      end

      # Is the Vagrant-controlled VM dead?
      def dead?
        !self.alive?
      end

      # START CORE CONFIG
      ####################

      def instance_id
        (@config[:vagrant][:id] || "testlab-#{ENV['USER']}".downcase)
      end

      def user
        (@config[:vagrant][:user] || "vagrant")
      end

      def identity
        (@config[:vagrant][:identity] || File.join(ENV['HOME'], ".vagrant.d", "insecure_private_key"))
      end

      def ip
        (@config[:vagrant][:ip] || "192.168.33.#{last_octet}")
      end

      def last_octet
        crc32 = Zlib.crc32(self.instance_id)
        (crc32.modulo(254) + 1)
      end

      def port
        (@config[:vagrant][:port] || 22)
      end

      ##################
      # END CORE CONFIG

      def hostname
        (@config[:vagrant][:hostname] || self.instance_id)
      end

      def box
        (@config[:vagrant][:box] || "raring64")
      end

      def box_url
        (@config[:vagrant][:box_url] || "http://files.vagrantup.com/raring64.box")
      end

      def cpus
        (@config[:vagrant][:cpus] || 2)
      end

      def memory
        (@config[:vagrant][:memory] || (1024 * 2))
      end

      def resize
        (@config[:vagrant][:resize] || (1024 * 16))
      end

      def synced_folders
        (@config[:vagrant][:synced_folders] || nil)
      end

################################################################################

      def vagrant_cli(*args)
        @ui.logger.debug { "args == #{args.inspect}" }

        command = TestLab.build_command_line("vagrant", *args)
        @ui.logger.debug { "command == #{command.inspect}" }

        render_vagrantfile
        result = ZTK::Command.new(:ui => @ui, :silence => true, :ignore_exit_status => true).exec(command)

        if result.exit_code != 0
          @ui.stderr.puts
          @ui.stderr.puts
          @ui.stderr.puts(result.output)

          raise VagrantError, "Vagrant failed to execute!"
        end

        result
      end

      def render_vagrantfile
        context = {
          :id => self.instance_id,
          :ip => self.ip,
          :hostname => self.hostname,
          :user => self.user,
          :port => self.port,
          :cpus => self.cpus,
          :memory => self.memory,
          :resize => self.resize,
          :box => self.box,
          :box_url => self.box_url,
          :synced_folders => self.synced_folders
        }

        vagrantfile_template = File.join(TestLab::Provider.template_dir, "vagrant", "Vagrantfile.erb")
        vagrantfile          = File.join(@config[:vagrant][:file], "Vagrantfile")

        File.open(vagrantfile, 'w') do |file|
          file.puts(ZTK::Template.render(vagrantfile_template, context))
        end
      end

################################################################################


    end

  end
end
