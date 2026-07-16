#!/usr/bin/env gawk -f

function format_number(n) {
    for (j = 0; j < 6; ++j) {
        n = gensub(/([0-9]+)([0-9]{3})($|,)/, "\\1,\\2", "g", n);
    }
    return n;
}

BEGIN {
    total = 0;
}

{
    bucket = int(log($1)/log(2));
    count[bucket]++;
    total++;
}

END {
    cumulative = 0;
    for (i = 0; i <= 64; i++) {
        cumulative += count[i];
        percentage = cumulative / total * 100;
        if (count[i] == 0) {
            continue;
        }
        printf("[%12s; %12s) %12s %6.2f%%\n", format_number(2^i), format_number(2^(i+1)), format_number(count[i]), percentage);
    }
}
