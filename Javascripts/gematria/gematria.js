function calculateGematria(word) {
    const letters = 'abcdefghijklmnopqrstuvwxyz'; // 1-26
    let total = 0;
    for (let i = 0; i < word.length; i++) {
        let value = letters.indexOf(word[i].toLowerCase()) + 1;
        if (value > 0) total += value; // Ignore characters not in our letters string
    }
    return total;
}

console.log(calculateGematria("example")); // replace "example" with your word
