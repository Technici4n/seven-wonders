import matplotlib.image as mpimg

image = mpimg.imread("textures.png")
image[...] = image[::-1, ...]
mpimg.imsave("textures.png", image)
