# auditusers_report_vol_mounted

Facter.add('auditusers_report_vol_mounted') do
  setcode do
    config_file = '/etc/auditusers/fact_config'
    if File.exist?(config_file)
      mounted = false
      File.open(config_file) do |infile|
        while (line = infile.gets) do
          line = line.rstrip()
          if line.length() == 0 || line[0].chr() == '#' then
            next
          end
          if line['report_vol'] then
            config = line.split('=')
            disk = config[-1].strip()
            if File.directory?(disk) then
              mounted = true
            end
          end
        end
      end
      if mounted then
        "true"
      end
    end
  end
end
