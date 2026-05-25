from camel_tools.disambig.mle import MLEDisambiguator
from camel_tools.tokenizers.word import SimpleWordTokenizer

# Requires downloading the data first: camel_data -i light
tokenizer = SimpleWordTokenizer()
disambiguator = MLEDisambiguator.pretrained()

sentence = "ذهب الولد إلى المدرسة"
tokens = tokenizer.tokenize(sentence)
disambig_results = disambiguator.disambiguate(tokens)

# Extracting the top diacritized choice for each word
diacritized = [res.analyses[0].analysis['diac'] for res in disambig_results]
print(" ".join(diacritized))