import json
import matplotlib.image as mpimg
import numpy as np

image = mpimg.imread("Ubuntu-R.png")
file = "Ubuntu-R.json"

with open(file, encoding="utf-8") as f:
	data = json.loads(f.read())

max_pos = np.unravel_index(image.argmax(), image.shape)
print("Max value of %d found at %s" % (image[max_pos], str(max_pos)))

data["common"]["whitestCell"] = [int(max_pos[1]), int(max_pos[0])]

with open(file, "w", encoding="utf-8") as f:
	f.write(json.dumps(data))
