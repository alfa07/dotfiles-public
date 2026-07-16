function format_number(n) {
    for (j = 0; j < 6; ++j) {
        n = gensub(/([0-9]+)([0-9]{3})($|,)/, "\\1,\\2", "g", n);
    }
    return n;
}
