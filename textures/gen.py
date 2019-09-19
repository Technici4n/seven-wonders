import json
import PyTexturePacker as ptp

textures_path = "png/"
packer = ptp.Packer.create(bg_color=0x00ffffff, enable_rotated=False)
packer.pack(textures_path, "textures")

output_xml = "textures.plist"

# Parse the generated XML to json
def remove_tag(input_str, endoftag=">"):
    return input_str[input_str.find(endoftag)+1:]

def remove_tags(input_str):
    a = remove_tag(input_str)
    a = a[::-1]
    a = remove_tag(a, endoftag="<")
    return a[::-1]

def as_tuple(input_str):
    return eval(input_str.replace("{", "[").replace("}", "]"))

with open(output_xml, encoding="utf-8") as f:
    full_xml = f.read()

full_xml = remove_tag(full_xml)
full_xml = remove_tag(full_xml)
full_xml = remove_tags(full_xml)
full_xml = remove_tags(full_xml)

frames, metadata = full_xml.split("<key>metadata</key>")

frames = remove_tag(frames)
frames = remove_tag(frames)
frames = remove_tags(frames)

pictures = []
while frames.strip() != "":
    frames = remove_tag(frames)
    name = frames.split(".png")[0]
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    position = as_tuple(frames.split("</string>")[0])
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    offset = as_tuple(frames.split("</string>")[0])
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    frames = remove_tag(frames)
    position1 = position[0]
    position2 = [position[0][0] + position[1][0], position[0][1] + position[1][1]]
    pictures.append(dict(name=name, position=[position1, position2], offset=offset))

metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
metadata = remove_tag(metadata)
size = as_tuple(metadata.split("</string>")[0])

with open("textures.json", "w", encoding="utf-8") as f:
    f.write(json.dumps(dict(images=pictures, metadata=dict(size=size)), ensure_ascii=False))