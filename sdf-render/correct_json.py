import json

file = "Ubuntu-R.json"

with open(file, encoding="utf-8") as f:
	data = json.loads(f.read())

letter_changes = [("A", "À"), ("E", "ÉÈÊ")]

def find_position(char):
	for i, d in enumerate(data["chars"]):
		if d["char"] == char:
			return i
	return -1

for reference_letter, faulty_letters in letter_changes:
	target_yoffset = data["chars"][find_position(reference_letter)]["yoffset"]
	for faulty_letter in faulty_letters:
		data["chars"][find_position(faulty_letter)]["yoffset"] = target_yoffset

with open(file, "w", encoding="utf-8") as f:
	f.write(json.dumps(data))