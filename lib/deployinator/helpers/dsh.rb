module Deployinator
  module Helpers
    module DshHelpers
      def dsh_fanout
        @dsh_fanout || 30
      end

      def run_dsh(groups, cmd, &block)
        groups = [groups] unless groups.is_a?(Array)
        dsh_groups = groups.map {|group| "-g #{group} "}.join("")
        run_cmd(%Q{ssh #{Deployinator.app_context['user']}@#{Deployinator.deploy_host} dsh #{dsh_groups} -r ssh -F #{dsh_fanout} "#{cmd}"}, &block)[:stdout]
      end

      # run dsh against a given host or array of hosts
      def run_dsh_hosts(hosts, cmd, extra_opts='', &block)
        hosts = [hosts] unless hosts.is_a?(Array)
        if extra_opts.length > 0
          run_cmd %Q{ssh #{Deployinator.app_context['user']}@#{Deployinator.deploy_host} 'dsh -m #{hosts.join(',')} -r ssh -F #{dsh_fanout} #{extra_opts} -- "#{cmd}"'}, &block
        else
          run_cmd %Q{ssh #{Deployinator.app_context['user']}@#{Deployinator.deploy_host} 'dsh -m #{hosts.join(',')} -r ssh -F #{dsh_fanout} -- "#{cmd}"'}, &block
        end
      end

      def run_dsh_extra(dsh_group, cmd, extra_opts, &block)
        # runs dsh to a single group with extra args to dsh
        run_cmd(%Q{ssh #{Deployinator.app_context['user']}@#{Deployinator.deploy_host} dsh -g #{dsh_group} -r ssh #{extra_opts} -F #{dsh_fanout} "#{cmd}"}, &block)[:stdout]
      end

      def hosts_for(group)
        @hosts_for ||= {}
        @hosts_for[group] ||= begin
          dsh_file = "/home/#{Deployinator.app_context['user']}/.dsh/group/#{group}"
          hosts = `ssh #{Deployinator.app_context['user']}@#{Deployinator.deploy_host} cat #{dsh_file}`.chomp
          if $?.nil? || $?.exitstatus != 0
            raise "DSH hosts file at #{Deployinator.deploy_host}:#{dsh_file} is likely missing!"
          end
          hosts.split("\n").delete_if { |x| x.lstrip[0..0] == "#" } 
        end
      end
    end
  end
end
