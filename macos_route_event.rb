class MacosRouteEvent
  def self.parse(raw, time)
    event = {
      _raw: raw,
      time: time,
      warnings: [],
    }

    # raw = raw.sub(/\Agot message .*?\n/, '')

    if (m = raw.match(/\A(?<raw>got message of size (?<size>\d+) on (?<t>.*))\n(?<remainder>(?m:.*))\z/))
      event[:preamble] = {
        _raw: m["raw"],
        size: m["size"].to_i,
        datetime_text: m["t"],
      }

      raw = m["remainder"]
    end

    if (m = raw.match(/\A(?<raw>(?<verb>RTM_\w+): (?<description>.*?): (?<props_text>.*))\n(?<remainder>(?m:.*))\z/))
      event[:header] = {
        _raw: m["raw"],
        verb: m["verb"],
        description: m["description"],
      }

      props = event[:header][:props] = {}
      props[:_raw] = m["props_text"]

      m["props_text"].split(', ').each do |prop|
        case prop
        when /^(\w+):? (\d+)$/
          props[$1] = $2.to_i
        when /^ifref$/
          props["ifref"] = true
        when /^flags:$/
          props["flags"] = []
        when /^flags:<(.*?)>$/
          props["flags"] = $1.split(",")
        else
          event[:warnings] << "Unknown prop #{prop.inspect}"
        end
      end

      raw = m["remainder"]
    end

    event[:sections] = raw.split(/^(?=\S)/m).map do |text|
      section = { _raw: text }

      if text.match(/^locks:  inits: (<expire>)?\n$/)
        section[:type] = :locks_inits
        section[:empty] = true
        section[:expire] = !!$1
        next section
      end

      if text.match(/^sockaddrs: <(?<cols>.*)>(?<row_text>(\n .*)*)$/)
        section[:type] = :sockaddrs
        rows = $2
        columns = $1.split(',')

        section[:columns] = columns
        section[:rows] = rows.lines.map do |t|
          next if t == "\n"
          { _raw: t, cells: t[1..-1].split(/ /, -1) }
        end.compact

        next section
      end

      # RTM_IFINFO: iface status change: len 112, if# 20, flags:<UP,BROADCAST,b6,SIMPLEX,MULTICAST>
      if text.match(/^RTM_IFINFO: iface status change: len \d+, if# (\d+), flags:<([A-Za-z0-9,]+)>$/)
        section[:type] = :ifinfo
        section[:if_nr] = $1
        section[:flags] = $2.split(/,/)
        next section
      end

      event[:warnings] << "Unknown section #{section.inspect}"

      nil
    end.compact

    event
  end
end

if $0 == __FILE__
  $stdout.sync = true
  require 'json'

  $stdin.each_line do |t|
    d = JSON.parse(t)
    puts JSON.generate(MacosRouteEvent.parse(d["_raw"], d["time"] || Time.now.to_f))
  end
end
