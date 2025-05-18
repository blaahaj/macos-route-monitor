class MacosRouteList
  def self.parse(raw)
    list = {
      _raw: raw,
      warnings: [],
    }

    raw.split("\n\n").each do |section|
      if section == "Routing tables"
        next
      elsif section.start_with?("Internet:\n")
        table = section.lines.map { |l| l.split(' ') }
        table.shift
        list[:ipv4_routes] = self.parse_table(table)
      elsif section.start_with?("Internet6:\n")
        table = section.lines.map { |l| l.split(' ') }
        table.shift
        list[:ipv6_routes] = self.parse_table(table)
      else
        list[:warnings] << "Unknown section"
      end
    end

    list
  end

  private

  def self.parse_table(rows)
    header = rows.shift
    rows.map do |cells|
      header.zip(cells).map { |k, v| [k.downcase, v] }.to_h
    end
  end
end

if $0 == __FILE__
  require 'json'
  list = MacosRouteList.parse(`netstat -rn`)
  puts JSON.generate(list)
end
