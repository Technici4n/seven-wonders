import json

font_file = "font.json"
textures_file = "textures.json"
data_file = "data.json"

data = {}
with open(font_file, encoding="utf-8") as f:
	data["font"] = json.loads(f.read())
with open(textures_file, encoding="utf-8") as f:
	data["textures"] = json.loads(f.read())

with open(data_file, "w", encoding="utf-8") as f:
	f.write(json.dumps(data, ensure_ascii=False))
