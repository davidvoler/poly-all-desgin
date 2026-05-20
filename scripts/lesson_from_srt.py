import random

def format_subtitles(lines:list[str]):
    subtitles = []
    last_srt = {}
    for line in lines:
        line = line.strip()
        if line.isdigit():
            last_srt['no'] = int(line)
        elif '-->' in line:
            times = line.split('-->')
            last_srt['start'] = times[0].strip()
            last_srt['end'] = times[1].strip()
        elif line == '':
            continue
        else:
            last_srt['text'] = line
            subtitles.append(last_srt)
            last_srt = {}
    return subtitles

def translate_subtitle(subtitle:str, to_lang:str):
    # Call translation API here
    return subtitle + f" {subtitle}  in {to_lang}"


def get_options(subtitles:list[dict], sub:dict):
    options = []
    for s in subtitles:
        print(s)
        print(sub)
        if s.get('text') != sub.get('text'):
            options.append({'text': s['ar'], 'correct': False})
        if len(options) >= 3:
            break
    options.append({'text': sub['ar'], 'correct': True})
    random.shuffle(options)
    return options


def gen_lesson(subtitle:list[dict], srt_file:str):
    for s in subtitle:
        translated = translate_subtitle(s['text'], 'ar')
        s['ar'] = translated
    lesson_file = srt_file.replace('.srt', '_lesson.txt')
    with open(lesson_file, 'w') as f:
        for s in subtitle:
            f.write(f"----\n")
            f.write(f"{s['text']}\n")
            options = get_options(subtitle, s)
            for o in options:
                prefix = '[+]' if o['correct'] else '[-]'
                f.write(f"{prefix} {o['text']}\n")
            
        
            
     




def gen_lesson_from_srt(srt_file:str):
    with open(srt_file, 'r') as f:
        lines = f.readlines()
        subtitles = format_subtitles(lines)
        subtitles = gen_lesson(subtitles, srt_file)



if __name__ == "__main__":
    gen_lesson_from_srt('/Users/davidle/dev/tutorial/poly-all-desgin/data/content/srt/example.srt')