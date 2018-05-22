puts '['
MergeRequest.all.find_each do |mr|
    present = mr.ref_fetched?
    result = "N/A"

    begin
        if not present
            mr.ensure_ref_fetched
            result = "success"
        end
    rescue StandardError => e
        result = sprintf("failure (%s)", e)
    ensure
        printf "  %d:{ state:'%s', present:'%s', fetch:'%s' },\n", mr.id, mr.state, present, result
    end
end
puts ']'
