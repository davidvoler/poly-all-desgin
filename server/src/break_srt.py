lines = []
with open("-0BEGR1uejs_ar.srt", "r", encoding="utf-8") as f:
    r = {}
    for line in f:
        print(line)
        if ("->" in line):
            times = line.strip().split(" -> ")
            print(times)
            r["start"] = times[0]
            r["duration "] = times[1]
        else:
            r["text"] = line.strip()
            lines.append(r)
            r = {}


# print(lines)

break_video_seconds = 120.0
next_break = break_video_seconds
text = ""
sections = []
last_break = 0
next_break = break_video_seconds
for l in lines:
    start = float(l.get("start", 0))
    duration = float(l.get("duration ", 0))
    print(start)
    if start > next_break:
        print(f"Break at {next_break} seconds: {text}")
        sections.append({"text": text , "start": last_break, "end": next_break})
        next_break += break_video_seconds
        last_break = next_break
        text = l.get("text", "") + " "
    else:
        text+= l.get("text", "") + " "

sections.append({"text": text , "start": last_break, "end": start+duration})

print(sections)
with open("sections.txt", "w", encoding="utf-8") as f:
    for section in sections:
        f.write(f"{section.get('start')} - {section.get('end')}:\n{section.get('text')}\n")