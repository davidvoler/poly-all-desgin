# Installation: pip install mishkal
from mishkal.tashkeel import TashkeelClass

vocalizer = TashkeelClass()
sentence = "ذهب الولد إلى المدرسة"
result = vocalizer.tashkeel(sentence)
print(result) 
# Output: ذَهَبَ الوَلَدُ إِلَى المَدْرَسَةِ