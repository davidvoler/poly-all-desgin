import stanza

# Download the Arabic model
stanza.download('ar')
nlp = stanza.Pipeline('ar')

doc = nlp("ذهب الولد إلى المدرسة")

for sentence in doc.sentences:
    for word in sentence.words:
        # word.text: the word string
        # word.upos: the Part of Speech tag
        # word.parent.start_char: the start position in the sentence
        print(f"{word.text} | POS: {word.upos} | Start: {word.parent.start_char}")