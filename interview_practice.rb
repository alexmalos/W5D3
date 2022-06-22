#take array of characters and reverse order of words in place
# Example: ["c", "a", "k", "e", " ", "p", "o", "u", "n", "d", " ", "s", "t", "e", "a", "l"] 
# => ["s", "t", "e", "a", "l", " ", "p", "o", "u", "n", "d", " ", "c", "a", "k", "e"]

def reverse_words(arr)
    words = arr.join.split(" ").reverse
    words.map(&:chars).join(" ")
end