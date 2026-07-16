# This AWK script adds comma separators to numbers
# Usage: awk -f format_numbers.awk input.txt > output.txt
{
    # Process each field in the line
    for (i=1; i<=NF; i++) {
        # Check if the field is a number (contains only digits)
        if ($i ~ /^[0-9]+$/) {
            # Format the number with comma separators
            $i = gensub(/([0-9])([0-9]{3})($|[^0-9])/, "\\1,\\2\\3", "g", $i)
            
            # Apply the substitution repeatedly until no more changes
            while (match($i, /([0-9])([0-9]{3})(,|$)/)) {
                $i = gensub(/([0-9])([0-9]{3})(,|$)/, "\\1,\\2\\3", "g", $i)
            }
        }
    }
    # Print the modified line
    print $0
}
