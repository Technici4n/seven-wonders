import matplotlib.image as mpimg

image = mpimg.imread("Ubuntu-R.png")
image[...] = image[::-1, ...]
mpimg.imsave("Ubuntu-R.png", image)
