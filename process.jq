def deep_no_raw:
    if type == "array" then
        map(deep_no_raw)
    elif type == "object" then
        [
            to_entries[]
            | select(.key != "_raw")
            | .value = (.value | deep_no_raw)
        ]
        | from_entries
    else
        .
    end;

#  deep_no_raw | {
#     time: .time,
#     verb: .header.verb,
#     sections,
#  }
